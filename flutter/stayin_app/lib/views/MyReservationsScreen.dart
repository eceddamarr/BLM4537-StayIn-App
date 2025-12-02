import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'AddReviewScreen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  List<dynamic> reservations = [];
  List<dynamic> myReviews = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getMyReservations();
      final reviewsResult = await ApiService.getMyReviews();
      
      if (mounted) {
        setState(() {
          reservations = data;
          myReviews = reviewsResult['success'] ? reviewsResult['data'] : [];
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rezervasyonlar yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _cancelReservation(int reservationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rezervasyonu İptal Et'),
        content: const Text('Bu rezervasyonu iptal etmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Evet, İptal Et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.cancelReservation(reservationId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'İşlem tamamlandı')),
      );
      if (result['success']) {
        _loadReservations();
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  void _showReviewDialog(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.rate_review, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Yorumunuz'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Yıldızlar
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review['rating'] ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                );
              }),
            ),
            const SizedBox(height: 16),
            // Yorum metni
            Text(
              review['comment'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            // Tarih
            Text(
              'Yorum tarihi: ${DateTime.parse(review['createdAt']).day}/${DateTime.parse(review['createdAt']).month}/${DateTime.parse(review['createdAt']).year}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddReviewScreen(
                    reservationId: review['reservationId'],
                    listingTitle: review['listingTitle'] ?? 'İlan',
                    existingReview: review,
                    onReviewAdded: _loadReservations,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Düzenle', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Yorumu Sil'),
                  content: const Text('Bu yorumu silmek istediğinizden emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hayır'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Evet, Sil', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final result = await ApiService.deleteReview(review['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'İşlem tamamlandı'),
                      backgroundColor: result['success'] ? Colors.green : Colors.red,
                    ),
                  );
                  if (result['success']) {
                    _loadReservations();
                  }
                }
              }
            },
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Sil', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rezervasyonlarım'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : reservations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz rezervasyonunuz yok',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReservations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = reservations[index];
                      final status = reservation['status'] ?? 'Unknown';
                      final checkInDate = DateTime.parse(reservation['checkInDate']);
                      final checkOutDate = DateTime.parse(reservation['checkOutDate']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image and Title
                            if (reservation['listingPhotoUrl'] != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  reservation['listingPhotoUrl'],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.home, size: 60),
                                    );
                                  },
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title and Status
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          reservation['listingTitle'] ?? 'İlan',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _getStatusColor(status),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(status),
                                          style: TextStyle(
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Dates
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${checkInDate.day}/${checkInDate.month}/${checkInDate.year} - ${checkOutDate.day}/${checkOutDate.month}/${checkOutDate.year}',
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Guests and Price
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16),
                                      const SizedBox(width: 8),
                                      Text('${reservation['guests']} misafir'),
                                      const Spacer(),
                                      Text(
                                        '₺${reservation['totalPrice']}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Cancel Button (only for Pending and Approved AND future/ongoing reservations)
                                  if ((status.toLowerCase() == 'pending' || status.toLowerCase() == 'approved') && 
                                      checkOutDate.isAfter(DateTime.now())) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => _cancelReservation(reservation['id']),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                        child: const Text('Rezervasyonu İptal Et'),
                                      ),
                                    ),
                                  ],
                                  
                                  // Review Button (only for completed approved reservations)
                                  if (status.toLowerCase() == 'approved' && 
                                      checkOutDate.isBefore(DateTime.now())) ...[
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                        // Bu rezervasyon için yorum yapılmış mı kontrol et
                                        final existingReview = myReviews.where(
                                          (review) => review['reservationId'] == reservation['id']
                                        ).firstOrNull;
                                        
                                        final hasReview = existingReview != null;
                                        
                                        return SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              if (hasReview) {
                                                // Yorumu göster
                                                _showReviewDialog(existingReview);
                                              } else {
                                                // Yeni yorum ekle
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => AddReviewScreen(
                                                      reservationId: reservation['id'],
                                                      listingTitle: reservation['listingTitle'] ?? 'İlan',
                                                      onReviewAdded: _loadReservations,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            icon: Icon(
                                              hasReview ? Icons.rate_review : Icons.star,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              hasReview ? 'Yorumumu Gör' : 'Yorum Yap',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber[700],
                                              elevation: 0,
                                            ),
                                          ),
                                        );
                                      },
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
                ),
    );
  }
}
