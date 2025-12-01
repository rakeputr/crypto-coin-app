import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin_model.dart';
import '../services/coin_cache_service.dart';
import '../services/favorite_service.dart';
import 'detail_screen.dart';
import 'package:intl/intl.dart';

const Color _primaryColor = Color(0xFF7B1FA2);
const Color _successColor = Color(0xFF26C281);
const Color _dangerColor = Color(0xFFEF4444);

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

      List<CoinModel>? allCoins = _cacheService.getCachedCoins();

      if (allCoins == null || allCoins.isEmpty) {
        allCoins = await _cacheService.fetchCoins();
      }

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
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _loadFavorites,
              color: _primaryColor,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: _primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7B1FA2), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Favorites',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your watchlist',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_favoriteCoins.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_favoriteCoins.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
          onPressed: _loadFavorites,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_currentUserId == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: 'Not Logged In',
        subtitle: 'Please login to view your favorites',
        color: _primaryColor,
      );
    }

    if (_isLoading) {
      return Container(
        height: 500,
        child: const Center(
          child: CircularProgressIndicator(
            color: _primaryColor,
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_favoriteCoins.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'No Favorites Yet',
        subtitle: 'Add coins to your favorites to track them here',
        color: Colors.grey.shade400,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Tracking ${_favoriteCoins.length} ${_favoriteCoins.length == 1 ? "coin" : "coins"}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _favoriteCoins.length,
            itemBuilder: (context, index) {
              final coin = _favoriteCoins[index];
              return _buildModernCryptoCard(
                context,
                coin: coin,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(coin: coin),
                    ),
                  );
                  _loadFavorites();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      height: 500,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCryptoCard(
    BuildContext context, {
    required CoinModel coin,
    required VoidCallback onTap,
  }) {
    final isUp = coin.priceChangePercentage24h >= 0;
    final changeColor = isUp ? _successColor : _dangerColor;
    final String formattedPrice = _formatCurrency(coin.currentPrice);
    final String formattedChange =
        '${coin.priceChangePercentage24h.abs().toStringAsFixed(2)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFFE53935)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.network(
                      coin.image,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.currency_bitcoin,
                        size: 28,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coin.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF2D3142),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            coin.symbol.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: changeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUp
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 11,
                                  color: changeColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  formattedChange,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: changeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
