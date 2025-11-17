import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';

class ListingDetailScreen extends StatefulWidget {
  final int listingId;
  final bool isLoggedIn;
  final VoidCallback? goToLogin;
  final String? userEmail;

  const ListingDetailScreen({
    Key? key,
    required this.listingId,
    this.isLoggedIn = false,
    this.goToLogin,
    this.userEmail,
  }) : super(key: key);

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Map<String, dynamic>? listing;
  Map<String, dynamic>? host;
  bool loading = true;
  int currentImageIndex = 0;
  bool showAllPhotos = false;
  DateTime? checkInDate;
  DateTime? checkOutDate;
  int guests = 1;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  Future<void> _loadListing() async {
    try {
      final response = await ApiService.getListingById(widget.listingId);
      if (response != null && mounted) {
        setState(() {
          listing = response;
          loading = false;
        });

        // İlan sahibi bilgisini yükle
        final userId = listing?['userId'];
        if (userId != null) {
          await _loadHost(userId);
        }

        // Favori durumunu kontrol et
        if (widget.isLoggedIn) {
          await _checkFavoriteStatus();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İlan yüklenemedi: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadHost(int userId) async {
    try {
      final response = await ApiService.getUserById(userId);
      if (response != null && mounted) {
        setState(() {
          host = {
            'id': response['id'],
            'name': response['fullName'] ?? 'Ev Sahibi',
            'email': response['email'],
          };
        });
      }
    } catch (e) {
      // Hata durumunda varsayılan değer
      setState(() {
        host = {'id': userId, 'name': 'Ev Sahibi'};
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (!widget.isLoggedIn) return;

    try {
      final isFav = await ApiService.isFavorite(listingId: widget.listingId);
      if (mounted) {
        setState(() {
          isFavorite = isFav;
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _toggleFavorite() async {
    if (!widget.isLoggedIn) {
      _showLoginRequiredDialog(message: 'Favorilere eklemek için önce giriş yapmanız gerekmektedir.');
      return;
    }

    final wasRemoving = isFavorite;
    setState(() {
      isFavorite = !isFavorite;
    });

    try {
      if (wasRemoving) {
        await ApiService.removeFromFavorites(listingId: widget.listingId);
      } else {
        await ApiService.addToFavorites(listingId: widget.listingId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasRemoving ? 'Favorilerden çıkarıldı' : 'Favorilere eklendi'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isFavorite = !isFavorite;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Favori güncellenirken hata: $e')),
        );
      }
    }
  }

  void _showLoginRequiredDialog({String? message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giriş Yapın'),
        content: Text(message ?? 'Bu işlem için önce giriş yapmanız gerekmektedir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              Navigator.pop(context); // Detay sayfasını kapat
              widget.goToLogin?.call(); // Login ekranına git
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Giriş Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  int get totalNights {
    if (checkInDate == null || checkOutDate == null) return 0;
    final diff = checkOutDate!.difference(checkInDate!).inDays;
    return diff > 0 ? diff : 0;
  }

  double get totalPrice {
    if (listing == null) return 0;
    final price = listing!['price'] ?? 0;
    return price * totalNights;
  }

  bool get isOwnListing {
    if (!widget.isLoggedIn || widget.userEmail == null || listing == null) return false;
    // Backend'den gelen host email ile karşılaştır
    return host?['email'] == widget.userEmail;
  }

  void _makeReservation() {
    if (isOwnListing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendi ilanınıza rezervasyon yapamazsınız')),
      );
      return;
    }

    if (checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen giriş ve çıkış tarihlerini seçin')),
      );
      return;
    }

    if (totalNights < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Çıkış tarihi giriş tarihinden sonra olmalıdır')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rezervasyon Talebi'),
        content: Text(
          'Giriş: ${checkInDate!.day}/${checkInDate!.month}/${checkInDate!.year}\n'
          'Çıkış: ${checkOutDate!.day}/${checkOutDate!.month}/${checkOutDate!.year}\n'
          'Misafir: $guests\n'
          'Toplam: ₺${totalPrice.toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.home, size: 80, color: Colors.white),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.home, size: 80, color: Colors.white),
        );
      }
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.home, size: 80, color: Colors.white),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Yükleniyor...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('İlan bulunamadı')),
      );
    }

    final photoUrls = (listing!['photoUrls'] as List?)?.cast<String>() ?? [];
    final amenities = (listing!['amenities'] as List?)?.cast<String>() ?? [];
    final address = listing!['address'] as Map<String, dynamic>? ?? {};
    
    // Backend'den gelen address yapısını parse et
    final city = address['addressCity'] ?? address['city'] ?? '';
    final country = address['addressCountry'] ?? address['country'] ?? '';
    final district = address['addressDistrict'] ?? address['district'] ?? '';
    final region = address['addressRegion'] ?? address['region'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Back Button
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.black,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Gallery
                if (photoUrls.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => showAllPhotos = true),
                    child: SizedBox(
                      height: 300,
                      child: PageView.builder(
                        itemCount: photoUrls.length,
                        onPageChanged: (index) => setState(() => currentImageIndex = index),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              _buildImageWidget(photoUrls[index]),
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${index + 1}/${photoUrls.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.home, size: 100, color: Colors.white),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        listing!['title'] ?? 'İlan',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '$city, $country',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Divider(),

                      // Host Info
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              radius: 28,
                              child: Text(
                                host?['name']?.substring(0, 1).toUpperCase() ?? 'E',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${host?['name'] ?? 'Ev Sahibi'} tarafından paylaşılan ilan',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${listing!['placeType'] ?? 'Konut'} - $district, $city',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Property Details
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Wrap(
                          spacing: 16,
                          children: [
                            Text('${listing!['guests'] ?? 1} misafir'),
                            const Text('·'),
                            Text('${listing!['bedrooms'] ?? 1} yatak odası'),
                            const Text('·'),
                            Text('${listing!['beds'] ?? 1} yatak'),
                            const Text('·'),
                            Text('${listing!['bathrooms'] ?? 1} banyo'),
                          ],
                        ),
                      ),

                      const Divider(height: 32),

                      // Description
                      const Text(
                        'Konaklama yeri hakkında',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        listing!['description'] ?? 'Açıklama bulunmuyor',
                        style: TextStyle(color: Colors.grey[700], height: 1.5),
                      ),

                      const Divider(height: 32),

                      // Amenities
                      if (amenities.isNotEmpty) ...[
                        const Text(
                          'Bu mekân size neler sunuyor?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: amenities.map((amenity) {
                            return Chip(
                              label: Text(amenity),
                              avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
                            );
                          }).toList(),
                        ),
                        const Divider(height: 32),
                      ],

                      // Location Info
                      const Text(
                        'Nerede olacaksınız',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$district, $city',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              country,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (region.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Bölge: $region',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 100), // Space for bottom card
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Reservation Card
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: isOwnListing
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Bu Sizin İlanınız',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kendi ilanınıza rezervasyon yapamazsınız',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '₺${listing!['price'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' / gece',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (totalNights > 0)
                    Text(
                      '₺${totalPrice.toStringAsFixed(0)} toplam',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (!widget.isLoggedIn) {
                    _showLoginRequiredDialog(message: 'Rezervasyon yapmak için önce giriş yapmanız gerekmektedir.');
                  } else {
                    _showReservationDialog();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Rezervasyon Yap',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReservationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rezervasyon Detayları',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Check-in Date
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Giriş Tarihi'),
                    subtitle: Text(
                      checkInDate != null
                          ? '${checkInDate!.day}/${checkInDate!.month}/${checkInDate!.year}'
                          : 'Tarih seçin',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setModalState(() => checkInDate = date);
                        setState(() => checkInDate = date);
                      }
                    },
                  ),

                  // Check-out Date
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Çıkış Tarihi'),
                    subtitle: Text(
                      checkOutDate != null
                          ? '${checkOutDate!.day}/${checkOutDate!.month}/${checkOutDate!.year}'
                          : 'Tarih seçin',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: checkInDate ?? DateTime.now(),
                        firstDate: checkInDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setModalState(() => checkOutDate = date);
                        setState(() => checkOutDate = date);
                      }
                    },
                  ),

                  // Guests
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Misafir Sayısı'),
                    subtitle: Text('Maksimum ${listing!['guests'] ?? 1} misafir'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (guests > 1) {
                              setModalState(() => guests--);
                              //setState(() => guests--);
                            }
                          },
                        ),
                        Text('$guests', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (guests < (listing!['guests'] ?? 1)) {
                              setModalState(() => guests++);
                              //setState(() => guests++);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price Summary
                  if (totalNights > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₺${listing!['price']} x $totalNights gece'),
                        Text('₺${(listing!['price'] * totalNights).toStringAsFixed(0)}'),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Toplam',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₺${totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Reserve Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (checkInDate != null && checkOutDate != null && totalNights > 0)
                          ? () {
                              Navigator.pop(context);
                              _makeReservation();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Rezervasyonu Onayla',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  if (checkInDate == null || checkOutDate == null || totalNights < 1)
                    const Center(
                      child: Text(
                        'Lütfen giriş ve çıkış tarihlerini seçin',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    )
                  else
                    const Center(
                      child: Text(
                        'Henüz ücret alınmayacak',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
