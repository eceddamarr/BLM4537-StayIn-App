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

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _activeListings = [];
  List<Map<String, dynamic>> _archivedListings = [];
  bool _isLoadingActive = true;
  bool _isLoadingArchived = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActiveListings();
    _loadArchivedListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveListings() async {
    setState(() => _isLoadingActive = true);
    
    try {
      final listings = await ApiService.getMyListings();
      
      if (mounted) {
        setState(() {
          _activeListings = _processListings(listings);
          _isLoadingActive = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeListings = [];
          _isLoadingActive = false;
        });
      }
    }
  }

  Future<void> _loadArchivedListings() async {
    setState(() => _isLoadingArchived = true);
    
    try {
      final listings = await ApiService.getArchivedListings();
      
      if (mounted) {
        setState(() {
          _archivedListings = _processListings(listings);
          _isLoadingArchived = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _archivedListings = [];
          _isLoadingArchived = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _processListings(List<dynamic>? listings) {
    return (listings ?? []).map((item) {
      final Map<String, dynamic> listingData = Map<String, dynamic>.from(item);
      
      listingData['location'] = '${item['address']?['addressCity'] ?? ''}, ${item['address']?['addressCountry'] ?? ''}';
      
      List<String> photos = [];
      if (item['photoUrls'] != null && item['photoUrls'] is List) {
        photos = (item['photoUrls'] as List).map((e) => e.toString()).where((url) => url.isNotEmpty).toList();
      }
      
      listingData['photoUrls'] = photos.map((url) {
        if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) {
          return url;
        } else if (url.startsWith('/')) {
          return 'http://localhost:5211$url';
        } else {
          return 'http://localhost:5211/$url';
        }
      }).toList();
      
      listingData['rating'] = 4.5;
      listingData['reviews'] = 0;
      listingData['period'] = 'gece';
      
      return listingData;
    }).toList();
  }

  Future<void> _deleteListing(int listingId) async {
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
        _activeListings.removeWhere((item) => item['id'] == listingId);
        _archivedListings.removeWhere((item) => item['id'] == listingId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlan başarıyla silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _archiveListing(int listingId, bool isArchived) async {
    try {
      final result = await ApiService.archiveListing(listingId: listingId);
      
      if (result['success']) {
        // Listeyi yeniden yükle
        await _loadActiveListings();
        await _loadArchivedListings();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'İşlem başarılı')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'İşlem başarısız')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
  void _editListing(int listingId, bool isArchived) {
    // İlan bilgilerini bul
    final listing = (isArchived ? _archivedListings : _activeListings)
        .firstWhere((item) => item['id'] == listingId);
    
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
      _loadActiveListings();
      _loadArchivedListings();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.redAccent,
          tabs: [
            Tab(
              icon: const Icon(Icons.home_work),
              text: 'Aktif İlanlar (${_activeListings.length})',
            ),
            Tab(
              icon: const Icon(Icons.archive),
              text: 'Arşiv (${_archivedListings.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Aktif İlanlar
          _buildListingsView(_activeListings, _isLoadingActive, false),
          // Arşivlenmiş İlanlar
          _buildListingsView(_archivedListings, _isLoadingArchived, true),
        ],
      ),
      bottomNavigationBar: widget.bottomNavBar,
    );
  }

  Widget _buildListingsView(List<Map<String, dynamic>> listings, bool isLoading, bool isArchived) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArchived ? Icons.archive_outlined : Icons.home_work_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isArchived ? 'Arşivlenmiş ilan yok' : 'Henüz ilanınız yok',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArchived 
                ? 'Arşivlediğiniz ilanlar burada görünecek'
                : 'İlk ilanınızı oluşturun ve kazanmaya başlayın',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadActiveListings();
        await _loadArchivedListings();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          return _buildListingCard(listings[index], isArchived);
        },
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing, bool isArchived) {
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
          // Image with Archive badge
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
                
                // Archive badge
                if (isArchived)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.archive, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Arşivlendi',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Action buttons
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      // Archive/Unarchive button
                      GestureDetector(
                        onTap: () => _archiveListing(listingId, isArchived),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isArchived ? Icons.unarchive : Icons.archive,
                            size: 20,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Edit button
                      GestureDetector(
                        onTap: () => _editListing(listingId, isArchived),
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
                      // Delete button
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
}
}
