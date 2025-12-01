import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  static const String _favKey = 'user_favorites';

  Future<Set<String>> getFavorites(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allFavs = prefs.getString(_favKey);

      if (allFavs == null) return {};

      final Map<String, dynamic> favsMap = jsonDecode(allFavs);
      final List<dynamic> userFavs = favsMap[userId] ?? [];

      return Set<String>.from(userFavs);
    } catch (e) {
      print('Error getting favorites: $e');
      return {};
    }
  }

  Future<bool> addFavorite(String userId, String coinId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allFavs = prefs.getString(_favKey);

      Map<String, dynamic> favsMap = {};
      if (allFavs != null) {
        favsMap = jsonDecode(allFavs);
      }

      List<dynamic> userFavs = favsMap[userId] ?? [];
      if (!userFavs.contains(coinId)) {
        userFavs.add(coinId);
        favsMap[userId] = userFavs;
        await prefs.setString(_favKey, jsonEncode(favsMap));
        print('✅ Added $coinId to favorites');
        return true;
      }

      return false;
    } catch (e) {
      print('Error adding favorite: $e');
      return false;
    }
  }

  Future<bool> removeFavorite(String userId, String coinId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allFavs = prefs.getString(_favKey);

      if (allFavs == null) return false;

      Map<String, dynamic> favsMap = jsonDecode(allFavs);
      List<dynamic> userFavs = favsMap[userId] ?? [];

      if (userFavs.contains(coinId)) {
        userFavs.remove(coinId);
        favsMap[userId] = userFavs;
        await prefs.setString(_favKey, jsonEncode(favsMap));
        print('✅ Removed $coinId from favorites');
        return true;
      }

      return false;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }

  Future<bool> isFavorite(String userId, String coinId) async {
    final favs = await getFavorites(userId);
    return favs.contains(coinId);
  }

  Future<bool> toggleFavorite(String userId, String coinId) async {
    final isFav = await isFavorite(userId, coinId);

    if (isFav) {
      return await removeFavorite(userId, coinId);
    } else {
      return await addFavorite(userId, coinId);
    }
  }

  Future<void> clearUserFavorites(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allFavs = prefs.getString(_favKey);

      if (allFavs == null) return;

      Map<String, dynamic> favsMap = jsonDecode(allFavs);
      favsMap.remove(userId);

      await prefs.setString(_favKey, jsonEncode(favsMap));
      print('🗑️ Cleared favorites for user $userId');
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }
}
