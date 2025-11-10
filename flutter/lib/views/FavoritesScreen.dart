import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FavoritesScreen extends StatefulWidget {
  final Widget? bottomNavBar;
  
  const FavoritesScreen({Key? key, this.bottomNavBar}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    
    try {
      final favorites = await ApiService.getFavorites();
      
      if (mounted) {
        setState(() {
          _favorites = (favorites ?? []).map((item) {
            return {
              'id': item['id'],
              'title': item['title'] ?? 'İlan',
              'description': item['description'] ?? '',
              'price': item['price'] ?? 0,
              'location': '${item['address']?['addressCity'] ?? ''}, ${item['address']?['addressCountry'] ?? ''}',
              'guests': item['guests'] ?? 0,
              'bedrooms': item['bedrooms'] ?? 0,
              'beds': item['beds'] ?? 0,
              'photoUrls': item['photoUrls'] ?? [],
              'rating': 4.5,
              'reviews': 0,
              'period': 'gece',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favorites = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFavorite(int listingId) async {
    try {
      await ApiService.removeFromFavorites(listingId: listingId);
      
      setState(() {
        _favorites.removeWhere((item) => item['id'] == listingId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favorilerden çıkarıldı'),
          duration: Duration(seconds: 1),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Favorilerim'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz favori ilan yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Beğendiğiniz ilanları favorilere ekleyin',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final property = _favorites[index];
                final listingId = property['id'] as int;
                
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
                                    child: Image.network(
                                      (property['photoUrls'] as List).first,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 200,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.redAccent.withOpacity(0.7), Colors.orangeAccent.withOpacity(0.7)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              property['image'] ?? Icons.home,
                                              size: 80,
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        );
                                      },
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
                                        property['image'] ?? Icons.home,
                                        size: 80,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => _removeFavorite(listingId),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    size: 20,
                                    color: Colors.red,
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
                                  '${property['rating'] ?? 4.5}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  ' (${property['reviews'] ?? 0} değerlendirme)',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              property['title'] ?? 'İlan',
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
                                  property['location'] ?? '',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '₺${property['price'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                Text(
                                  ' / ${property['period'] ?? 'gece'}',
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
      bottomNavigationBar: widget.bottomNavBar,
    );
  }
}
