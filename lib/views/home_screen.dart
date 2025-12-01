import 'package:flutter/material.dart';
import 'package:project_crypto_app/views/detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin_model.dart';
import '../services/coin_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<CoinModel>> futureCoins;
  List<CoinModel> allCoins = [];
  List<CoinModel> filteredCoins = [];

  final TextEditingController searchController = TextEditingController();

  String? fullName;

  @override
  void initState() {
    super.initState();
    futureCoins = CoinService().fetchCoins();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('fullName');
    debugPrint('Nama dari prefs: $savedName');

    if (mounted) {
      setState(() {
        fullName = savedName ?? 'User';
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterCoins(String query) {
    final searchLower = query.toLowerCase();

    if (query.isEmpty) {
      setState(() => filteredCoins = allCoins);
      return;
    }

    final results = allCoins.where((coin) {
      final nameLower = coin.name.toLowerCase();
      final symbolLower = coin.symbol.toLowerCase();
      return nameLower.contains(searchLower) ||
          symbolLower.contains(searchLower);
    }).toList();

    setState(() => filteredCoins = results);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          _buildGradientHeaderCard(context, topPadding),
          Padding(
            padding: EdgeInsets.only(top: topPadding + 200),
            child: FutureBuilder<List<CoinModel>>(
              future: futureCoins,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  final errorMsg = snapshot.error.toString();

                  // Jika error 429 Too Many Requests
                  if (errorMsg.contains('429')) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 60),
                          const SizedBox(height: 10),
                          const Text(
                            'Terlalu banyak permintaan.\nSilakan coba lagi nanti.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                futureCoins = CoinService().fetchCoins();
                              });
                            },
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Error lain
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $errorMsg'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              futureCoins = CoinService().fetchCoins();
                            });
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                } else {
                  if (allCoins.isEmpty) {
                    allCoins = snapshot.data!;
                    filteredCoins = allCoins;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Rekomendasi Crypto',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredCoins.length,
                            itemBuilder: (context, index) {
                              final coin = filteredCoins[index];
                              return _buildCryptoCard(
                                context,
                                title:
                                    '${coin.name} (${coin.symbol.toUpperCase()})',
                                subtitle:
                                    'Harga: \$${coin.currentPrice.toStringAsFixed(2)} | 24h: ${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                                imageUrl: coin.image,
                                isUp: coin.priceChangePercentage24h >= 0,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailScreen(coin: coin),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }
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
              fullName == null ? 'Hi,' : 'Hi, $fullName',
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
            _buildSearchBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (query) {
          _filterCoins(query);
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Cari nama atau simbol crypto...',
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: searchController.text.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    splashRadius: 18,
                    onPressed: () {
                      searchController.clear();
                      _filterCoins('');
                      setState(() {});
                    },
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCryptoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imageUrl,
    required bool isUp,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),

        // OUTER: GRADIENT BORDER + SHADOW
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF7B1FA2), // ungu
              Color(0xFFE53935), // merah
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),

        // PADDING UNTUK BORDER GRADIENT (PENTING!)
        child: Container(
          padding: const EdgeInsets.all(
            2,
          ), // <= INI YANG BIKIN GRADIENT KELIATAN

          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),

            // INNER WHITE CARD
            decoration: BoxDecoration(
              //ganti warna card disini
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),

            child: Row(
              children: [
                // ICON / IMAGE
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.network(imageUrl, width: 35, height: 35),
                ),

                const SizedBox(width: 14),

                // TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // ICON UP/DOWN
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
