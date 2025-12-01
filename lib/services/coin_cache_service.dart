import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin_model.dart';
import 'coin_service.dart';

/// Service untuk caching data coin agar tidak perlu fetch API terus menerus
class CoinCacheService {
  static final CoinCacheService _instance = CoinCacheService._internal();
  factory CoinCacheService() => _instance;
  CoinCacheService._internal();

  final CoinService _coinService = CoinService();

  // Cache di memory
  List<CoinModel>? _cachedCoins;
  DateTime? _lastFetchTime;

  // Cache duration: 5 menit
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const String _cacheKey = 'coins_cache';
  static const String _cacheTimeKey = 'coins_cache_time';

  /// Fetch coins dengan caching mechanism
  Future<List<CoinModel>> fetchCoins({bool forceRefresh = false}) async {
    // Jika ada cache di memory dan belum expired, return cache
    if (!forceRefresh && _cachedCoins != null && _lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!);
      if (elapsed < _cacheDuration) {
        print('✅ Using MEMORY cache (${elapsed.inSeconds}s old)');
        return _cachedCoins!;
      }
    }

    // Coba ambil dari SharedPreferences jika memory cache kosong
    if (!forceRefresh && _cachedCoins == null) {
      final cachedData = await _loadFromPrefs();
      if (cachedData != null) {
        print('✅ Using STORAGE cache');
        _cachedCoins = cachedData;
        return cachedData;
      }
    }

    // Fetch dari API
    try {
      print('🌐 Fetching from API...');
      final coins = await _coinService.fetchCoins();

      // Simpan ke cache
      _cachedCoins = coins;
      _lastFetchTime = DateTime.now();
      await _saveToPrefs(coins);

      print('✅ API fetch success, cached ${coins.length} coins');
      return coins;
    } catch (e) {
      // Jika error dan ada cache lama, return cache lama
      if (_cachedCoins != null) {
        print('⚠️ API error, using old cache');
        return _cachedCoins!;
      }
      rethrow;
    }
  }

  /// Simpan cache ke SharedPreferences
  Future<void> _saveToPrefs(List<CoinModel> coins) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = coins
          .map(
            (coin) => {
              'id': coin.id,
              'symbol': coin.symbol,
              'name': coin.name,
              'image': coin.image,
              'current_price': coin.currentPrice,
              'market_cap': coin.marketCap,
              'price_change_percentage_24h': coin.priceChangePercentage24h,
              'last_updated': coin.lastUpdated,
              'high_24h': coin.high24h,
              'low_24h': coin.low24h,
            },
          )
          .toList();

      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving cache: $e');
    }
  }

  /// Load cache dari SharedPreferences
  Future<List<CoinModel>?> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      final timeString = prefs.getString(_cacheTimeKey);

      if (jsonString == null || timeString == null) return null;

      final cacheTime = DateTime.parse(timeString);
      final elapsed = DateTime.now().difference(cacheTime);

      // Jika cache sudah expired, return null
      if (elapsed > _cacheDuration) {
        print('⚠️ Storage cache expired');
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      _lastFetchTime = cacheTime;

      return jsonList.map((json) => CoinModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading cache: $e');
      return null;
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    _cachedCoins = null;
    _lastFetchTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);

    print('🗑️ Cache cleared');
  }

  /// Check apakah cache masih valid
  bool isCacheValid() {
    if (_lastFetchTime == null) return false;
    final elapsed = DateTime.now().difference(_lastFetchTime!);
    return elapsed < _cacheDuration;
  }

  /// Get cached coins tanpa fetch (untuk akses cepat)
  List<CoinModel>? getCachedCoins() => _cachedCoins;
}
