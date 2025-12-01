import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin_model.dart';
import '../services/coin_cache_service.dart';
import '../services/favorite_service.dart';
import 'detail_screen.dart';
import 'package:intl/intl.dart';

const Color _primaryColor = Color(0xFF7B1FA2);
const Color _accentColor = Color(0xFFE53935);

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen>
    with AutomaticKeepAliveClientMixin {
  final CoinCacheService _cacheService = CoinCacheService();
  final FavoriteService _favoriteService = FavoriteService();

  List<CoinModel> _favoriteCoins = [];
  String? _currentUserId;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _currentUserId = null;
          });
        }
        return;
      }

      _currentUserId = userId;

      // 🔥 Ambil favorite IDs dari SharedPreferences (CEPAT!)
      final favoriteIds = await _favoriteService.getFavorites(userId);

      if (favoriteIds.isEmpty) {
        if (mounted) {
          setState(() {
            _favoriteCoins = [];
            _isLoading = false;
          });
        }
        return;
      }

      // 🔥 Ambil data coin dari CACHE, BUKAN dari API!
      List<CoinModel>? allCoins = _cacheService.getCachedCoins();

      // Jika cache kosong, fetch sekali saja
      if (allCoins == null || allCoins.isEmpty) {
        allCoins = await _cacheService.fetchCoins();
      }

      // Filter coin yang ada di favorites
      final favoriteCoins = allCoins
          .where((coin) => favoriteIds.contains(coin.id))
          .toList();

      if (mounted) {
        setState(() {
          _favoriteCoins = favoriteCoins;
          _isLoading = false;
        });
      }

      print('✅ Loaded ${favoriteCoins.length} favorite coins from CACHE');
    } catch (e) {
      print('Error loading favorites: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Koin Favorit",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Tombol refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        color: _primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentUserId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30.0),
          child: Text(
            'Anda harus login untuk melihat daftar favorit.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_favoriteCoins.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'Belum ada koin favorit',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Tambahkan koin ke favorit untuk melihatnya di sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            '${_favoriteCoins.length} Koin Favorit',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _favoriteCoins.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final coin = _favoriteCoins[index];
                return _buildCryptoCard(
                  context,
                  coin: coin,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(coin: coin),
                      ),
                    );
                    // Refresh setelah kembali dari detail
                    _loadFavorites();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoCard(
    BuildContext context, {
    required CoinModel coin,
    required VoidCallback onTap,
  }) {
    final isUp = coin.priceChangePercentage24h >= 0;
    final String formattedPrice = _formatCurrency(coin.currentPrice);
    final String formattedChange =
        '${coin.priceChangePercentage24h.toStringAsFixed(2)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.network(
            coin.image,
            width: 35,
            height: 35,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.currency_bitcoin,
              size: 35,
              color: _primaryColor,
            ),
          ),
        ),
        title: Text(
          '${coin.name} (${coin.symbol.toUpperCase()})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('Harga: $formattedPrice | 24h: $formattedChange'),
        trailing: Icon(
          isUp ? Icons.trending_up : Icons.trending_down,
          color: isUp ? Colors.green.shade700 : _accentColor,
          size: 28,
        ),
        onTap: onTap,
      ),
    );
  }
}
