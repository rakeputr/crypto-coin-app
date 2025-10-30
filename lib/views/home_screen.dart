import 'package:flutter/material.dart';
import 'package:project_crypto_app/views/detail_screen.dart';
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

  @override
  void initState() {
    super.initState();

    futureCoins = CoinService().fetchCoins();
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
      backgroundColor: Colors.white,
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
                  return Center(child: Text('Error: ${snapshot.error}'));
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

            const Text(
              'Hi, User',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Lihat Harga Crypto Saat Ini',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
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
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.network(imageUrl, width: 35, height: 35),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          isUp ? Icons.trending_up : Icons.trending_down,
          color: isUp ? Colors.green : Colors.red,
          size: 28,
        ),
        onTap: onTap,
      ),
    );
  }
}
