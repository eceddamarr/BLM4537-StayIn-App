import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final Set<String> _favoriteListingIds = {};
  final List<Map<String, dynamic>> _favoriteListings = [];
  String? _currentUserEmail;
  bool _isInitialized = false;

  // Kullanıcı email'ini set et
  void setUser(String? email) {
    if (_currentUserEmail != email) {
      _currentUserEmail = email;
      _isInitialized = false;
      _favoriteListingIds.clear();
      _favoriteListings.clear();
      if (email != null) {
        _loadFavorites();
      }
    }
  }

  // Favorileri SharedPreferences'tan yükle
  Future<void> _loadFavorites() async {
    if (_currentUserEmail == null || _isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'favorites_$_currentUserEmail';
    final favoritesJson = prefs.getString(key);
    
    if (favoritesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(favoritesJson);
        _favoriteListings.clear();
        _favoriteListingIds.clear();
        
        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            final id = item['id']?.toString();
            if (id != null) {
              _favoriteListingIds.add(id);
              _favoriteListings.add(item);
            }
          }
        }
      } catch (e) {
        // Error loading favorites
      }
    }
    
    _isInitialized = true;
  }

  // Favorileri SharedPreferences'a kaydet
  Future<void> _saveFavorites() async {
    if (_currentUserEmail == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'favorites_$_currentUserEmail';
    final favoritesJson = jsonEncode(_favoriteListings);
    await prefs.setString(key, favoritesJson);
  }

  // Favori ekle/çıkar
  Future<void> toggleFavorite(String listingId, Map<String, dynamic> listing) async {
    if (_currentUserEmail == null) {
      throw Exception('Favorilere eklemek için giriş yapmalısınız');
    }
    
    if (!_isInitialized) {
      await _loadFavorites();
    }
    
    if (_favoriteListingIds.contains(listingId)) {
      _favoriteListingIds.remove(listingId);
      _favoriteListings.removeWhere((item) => item['id']?.toString() == listingId);
    } else {
      _favoriteListingIds.add(listingId);
      _favoriteListings.add({...listing, 'id': listingId});
    }
    
    await _saveFavorites();
  }

  // Favori mi kontrol et
  Future<bool> isFavorite(String listingId) async {
    if (_currentUserEmail == null) return false;
    
    if (!_isInitialized) {
      await _loadFavorites();
    }
    
    return _favoriteListingIds.contains(listingId);
  }

  // Tüm favorileri getir
  Future<List<Map<String, dynamic>>> getFavorites() async {
    if (_currentUserEmail == null) return [];
    
    if (!_isInitialized) {
      await _loadFavorites();
    }
    
    return List.from(_favoriteListings);
  }

  // Favori sayısı
  Future<int> getCount() async {
    if (_currentUserEmail == null) return 0;
    
    if (!_isInitialized) {
      await _loadFavorites();
    }
    
    return _favoriteListings.length;
  }

  // Kullanıcı giriş yapmış mı?
  bool get isLoggedIn => _currentUserEmail != null;
}
