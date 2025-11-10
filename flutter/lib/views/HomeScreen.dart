import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  final VoidCallback? goToProfile;
  final VoidCallback? goToLogin;
  final Widget? bottomNavBar;
  const HomeScreen({
    Key? key, 
    this.isLoggedIn = false, 
    this.goToProfile, 
    this.goToLogin, 
    this.bottomNavBar,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool isLoggedIn;
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;
  Set<int> _favoriteIds = {};
  
  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.isLoggedIn;
    _loadListings();
  }

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

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);
    
    try {
      final listings = await ApiService.getAllListings();
      if (listings != null && mounted) {
        setState(() {
          _properties = listings.map((listing) {
            return {
              'id': listing['id'],
              'image': Icons.home,
              'title': listing['title'] ?? 'İlan',
              'location': '${listing['address']?['city'] ?? ''}, ${listing['address']?['district'] ?? ''}',
              'rating': 4.5,
              'reviews': 0,
              'price': '₺${listing['price'] ?? '0'}',
              'period': 'gece',
              'description': listing['description'] ?? '',
              'amenities': listing['amenities'] ?? [],
              'photoUrls': listing['photoUrls'] ?? [],
            };
          }).toList();
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

  // Helper method to build image widget for different URL types
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
                            
                            return Container(
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
                                        Row(
                                          children: [
                                            Icon(Icons.star, color: Colors.amber[700], size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${property['rating']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              ' (${property['reviews']} değerlendirme)',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                          ],
                                        ),
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