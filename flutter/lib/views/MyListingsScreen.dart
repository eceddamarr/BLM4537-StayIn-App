import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'HostHomeScreen.dart';
import 'dart:convert';

class MyListingsScreen extends StatefulWidget {
  final Widget? bottomNavBar;
  final String userEmail;
  final String userFullName;
  
  const MyListingsScreen({
    Key? key, 
    this.bottomNavBar,
    required this.userEmail,
    required this.userFullName,
  }) : super(key: key);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<Map<String, dynamic>> _myListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyListings();
  }

  Future<void> _loadMyListings() async {
    setState(() => _isLoading = true);
    
    try {
      final listings = await ApiService.getMyListings();
      
      if (mounted) {
        setState(() {
          _myListings = (listings ?? []).map((item) {
            // Tüm backend verisini koru, sadece UI için ek alanlar ekle
            final Map<String, dynamic> listingData = Map<String, dynamic>.from(item);
            
            // UI için ek alanlar
            listingData['location'] = '${item['address']?['city'] ?? item['address']?['addressCity'] ?? ''}, ${item['address']?['country'] ?? item['address']?['addressCountry'] ?? ''}';
            
            // Fotoğraf URL'lerini işle - backend'den gelen veriyi direkt kullan
            List<String> photos = [];
            if (item['photoUrls'] != null && item['photoUrls'] is List) {
              photos = (item['photoUrls'] as List).map((e) => e.toString()).where((url) => url.isNotEmpty).toList();
            } else if (item['photos'] != null && item['photos'] is List) {
              photos = (item['photos'] as List).map((e) => e.toString()).where((url) => url.isNotEmpty).toList();
            }
            
            // URL'leri tam path'e çevir (eğer göreli path ise)
            listingData['photoUrls'] = photos.map((url) {
              if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) {
                return url; // Zaten tam URL veya data URI (base64)
              } else if (url.startsWith('/')) {
                return 'http://10.0.2.2:5211$url'; // Göreli path - backend URL'i ekle
              } else {
                return 'http://10.0.2.2:5211/$url'; // Göreli path (/ ile başlamayan)
              }
            }).toList();
            
            listingData['rating'] = 4.5;
            listingData['reviews'] = 0;
            listingData['period'] = 'gece';
            
            return listingData;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _myListings = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteListing(int listingId) async {
    // Onay dialogu göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlanı Sil'),
        content: const Text('Bu ilanı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteListing(listingId: listingId);
      
      setState(() {
        _myListings.removeWhere((item) => item['id'] == listingId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlan başarıyla silindi'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
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

  void _editListing(int listingId) {
    // İlan bilgilerini bul
    final listing = _myListings.firstWhere((item) => item['id'] == listingId);
    
    // HostHomeScreen'e git (edit modunda)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HostHomeScreen(
          userEmail: widget.userEmail,
          userFullName: widget.userFullName,
          editMode: true,
          existingListing: listing,
        ),
      ),
    ).then((_) {
      // Geri döndüğünde ilanları yeniden yükle
      _loadMyListings();
    });
  }

  // Helper method to build image widget for different URL types
  Widget _buildImageWidget(String imageUrl, {double? height, double? width}) {
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
                  Icons.home,
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
              Icons.home,
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
                Icons.home,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          );
        },
      );
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('İlanlarım'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myListings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz ilanınız yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'İlk ilanınızı oluşturun ve kazanmaya başlayın',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: İlan oluşturma sayfasına git
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('İlan oluşturma özelliği zaten mevcut - "Ev Sahipliği Yapın" sayfasına gidin'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('İlan Oluştur', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myListings.length,
                  itemBuilder: (context, index) {
                    final listing = _myListings[index];
                    final listingId = listing['id'] as int;
                    
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
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Stack(
                              children: [
                                // Fotoğraf
                                listing['photoUrls'] != null && (listing['photoUrls'] as List).isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: _buildImageWidget(
                                          (listing['photoUrls'] as List).first,
                                          height: 200,
                                          width: double.infinity,
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
                                            Icons.home,
                                            size: 80,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ),
                                // Düzenle ve Sil butonları
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Row(
                                    children: [
                                      // Düzenle butonu
                                      GestureDetector(
                                        onTap: () {
                                          _editListing(listing['id']);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Sil butonu
                                      GestureDetector(
                                        onTap: () => _deleteListing(listingId),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                      '${listing['rating'] ?? 4.5}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      ' (${listing['reviews'] ?? 0} değerlendirme)',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  listing['title'] ?? 'İlan',
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
                                      listing['location'] ?? '',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '₺${listing['price'] ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    Text(
                                      ' / ${listing['period'] ?? 'gece'}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${listing['guests']} misafir · ${listing['bedrooms']} yatak odası · ${listing['beds']} yatak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (listing['createdAt'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Oluşturulma: ${_formatDate(listing['createdAt'])}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
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
