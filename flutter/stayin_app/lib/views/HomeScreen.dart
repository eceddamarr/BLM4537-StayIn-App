import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'ListingDetailScreen.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  final VoidCallback? goToProfile;
  final VoidCallback? goToLogin;
  final Widget? bottomNavBar;
  final String? userEmail;
  const HomeScreen({
    Key? key, 
    this.isLoggedIn = false, 
    this.goToProfile, 
    this.goToLogin, 
    this.bottomNavBar,
    this.userEmail,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool isLoggedIn;
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;
  Set<int> _favoriteIds = {};   // Favori ilan ID'leri
  Set<int> _myListingIds = {}; // Kullanıcının kendi ilan ID'leri
  
  // Widget ilk oluşturulduğunda çalışır, başlangıç verilerini yükler
  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.isLoggedIn;
    _loadData();
  }

  // Kullanıcıya ait ilanları ve tüm ilanları yükler
  Future<void> _loadData() async {
    await _loadMyListingIds();
    await _loadListings();
  }

  // Kullanıcının kendi ilan ID'lerini backend'den alır
  Future<void> _loadMyListingIds() async {
    if (!widget.isLoggedIn) return;
    
    try {
      final myListings = await ApiService.getMyListings();
      if (myListings != null && mounted) {
        setState(() {
          _myListingIds = myListings.map((listing) => listing['id'] as int).toSet();
        });
      }
    } catch (e) {
      // Sessizce devam et
    }
  }

  // Tüm ilanlar için favori durumunu backend'den kontrol eder
  Future<void> _loadFavoriteStates() async {
    if (!mounted || !widget.isLoggedIn) return;
    
    final favorites = <int>{};
    for (var property in _properties) {
      final listingId = property['id'] as int?;
      if (listingId != null) {
        final isFav = await ApiService.isFavorite(listingId: listingId);
        if (isFav) {
          favorites.add(listingId);
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _favoriteIds = favorites;
      });
    }
  }

  // Favori ekleme/çıkarma işlemini yapar
  Future<void> _toggleFavorite(int index) async {
    // Giriş kontrolü
    if (!widget.isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }
    
    final property = _properties[index];
    final listingId = property['id'] as int;
    final isFavorite = _favoriteIds.contains(listingId);
    
    try {
      if (isFavorite) {
        // Favorilerden çıkar
        await ApiService.removeFromFavorites(listingId: listingId);
        setState(() {
          _favoriteIds.remove(listingId);
        });
      } else {
        // Favorilere ekle
        await ApiService.addToFavorites(listingId: listingId);
        setState(() {
          _favoriteIds.add(listingId);
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? 'Favorilerden çıkarıldı'
                : 'Favorilere eklendi',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Favori için giriş gerektiren uyarı dialogunu gösterir
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giriş Yapın'),
        content: const Text('Favorilere eklemek için önce giriş yapmanız gerekmektedir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.goToLogin?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Giriş Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Tüm ilanları backend'den alır ve ekrana hazırlar
  Future<void> _loadListings() async {
    setState(() => _isLoading = true);
    
    try {
      final listings = await ApiService.getAllListings();
      if (listings != null && mounted) {
        // İlanları map'le ve review bilgilerini ekle
        final propertiesList = await Future.wait(
          listings
            .where((listing) {
              // Giriş yapmış kullanıcının kendi ilanlarını filtrele
              if (widget.isLoggedIn && _myListingIds.isNotEmpty) {
                final listingId = listing['id'] as int?;
                return listingId != null && !_myListingIds.contains(listingId);
              }
              return true;
            })
            .map((listing) async {
              // Backend'den gelen address yapısını parse et
              final address = listing['address'] as Map<String, dynamic>?;
              final city = address?['addressCity'] ?? address?['city'] ?? '';
              final district = address?['addressDistrict'] ?? address?['district'] ?? '';
              
              // Her ilan için review bilgilerini getir
              double rating = 0.0;
              int reviewCount = 0;
              try {
                final reviewResult = await ApiService.getListingReviews(listing['id']);
                if (reviewResult['success']) {
                  final data = reviewResult['data'];
                  rating = (data['averageRating'] ?? 0.0).toDouble();
                  reviewCount = data['totalReviews'] ?? 0;
                }
              } catch (e) {
                // Hata durumunda varsayılan değerleri kullan
              }
              
              return {
                'id': listing['id'],
                'image': Icons.home,
                'title': listing['title'] ?? 'İlan',
                'location': '$city, $district',
                'rating': rating,
                'reviews': reviewCount,
                'price': '₺${listing['price'] ?? '0'}',
                'period': 'gece',
                'description': listing['description'] ?? '',
                'amenities': listing['amenities'] ?? [],
                'photoUrls': listing['photoUrls'] ?? [],
                'userId': listing['userId'], // userId'yi de sakla
              };
            }).toList(),
        );
        
        setState(() {
          _properties = propertiesList;
          _isLoading = false;
        });
        
        // İlanlar yüklendikten sonra favori durumlarını yükle
        await _loadFavoriteStates();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İlanlar yüklenirken hata oluştu: $e')),
        );
      }
    }
  }
  
  String demoUsername = 'Demo Kullanıcı';
  String demoEmail = 'demo@email.com';


  // Fotoğraf URL'sine göre uygun image widget'ı döndürür
  Widget _buildImageWidget(String imageUrl, {double? height, double? width, IconData? placeholderIcon}) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 data URI - extract and decode
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          height: height,
          width: width,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: height ?? 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.redAccent.withOpacity(0.7), Colors.orangeAccent.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  placeholderIcon ?? Icons.home,
                  size: 80,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          height: height ?? 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent.withOpacity(0.7), Colors.orangeAccent.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(
              placeholderIcon ?? Icons.home,
              size: 80,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        );
      }
    } else {
      // Regular network URL
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: height,
        width: width,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height ?? 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.redAccent.withOpacity(0.7), Colors.orangeAccent.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                placeholderIcon ?? Icons.home,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          );
        },
      );
    }
  }

  // Ana ekranın arayüzünü oluşturur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // Search Bar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Nereye gitmek istersiniz?",
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Başlık
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Popüler İlanlar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_properties.length} ilan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Property Listings
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _properties.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz ilan bulunmuyor',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _properties.length,
                          itemBuilder: (context, index) {
                            final property = _properties[index];
                            final listingId = property['id'] as int;
                            final isFavorite = _favoriteIds.contains(listingId);
                            
                            return GestureDetector(
                              onTap: () {
                                // İlan detay sayfasına git
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ListingDetailScreen(
                                      listingId: listingId,
                                      isLoggedIn: widget.isLoggedIn,
                                      goToLogin: widget.goToLogin,
                                      userEmail: widget.userEmail,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Fotoğraf varsa göster, yoksa placeholder
                                        property['photoUrls'] != null && (property['photoUrls'] as List).isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                child: _buildImageWidget(
                                                  (property['photoUrls'] as List).first,
                                                  height: 200,
                                                  width: double.infinity,
                                                  placeholderIcon: property['image'],
                                                ),
                                              )
                                            : Container(
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [Colors.redAccent.withOpacity(0.7), Colors.orangeAccent.withOpacity(0.7)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    property['image'],
                                                    size: 80,
                                                    color: Colors.white.withOpacity(0.9),
                                                  ),
                                                ),
                                              ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () => _toggleFavorite(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Icon(
                                                isFavorite
                                                    ? Icons.favorite 
                                                    : Icons.favorite_border,
                                                size: 20,
                                                color: isFavorite
                                                    ? Colors.red
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Details
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Text(
                                          property['title'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              property['location'],
                                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Rating
                                        if (property['reviews'] > 0) ...[
                                          Row(
                                            children: [
                                              const Icon(Icons.star, size: 16, color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${property['rating'].toStringAsFixed(1)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${property['reviews']} yorum)',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        Row(
                                          children: [
                                            Text(
                                              property['price'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                            Text(
                                              ' / ${property['period']}',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.bottomNavBar,
    );
  }
}