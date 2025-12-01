import 'package:flutter/material.dart';
import 'package:project_crypto_app/views/detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin_model.dart';
import '../services/coin_cache_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final CoinCacheService _cacheService = CoinCacheService();
  final TextEditingController _searchController = TextEditingController();

  List<CoinModel> _allCoins = [];
  List<CoinModel> _filteredCoins = [];
  String? _fullName;
  bool _isLoading = true;
  String? _errorMessage;

  // Untuk mencegah rebuild saat switch tab
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUserData();
    await _fetchCoins();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('fullName');
    if (mounted) {
      setState(() => _fullName = savedName ?? 'User');
    }
  }

  Future<void> _fetchCoins({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Gunakan cache service
      final coins = await _cacheService.fetchCoins(forceRefresh: forceRefresh);

      if (!mounted) return;

      setState(() {
        _allCoins = coins;
        _filteredCoins = coins;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final errorMsg = e.toString();
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg.contains('429')
            ? 'Terlalu banyak permintaan.\nSilakan tunggu beberapa menit.'
            : 'Gagal memuat data.\n$errorMsg';
      });
    }
  }

  void _filterCoins(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCoins = _allCoins);
      return;
    }

    final searchLower = query.toLowerCase();
    final results = _allCoins.where((coin) {
      return coin.name.toLowerCase().contains(searchLower) ||
          coin.symbol.toLowerCase().contains(searchLower);
    }).toList();

    setState(() => _filteredCoins = results);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Penting untuk AutomaticKeepAliveClientMixin

    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () => _fetchCoins(forceRefresh: true),
        color: const Color(0xFF7B1FA2),
        child: Stack(
          children: [
            _buildGradientHeaderCard(context, topPadding),
            Padding(
              padding: EdgeInsets.only(top: topPadding + 200),
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B1FA2)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 15),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _fetchCoins(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rekomendasi Crypto',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Indikator cache
              if (_cacheService.isCacheValid())
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cached',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCoins.length,
              padding: const EdgeInsets.only(bottom: 20),
              // Optimasi performa dengan itemExtent
              itemExtent: 90,
              itemBuilder: (context, index) {
                final coin = _filteredCoins[index];
                return _CryptoCard(
                  key: ValueKey(coin.id),
                  coin: coin,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(coin: coin),
                      ),
                    );
                    // Refresh data jika perlu setelah kembali
                    if (!_cacheService.isCacheValid()) {
                      _fetchCoins();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeaderCard(BuildContext context, double topPadding) {
    return Container(
      width: double.infinity,
      height: topPadding + 190,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50.0),
          bottomRight: Radius.circular(50.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(30, topPadding + 10, 30, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              _fullName == null ? 'Hi,' : 'Hi, $_fullName',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Lihat Harga Coin Crypto Saat Ini',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (query) {
          _filterCoins(query);
        },
        decoration: InputDecoration(
          hintText: 'Cari nama atau simbol crypto...',
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  splashRadius: 18,
                  onPressed: () {
                    _searchController.clear();
                    _filterCoins('');
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// Widget terpisah untuk optimasi rebuild
class _CryptoCard extends StatelessWidget {
  final CoinModel coin;
  final VoidCallback onTap;

  const _CryptoCard({Key? key, required this.coin, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUp = coin.priceChangePercentage24h >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF7B1FA2), Color(0xFFE53935)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.network(
                    coin.image,
                    width: 35,
                    height: 35,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.currency_bitcoin,
                      size: 35,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${coin.name} (${coin.symbol.toUpperCase()})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Harga: \$${coin.currentPrice.toStringAsFixed(2)} | 24h: ${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  color: isUp ? Colors.green : Colors.red,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
