import 'package:http/http.dart' as http;  //Rest API'ye istek göndermek için
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5211/api/Auth';

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
      Uri.parse('$baseUrl/login'),
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
  static Future<Map<String, dynamic>?> register(String fullName, String email, String password, String passwordConfirm) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
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
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  // Verify Code
  static Future<Map<String, dynamic>?> verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    return jsonDecode(response.body);
  }

  // Reset Password
  static Future<Map<String, dynamic>?> resetPassword(String email, String code, String newPassword, String newPasswordConfirm) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
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
      Uri.parse('http://10.0.2.2:5211/api/MyListings'),
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
      Uri.parse('http://10.0.2.2:5211/api/Listing/all'),
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
      Uri.parse('http://10.0.2.2:5211/api/Favorites/$listingId'),
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
      Uri.parse('http://10.0.2.2:5211/api/Favorites/$listingId'),
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
      Uri.parse('http://10.0.2.2:5211/api/Favorites'),
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
      Uri.parse('http://10.0.2.2:5211/api/Favorites/check/$listingId'),
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
      Uri.parse('http://10.0.2.2:5211/api/MyListings'),
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

  // İlan Sil
  static Future<Map<String, dynamic>?> deleteListing({
    required int listingId,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı. Lütfen giriş yapın.'};
    }

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:5211/api/MyListings/$listingId'),
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
      Uri.parse('http://10.0.2.2:5211/api/MyListings/$listingId'),
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
      Uri.parse('http://10.0.2.2:5211/api/Listing/$listingId'),
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
      Uri.parse('http://10.0.2.2:5211/api/User/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }
}