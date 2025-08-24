import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();
  
  static const String _favoritesKey = 'user_favorites';
  
  /// Get all favorite destinations
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      
      return favoritesJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Add destination to favorites
  Future<bool> addToFavorites(Map<String, dynamic> destination) async {
    try {
      final favorites = await getFavorites();
      final destinationId = destination['id'];
      
      // Check if already exists
      if (favorites.any((fav) => fav['id'] == destinationId)) {
        return false; // Already in favorites
      }
      
      favorites.add(destination);
      return await _saveFavorites(favorites);
    } catch (e) {
      return false;
    }
  }
  
  /// Remove destination from favorites
  Future<bool> removeFromFavorites(dynamic destinationId) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((fav) => fav['id'] == destinationId);
      return await _saveFavorites(favorites);
    } catch (e) {
      return false;
    }
  }
  
  /// Check if destination is in favorites
  Future<bool> isFavorite(dynamic destinationId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((fav) => fav['id'] == destinationId);
    } catch (e) {
      return false;
    }
  }
  
  /// Toggle favorite status
  Future<bool> toggleFavorite(Map<String, dynamic> destination) async {
    final destinationId = destination['id'];
    final isCurrentlyFavorite = await isFavorite(destinationId);
    
    if (isCurrentlyFavorite) {
      return await removeFromFavorites(destinationId);
    } else {
      return await addToFavorites(destination);
    }
  }
  
  /// Clear all favorites
  Future<bool> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_favoritesKey);
    } catch (e) {
      return false;
    }
  }
  
  /// Save favorites to storage
  Future<bool> _saveFavorites(List<Map<String, dynamic>> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = favorites.map((fav) => jsonEncode(fav)).toList();
      return await prefs.setStringList(_favoritesKey, favoritesJson);
    } catch (e) {
      return false;
    }
  }
  
  /// Get favorites count
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }
}
