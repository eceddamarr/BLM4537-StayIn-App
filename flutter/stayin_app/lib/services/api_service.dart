import 'package:http/http.dart' as http;  //Rest API'ye istek göndermek için
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5211/api';

  // Token'ı al
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Token'ı kaydet
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Token'ı sil
  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Login
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);  //Gelen yanıtı json.decode ile Dart objesine çevirir
      // Token'ı kaydet
      if (data['token'] != null) {
        await _saveToken(data['token']);
      }
      return data;
    } else {
      return jsonDecode(response.body);
    }
  }

  // Register
  static Future<Map<String, dynamic>?> register(String fullName, String email, String phoneNumber, String password, String passwordConfirm) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'passwordConfirm': passwordConfirm,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return jsonDecode(response.body);
    }
  }

  // Forgot Password
  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  // Verify Code
  static Future<Map<String, dynamic>?> verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    return jsonDecode(response.body);
  }

  // Reset Password
  static Future<Map<String, dynamic>?> resetPassword(String email, String code, String newPassword, String newPasswordConfirm) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
        'newPasswordConfirm': newPasswordConfirm,
      }),
    );
    return jsonDecode(response.body);
  }

  // Create Listing (İlan oluştur) - Token ile
  static Future<Map<String, dynamic>?> createListing({
    required String title,
    required String description,
    required String placeType,
    required String accommodationType,
    required int guests,
    required int bedrooms,
    required int beds,
    required int bathrooms,
    required List<String> amenities,
    required double price,
    required String country,
    required String city,
    required String district,
    required String street,
    String? building,
    String? postalCode,
    String? region,
    double? latitude,
    double? longitude,
    List<String>? photoUrls,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı. Lütfen giriş yapın.'};
    }

    final response = await http.post(
      Uri.parse('$baseUrl/MyListings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'placeType': placeType,
        'accommodationType': accommodationType,
        'guests': guests,
        'bedrooms': bedrooms,
        'beds': beds,
        'bathrooms': bathrooms,
        'amenities': amenities,
        'price': price,
        'addressCountry': country,
        'addressCity': city,
        'addressDistrict': district,
        'addressStreet': street,
        'addressBuilding': building ?? '',
        'addressPostalCode': postalCode ?? '',
        'addressRegion': region ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'photoUrls': photoUrls ?? [],
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'İlan oluşturulamadı: ${response.statusCode}'};
    }
  }

  // Get All Listings (Tüm ilanları getir)
  static Future<List<dynamic>?> getAllListings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Listing/all'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      return null;
    }
  }

  // Favorilere Ekle (Token ile)
  static Future<Map<String, dynamic>?> addToFavorites({
    required int listingId,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı. Lütfen giriş yapın.'};
    }

    final response = await http.post(
      Uri.parse('$baseUrl/Favorites/$listingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'Favorilere eklenemedi'};
    }
  }

  // Favorilerden Çıkar (Token ile)
  static Future<Map<String, dynamic>?> removeFromFavorites({
    required int listingId,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı. Lütfen giriş yapın.'};
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/Favorites/$listingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'Favorilerden çıkarılamadı'};
    }
  }

  // Kullanıcının Favorilerini Getir (Token ile)
  static Future<List<dynamic>?> getFavorites() async {
    final token = await _getToken();
    if (token == null) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/Favorites'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['favorites'] as List<dynamic>?;
    } else {
      return null;
    }
  }

  // Favori mi Kontrol Et (Token ile)
  static Future<bool> isFavorite({
    required int listingId,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.get(
      Uri.parse('$baseUrl/Favorites/check/$listingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isFavorite'] ?? false;
    } else {
      return false;
    }
  }

  // Logout - Token'ı temizle
  static Future<void> logout() async {
    await _clearToken();
  }

  // Kullanıcının Kendi İlanlarını Getir
  static Future<List<dynamic>?> getMyListings() async {
    final token = await _getToken();
    if (token == null) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/MyListings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['listings'] as List<dynamic>?;
    } else {
      return null;
    }
  }

  // Arşivlenmiş İlanları Getir
  static Future<List<dynamic>?> getArchivedListings() async {
    final token = await _getToken();
    if (token == null) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/MyListings/archived'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['listings'] as List<dynamic>?;
    } else {
      return null;
    }
  }

  // İlanı Arşivle/Arşivden Çıkar (Toggle)
  static Future<Map<String, dynamic>> archiveListing({
    required int listingId,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı. Lütfen giriş yapın.'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/MyListings/$listingId/archive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': 'İşlem başarısız'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // İlan Sil
  static Future<Map<String, dynamic>?> deleteListing({
    required int listingId,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı. Lütfen giriş yapın.'};
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/MyListings/$listingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'İlan silinemedi'};
    }
  }

  // İlan Güncelle
  static Future<Map<String, dynamic>?> updateListing({
    required int listingId,
    required String title,
    required String description,
    required String placeType,
    required String accommodationType,
    required int guests,
    required int bedrooms,
    required int beds,
    required int bathrooms,
    required List<String> amenities,
    required double price,
    required String country,
    required String city,
    required String district,
    required String street,
    String? building,
    String? postalCode,
    String? region,
    double? latitude,
    double? longitude,
    List<String>? photoUrls,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı. Lütfen giriş yapın.'};
    }

    // Backend Listing modeline uygun format
    final body = {
      'title': title,
      'description': description,
      'placeType': placeType,
      'accommodationType': accommodationType,
      'guests': guests,
      'bedrooms': bedrooms,
      'beds': beds,
      'bathrooms': bathrooms,
      'amenities': amenities,
      'price': price,
      'addressCountry': country,
      'addressCity': city,
      'addressDistrict': district,
      'addressStreet': street,
      'addressBuilding': building,
      'addressPostalCode': postalCode,
      'addressRegion': region,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrls': photoUrls ?? [],
    };

    final response = await http.put(
      Uri.parse('$baseUrl/MyListings/$listingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    
    
    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'message': responseData['message'] ?? 'İlan güncellendi'};
      } catch (e) {
        return {'success': true, 'message': 'İlan güncellendi'};
      }
    } else {
      return {'success': false, 'message': 'İlan güncellenemedi (${response.statusCode}): ${response.body}'};
    }
  }

  // İlan Detayını Getir (ID ile)
  static Future<Map<String, dynamic>?> getListingById(int listingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Listing/$listingId'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  // Kullanıcı Bilgilerini Getir (ID ile)
  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/User/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  // ============ RESERVATION API ============

  // Rezervasyon Oluştur
  static Future<Map<String, dynamic>> createReservation({
    required int listingId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guests,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı. Lütfen giriş yapın.'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Reservation/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'listingId': listingId,
          'checkInDate': checkInDate.toIso8601String(),
          'checkOutDate': checkOutDate.toIso8601String(),
          'guests': guests,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'], 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Rezervasyon oluşturulamadı'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Mevcut Rezervasyon Kontrolü
  static Future<bool> checkExistingReservation(int listingId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Reservation/check/$listingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['hasReservation'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Kullanıcının Rezervasyonları (Guest - Yapılan)
  static Future<List<dynamic>> getMyReservations() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Reservation/my-reservations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reservations'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Gelen Rezervasyon Talepleri (Host)
  static Future<List<dynamic>> getIncomingRequests() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Reservation/incoming-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['requests'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Rezervasyonu Onayla (Host)
  static Future<Map<String, dynamic>> approveReservation(int reservationId) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Reservation/$reservationId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Onaylanamadı'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Rezervasyonu Reddet (Host)
  static Future<Map<String, dynamic>> rejectReservation(int reservationId) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Reservation/$reservationId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Reddedilemedi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Rezervasyonu İptal Et (Guest)
  static Future<Map<String, dynamic>> cancelReservation(int reservationId) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Reservation/$reservationId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'İptal edilemedi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Profil güncelleme
  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Auth/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Profil güncellendi'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Güncelleme başarısız'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Şifre değiştirme
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Şifre değiştirildi'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Şifre değiştirilemedi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Kullanıcı bilgilerini getir
  static Future<Map<String, dynamic>> getUserInfo() async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'user': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Kullanıcı bilgileri alınamadı'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // ============== YORUM (REVIEW) İŞLEMLERİ ==============

  // İlan yorumlarını getir
  static Future<Map<String, dynamic>> getListingReviews(int listingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Reviews/listing/$listingId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Yorumlar alınamadı'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Yorum oluştur
  static Future<Map<String, dynamic>> createReview({
    required int reservationId,
    required int rating,
    required String comment,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reservationId': reservationId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'], 'review': data['review']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Yorum eklenemedi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Kullanıcının yorumlarını getir
  static Future<Map<String, dynamic>> getMyReviews() async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Reviews/my-reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Yorumlar alınamadı'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Rezervasyon için yapılmış yorum var mı kontrol et
  static Future<Map<String, dynamic>?> getReviewByReservation(int reservationId) async {
    final result = await getMyReviews();
    if (result['success']) {
      final reviews = result['data'] as List;
      try {
        return reviews.firstWhere(
          (review) => review['reservationId'] == reservationId,
          orElse: () => null,
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Yorum sil
  static Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/Reviews/$reviewId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Yorum silinemedi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Yorum güncelle
  static Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int reservationId,
    required int rating,
    required String comment,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Reviews/$reviewId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reservationId': reservationId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'], 'review': data['review']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Yorum güncellenemedi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // ============== PAYMENT ENDPOINTS ==============

  // Rezervasyon için ödeme yap
  static Future<Map<String, dynamic>> processPayment({
    required int reservationId,
    required String cardNumber,
    required String cardHolder,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required double amount,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Payments/reservation/$reservationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'cardNumber': cardNumber,
          'cardHolder': cardHolder,
          'expiryMonth': expiryMonth,
          'expiryYear': expiryYear,
          'cvv': cvv,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Ödeme yapılamadı'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // Rezervasyon ödeme detayı
  static Future<Map<String, dynamic>> getPaymentByReservation(int reservationId) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Payments/reservation/$reservationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Ödeme bilgisi bulunamadı'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }
}
