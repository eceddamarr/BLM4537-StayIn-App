import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';   //Haritayı ekranda göstermek için
import 'package:latlong2/latlong.dart';         //Enlem boylam bilgisi için 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/api_service.dart';

class HostHomeScreen extends StatefulWidget {
  final String userFullName;
  final String userEmail;
  final bool editMode;
  final Map<String, dynamic>? existingListing;

  const HostHomeScreen({
    Key? key,
    required this.userFullName,
    required this.userEmail,
    this.editMode = false,
    this.existingListing,
  }) : super(key: key);

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  // Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  // Step 8: Address Controllers
  final TextEditingController addressCountryController = TextEditingController();
  final TextEditingController addressDistrictController = TextEditingController();
  final TextEditingController addressStreetController = TextEditingController();
  final TextEditingController addressBuildingController = TextEditingController();
  final TextEditingController addressPostalCodeController = TextEditingController();
  final TextEditingController addressRegionController = TextEditingController();
  final TextEditingController addressCityController = TextEditingController();

  // Map + search controller'ları (state değişkenleri)
  final TextEditingController addressController = TextEditingController();
  final MapController mapController = MapController();  //Haritayı yönetmek için 


  // Amenities
  final List<String> amenitiesOptions = const [
    'Wifi', 'TV', 'Mutfak', 'Çamaşır makinesi', 'Binada ücretsiz otopark',
    'Mülkte ücretli otopark', 'Klima', 'Özel çalışma alanı', 'Havuz', 'Jakuzi',
    'Veranda', 'Mangal', 'Açık havada yemek alanı', 'Bilardo masası', 'Şömine',
    'Piyano', 'Egzersiz ekipmanı', 'Göle erişim', 'Plaja erişim'
  ];
  List<String> selectedAmenities = [];

  // Photo picker
  final ImagePicker _picker = ImagePicker();
  List<XFile> selectedImages = [];
  List<String> photoUrls = [];

  // Wizard state
  static const int totalSteps = 10;
  int currentStep = 0;

  // Step 0-2 states
  String? selectedPlace;
  String? selectedAccommodation;
  final List<String> placeOptions = const [
    'Ev', 'Daire', 'Ambar', 'Oda-kahvaltı', 'Tekne',
    'Kulübe', 'Kamp aracı/karavan', 'Casa particular', 'Şato',
  ];
  final List<String> accommodationOptions = const [
    'Bütün mekan', 'Bir oda', 'Paylaşılan oda',
  ];

  int guests = 2;
  int bedrooms = 1;
  int beds = 1;
  int bathrooms = 1;

  // Step 3: Mock Map
  LatLng? selectedLocation;

  // Widget ilk oluşturulduğunda çalışır, edit modunda eski ilanı yükler
  @override
  void initState() {
    super.initState();
    if (widget.editMode && widget.existingListing != null) {
      _loadExistingListing();
    }
  }

  // Edit modunda mevcut ilanı tüm alanlara doldurur
  void _loadExistingListing() {
    final listing = widget.existingListing!;
    
    // Load text fields
    titleController.text = listing['title']?.toString() ?? '';
    descriptionController.text = listing['description']?.toString() ?? '';
    priceController.text = listing['price']?.toString() ?? '';
    
    // Load selections
    selectedPlace = listing['placeType']?.toString() ?? 'Ev';
    selectedAccommodation = listing['accommodationType']?.toString() ?? 'Bütün mekan';
    
    // Load counts
    guests = listing['guests'] ?? 2;
    bedrooms = listing['bedrooms'] ?? 1;
    beds = listing['beds'] ?? 1;
    bathrooms = listing['bathrooms'] ?? 1;
    
    // Load amenities
    selectedAmenities = [];
    if (listing['amenities'] != null) {
      try {
        if (listing['amenities'] is List) {
          selectedAmenities = List<String>.from(listing['amenities']);
        } else if (listing['amenities'] is String) {
          final amenitiesStr = listing['amenities'] as String;
          if (amenitiesStr.isNotEmpty) {
            selectedAmenities = amenitiesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
        }
      } catch (e) {
        // Amenities loading error
      }
    }
    
    // Load address
    if (listing['address'] != null) {
      final address = listing['address'];
      
      try {
        addressCountryController.text = (address['addressCountry'] ?? address['country'] ?? '').toString();
        addressCityController.text = (address['addressCity'] ?? address['city'] ?? '').toString();
        addressDistrictController.text = (address['addressDistrict'] ?? address['district'] ?? '').toString();
        addressStreetController.text = (address['addressStreet'] ?? address['street'] ?? '').toString();
        addressBuildingController.text = (address['addressBuilding'] ?? address['building'] ?? '').toString();
        addressPostalCodeController.text = (address['addressPostalCode'] ?? address['postalCode'] ?? '').toString();
        addressRegionController.text = (address['addressRegion'] ?? address['region'] ?? '').toString();
      } catch (e) {
        // Address loading error
      }
    }
    
    // Load location
    var lat = listing['latitude'];
    var lon = listing['longitude'];
    
    if (lat != null && lon != null) {
      try {
        double latDouble = (lat is int) ? lat.toDouble() : (lat is double) ? lat : double.parse(lat.toString());
        double lonDouble = (lon is int) ? lon.toDouble() : (lon is double) ? lon : double.parse(lon.toString());
        
        selectedLocation = LatLng(latDouble, lonDouble);
      } catch (e) {
        selectedLocation = null;
      }
    }
    
    // Load photos
    photoUrls = [];
    selectedImages = [];
    
    try {
      List<String> rawPhotos = [];
      
      if (listing['photos'] != null && listing['photos'] is List) {
        final photosList = listing['photos'] as List;
        rawPhotos = photosList.map((e) => e.toString()).where((url) => url.isNotEmpty).toList();
      } else if (listing['photoUrls'] != null && listing['photoUrls'] is List) {
        final photosList = listing['photoUrls'] as List;
        rawPhotos = photosList.map((e) => e.toString()).where((url) => url.isNotEmpty).toList();
      }
      
      // URL'leri tam path'e çevir
      photoUrls = rawPhotos.map((url) {
        if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) {
          return url;
        } else if (url.startsWith('/')) {
          return 'http://10.0.2.2:5211$url';
        } else {
          return 'http://10.0.2.2:5211/$url';
        }
      }).toList();
      
    } catch (e) {
      // Photo loading error
    }
  }

  // -----------------------------
  // Navigation Logic
  // -----------------------------
  // İleri butonuna basınca adım değiştirir veya ilanı yayınlar
  void nextStep() async {
    if (!_canProceed(showWarning: true)) return;

    if (currentStep < totalSteps - 1) {
      setState(() => currentStep++);
    } else {
      // Yayınla butonuna basıldığında backend'e gönder
      await _publishListing();
    }
  }

  // İlanı backend'e kaydeder veya günceller
  Future<void> _publishListing() async {
    // Validate required fields
    if (titleController.text.isEmpty || 
        descriptionController.text.isEmpty || 
        priceController.text.isEmpty) {
      _warn('Lütfen tüm zorunlu alanları doldurun.');
      return;
    }

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      dynamic result;
      
      if (widget.editMode && widget.existingListing != null) {
        // Update existing listing
        final listingId = widget.existingListing!['id'];
        
        // Fotoğraf URL'lerini filtrele - sadece geçerli URL'leri gönder
        // Lokal dosya path'lerini (file://) backend'e gönderme
        final validPhotoUrls = photoUrls.where((url) {
          return url.startsWith('http://') || 
                 url.startsWith('https://') || 
                 url.startsWith('data:image');
        }).toList();
        
        print('Güncelleme için gönderilen fotoğraf sayısı: ${validPhotoUrls.length}');
        
        result = await ApiService.updateListing(
          listingId: listingId,
          title: titleController.text,
          description: descriptionController.text,
          placeType: selectedPlace ?? 'Ev',
          accommodationType: selectedAccommodation ?? 'Bütün mekan',
          guests: guests,
          bedrooms: bedrooms,
          beds: beds,
          bathrooms: bathrooms,
          amenities: selectedAmenities,
          price: double.tryParse(priceController.text) ?? 0.0,
          country: addressCountryController.text,
          city: addressCityController.text,
          district: addressDistrictController.text,
          street: addressStreetController.text,
          building: addressBuildingController.text.isEmpty ? null : addressBuildingController.text,
          postalCode: addressPostalCodeController.text.isEmpty ? null : addressPostalCodeController.text,
          region: addressRegionController.text.isEmpty ? null : addressRegionController.text,
          latitude: selectedLocation?.latitude,
          longitude: selectedLocation?.longitude,
          photoUrls: validPhotoUrls,
        );
      } else {
        // Create new listing
        result = await ApiService.createListing(
          title: titleController.text,
          description: descriptionController.text,
          placeType: selectedPlace ?? 'Ev',
          accommodationType: selectedAccommodation ?? 'Bütün mekan',
          guests: guests,
          bedrooms: bedrooms,
          beds: beds,
          bathrooms: bathrooms,
          amenities: selectedAmenities,
          price: double.tryParse(priceController.text) ?? 0.0,
          country: addressCountryController.text,
          city: addressCityController.text,
          district: addressDistrictController.text,
          street: addressStreetController.text,
          building: addressBuildingController.text.isEmpty ? null : addressBuildingController.text,
          postalCode: addressPostalCodeController.text.isEmpty ? null : addressPostalCodeController.text,
          region: addressRegionController.text.isEmpty ? null : addressRegionController.text,
          latitude: selectedLocation?.latitude,
          longitude: selectedLocation?.longitude,
          photoUrls: photoUrls,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Başarı durumunu daha esnek kontrol et
      bool isSuccess = false;
      String? message;
      
      if (result != null) {
        // success field varsa kontrol et
        if (result.containsKey('success')) {
          isSuccess = result['success'] == true;
        } else {
          // success field yoksa, message veya listing varsa başarılı say
          isSuccess = result.containsKey('message') || result.containsKey('listing');
        }
        message = result['message']?.toString();
      }

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? (widget.editMode ? 'İlanınız başarıyla güncellendi!' : 'İlanınız başarıyla yayınlandı!')),
            backgroundColor: Colors.green,
          ),
        );
        
        // Edit modunda ise İlanlarım sayfasına dön, yeni ilan ise ana sayfaya dön
        if (widget.editMode) {
          // İlanlarım sayfasına dön (MyListingsScreen'e geri dön)
          Navigator.of(context).pop();
        } else {
          // Ana ekrana dön
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? (widget.editMode ? 'İlan güncellenemedi.' : 'İlan yayınlanamadı.')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      // Detaylı hata göster
      print('Hata detayı: $e');
      print('Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Geri butonuna basınca bir önceki adıma döner
  void prevStep() {
    if (currentStep > 0) setState(() => currentStep--);
  }

  // Adım geçişi için gerekli alanlar dolu mu kontrol eder
  bool _canProceed({bool showWarning = false}) {
    if (currentStep == 0 && selectedPlace == null) {
      if (showWarning) _warn('Devam etmek için bir yer türü seçin.');
      return false;
    }
    if (currentStep == 1 && selectedAccommodation == null) {
      if (showWarning) _warn('Devam etmek için konaklama tipini seçin.');
      return false;
    }
    return true;
  }

  // Uyarı mesajı gösterir
  void _warn(String msg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  // -----------------------------
  // Step Builder
  // -----------------------------
  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _stepPlaceSelection();
      case 1:
        return _stepAccommodationSelection();
      case 2:
        return _stepBasicInfo();
      case 3:
        return _stepMapSelection();
      case 4:
        return _stepAmenities();
      case 5:
        return _stepPhotos();
      case 6:
        return _stepTitleAndDescription();
      case 7:
        return _stepPrice();
      case 8:
        return _stepAddress();
      case 9:
        return _stepPublishPreview();
      default:
        return const SizedBox.shrink();
    }
  }


  // -----------------------------
  // Steps
  // -----------------------------

  Widget _stepPlaceSelection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aşağıdakilerden hangisi yerinizi en iyi tanımlıyor?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: placeOptions.map((option) {
              return ChoiceChip(
                label: Text(option),
                selected: selectedPlace == option,
                onSelected: (_) => setState(() => selectedPlace = option),
              );
            }).toList(),
          ),
        ],
      );

  Widget _stepAccommodationSelection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Misafirlere ne tür bir yer sağlanacak?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: accommodationOptions.map((option) {
              return ChoiceChip(
                label: Text(option),
                selected: selectedAccommodation == option,
                onSelected: (_) =>
                    setState(() => selectedAccommodation = option),
              );
            }).toList(),
          ),
        ],
      );

  Widget _stepBasicInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yerinizle ilgili bazı temel bilgileri paylaşın',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _counterRow('Misafir', guests, () => setState(() => guests--),
              () => setState(() => guests++), 1, 99),
          _counterRow('Yatak odası', bedrooms, () => setState(() => bedrooms--),
              () => setState(() => bedrooms++), 0, 99),
          _counterRow('Yatak', beds, () => setState(() => beds--),
              () => setState(() => beds++), 1, 99),
          _counterRow('Banyo', bathrooms, () => setState(() => bathrooms--),
              () => setState(() => bathrooms++), 0, 99),
        ],
      );

  Widget _stepMapSelection() {
    Future<List<Map<String, dynamic>>> _searchLocation(String query) async {
      if (query.trim().isEmpty) return [];
      
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$query'
        '&format=json'
        '&addressdetails=1'
        '&limit=5'
        '&viewbox=32.5,40.0,33.2,39.7'
        '&bounded=1'
      );
      final res = await http.get(
        url,
        headers: {
          // Nominatim policy gereği custom UA gönderelim
          'User-Agent': 'StayInApp/1.0 (+https://example.com/contact)',
          'Accept-Language': 'tr'
        },
      );
      if (res.statusCode != 200) return [];
      final List data = json.decode(res.body);
      return data.cast<Map<String, dynamic>>();
    }

    void _fillAddressFromData(Map<String, dynamic> address) {
      // Adres bilgilerini otomatik doldur
      setState(() {
        addressCountryController.text = address['country'] ?? '';
        addressCityController.text = address['city'] ?? address['town'] ?? address['state'] ?? '';
        addressDistrictController.text = address['suburb'] ?? address['neighbourhood'] ?? '';
        addressStreetController.text = address['road'] ?? '';
        addressBuildingController.text = address['house_number'] ?? '';
        addressPostalCodeController.text = address['postcode'] ?? '';
        addressRegionController.text = address['state'] ?? '';
      });
    }

    void _goTo(LatLng latLng, {double zoom = 15, Map<String, dynamic>? addressData}) {
      setState(() => selectedLocation = latLng);
      // flutter_map v7'de haritayı gerçekten hareket ettirmek için MapController kullan
      mapController.move(latLng, zoom);
      
      // Eğer adres bilgisi varsa otomatik doldur
      if (addressData != null && addressData['address'] != null) {
        _fillAddressFromData(addressData['address']);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yerinizin konumunu belirleyin',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Adresinizi yazın veya haritadan seçin. Adres bilgileri otomatik doldurulacaktır.',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),

  // Autocomplete'li arama kutusu (flutter_typeahead v5 uyumlu)
        TypeAheadField<Map<String, dynamic>>(
          // v5 API: builder ile TextField'ı çiziyoruz
          builder: (context, controller, focusNode) {
            // bizim state controller'ımızı bağlayalım
            controller.text = addressController.text;
            controller.addListener(() {
              // senkronize tut
              addressController.value = controller.value;
            });
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Adres ara',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            );
          },
          // Öneri sağlayıcı
          suggestionsCallback: (pattern) => _searchLocation(pattern),
          // Öneri öğesi
          itemBuilder: (context, suggestion) {
            final address = (suggestion['display_name'] ?? '') as String;
            return ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
          // Öneri seçildiğinde
          onSelected: (suggestion) {
            final lat = double.parse(suggestion['lat']);
            final lon = double.parse(suggestion['lon']);
            addressController.text = suggestion['display_name'] ?? '';
            _goTo(LatLng(lat, lon), addressData: suggestion);
          },
          // Kutunun görünüşü
          decorationBuilder: (context, child) => ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: Material(
              elevation: 6,
              child: child,
            ),
          ),
          // Boşta gizle vs.
          hideOnEmpty: true,
        ),

        const SizedBox(height: 16),

  // Harita (flutter_map v7)
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                // v7: initialCenter / initialZoom kullanılır
                initialCenter: selectedLocation ?? LatLng(39.92077, 32.85411),  // Ankara merkez
                initialZoom: selectedLocation != null ? 15.0 : 13.0,
                onTap: (tapPos, point) async {
                  // Haritaya tıklanınca reverse geocoding yap
                  final lat = point.latitude;
                  final lon = point.longitude;
                  
                  try {
                    final url = Uri.parse(      //koordinattan adres bilgisi alınır 
                      'https://nominatim.openstreetmap.org/reverse'
                      '?lat=$lat'
                      '&lon=$lon'
                      '&format=json'
                      '&addressdetails=1'
                    );
                    final res = await http.get(
                      url,
                      headers: {
                        'User-Agent': 'StayInApp/1.0 (+https://example.com/contact)',
                        'Accept-Language': 'tr'
                      },
                    );
                    
                    if (res.statusCode == 200) {
                      final data = json.decode(res.body);
                      _goTo(point, addressData: data);
                    } else {
                      _goTo(point);
                    }
                  } catch (e) {
                    _goTo(point);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.stayin.app',
                ),
                if (selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 60,
                        height: 60,
                        point: selectedLocation!,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (selectedLocation != null)    //Kullanıcı bir konum seçtiyse, enlem ve boylamı ekranda gösterilir.
          Text(
            "Seçilen konum: "
            "${selectedLocation!.latitude.toStringAsFixed(5)}, "
            "${selectedLocation!.longitude.toStringAsFixed(5)}",
            style: const TextStyle(color: Colors.black87),
          )
        else
          const Text("Henüz bir konum seçilmedi.",
              style: TextStyle(color: Colors.grey)),
      ],
    );
  }



  Widget _stepAmenities() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Misafirlerinize yerinizin neler sunduğunu anlatın',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: amenitiesOptions.map((label) {
              final selected = selectedAmenities.contains(label);
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      selectedAmenities.add(label);
                    } else {
                      selectedAmenities.remove(label);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      );

  // Yeni aktif fotoğraf yükleme
  // Cihazdan birden fazla fotoğraf seçer ve ekler
  Future<void> pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage(
      imageQuality: 85,
    );
    if (images != null && images.isNotEmpty) {
      setState(() {
        selectedImages.addAll(images);
        // Yeni dosya path'lerini photoUrls'e ekle (mevcut URL'leri koru)
        for (var img in images) {
          photoUrls.add(img.path);
        }
      });
    }
  }

  // Helper method to build image widget for different URL types
  // Fotoğraf URL'sine göre uygun image widget'ı döndürür
  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 data URI - extract and decode
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 40),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 40),
        );
      }
    } else {
      // Regular network URL
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 40),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }
  }

  Widget _stepPhotos() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fotoğraf ekleyin',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: pickImages,
            icon: const Icon(Icons.photo_library),
            label: const Text('Fotoğraf Seç'),
          ),
          const SizedBox(height: 16),
          
          // Hem mevcut URL'leri hem de yeni seçilen dosyaları göster
          (selectedImages.isEmpty && photoUrls.isEmpty)
              ? Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Henüz fotoğraf eklenmedi.'),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: selectedImages.length + photoUrls.length,
                  itemBuilder: (context, index) {
                    // Önce yeni seçilen dosyaları göster
                    if (index < selectedImages.length) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(selectedImages[index].path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Sonra mevcut URL'leri göster (edit modunda)
                      final urlIndex = index - selectedImages.length;
                      final imageUrl = photoUrls[urlIndex];
                      
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildImageWidget(imageUrl),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  photoUrls.removeAt(urlIndex);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
        ],
      );


  Widget _stepTitleAndDescription() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Başlık ve Açıklama',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
                labelText: 'Başlık', border: OutlineInputBorder()),
            controller: titleController,
            maxLength: 50,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
                labelText: 'Açıklama', border: OutlineInputBorder()),
            controller: descriptionController,
            maxLength: 500,
            minLines: 3,
            maxLines: 5,
          ),
        ],
      );

  Widget _stepPrice() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fiyat Bilgisi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
                labelText: 'Gecelik Fiyat (₺)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            controller: priceController,
          ),
        ],
      );

  Widget _stepAddress() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adres Bilgilerini Kontrol Edin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Haritadan seçilen adres bilgileri otomatik dolduruldu. İsterseniz düzenleyebilirsiniz.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          _addressField('Ülke/Bölge', addressCountryController),
          _addressField('İl', addressCityController),
          _addressField('Semt (varsa)', addressDistrictController),
          _addressField('Sokak, cadde', addressStreetController),
          _addressField('Daire, kat, bina (varsa)', addressBuildingController),
          _addressField('Posta Kodu', addressPostalCodeController),
          _addressField('Bölge', addressRegionController),
        ],
      );

  Widget _stepPublishPreview() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            " Tebrikler! İlanınızı yayınlamaya hazırsınız.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "İşte misafirlerin göreceği ilan önizlemesi:",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 30),

          // Kart önizleme
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: photoUrls.isNotEmpty
                      ? SizedBox(
                          width: double.infinity,
                          height: 220,
                          child: _buildImageWidget(photoUrls.first),
                        )
                      : Image.network(
                          'https://via.placeholder.com/400x250?text=Önizleme',
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleController.text.isNotEmpty
                            ? titleController.text
                            : "Başlık",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descriptionController.text.isNotEmpty
                            ? descriptionController.text
                            : "Açıklama",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            "₺${priceController.text.isNotEmpty ? priceController.text : "130"}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "gecelik",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Yeni ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Yayınla butonuna bastığınızda ilanınız aktif hale gelecektir.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    ),
  );



  // ---------- Helpers ----------
  Widget _counterRow(String title, int value, VoidCallback dec, VoidCallback inc,
          int min, int max) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Row(children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: value > min ? dec : null,
              ),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: value < max ? inc : null,
              ),
            ]),
          ],
        ),
      );

  Widget _addressField(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          decoration:
              InputDecoration(labelText: label, border: const OutlineInputBorder()),
          controller: c,
        ),
      );


  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == totalSteps - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editMode ? 'İlanı Düzenle' : 'Ev Sahipliği Yapın'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: (currentStep + 1) / totalSteps),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(),
                ),
              ),
              Row(
                children: [
                  if (currentStep > 0)
                    OutlinedButton(
                      onPressed: prevStep,
                      child: const Text('Geri'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: nextStep,
                    child: Text(isLast 
                      ? (widget.editMode ? 'Güncelle' : 'Yayınla')
                      : 'İleri'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
