import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin_model.dart';
import '../services/coin_service.dart';
import '../services/database_helper.dart';
import 'detail_screen.dart';
import 'package:intl/intl.dart';

// Konstanta warna utama
const Color _primaryColor = Color(0xFF7B1FA2);
const Color _accentColor = Color(0xFFE53935);

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  late Future<List<CoinModel>> _favoriteCoinsFuture;
  final dbHelper = DatabaseHelper();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Panggil refresh data saat inisialisasi
    _favoriteCoinsFuture = _fetchFavorites();
  }

  // 🔥 Fungsi untuk mengambil semua data koin dan memfilternya berdasarkan favorit
  Future<List<CoinModel>> _fetchFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      // Jika belum login, kembalikan daftar kosong
      return [];
    }
    _currentUserId = userId;

    // 1. Ambil daftar ID koin yang difavoritkan dari SQLite
    final favMaps = await dbHelper.getFavorites(userId);
    final Set<String> favoriteCoinIds = favMaps
        .map((map) => map['coinId'] as String)
        .toSet();

    if (favoriteCoinIds.isEmpty) {
      return [];
    }

    // 2. Ambil daftar koin global dari API CoinGecko
    final allCoins = await CoinService().fetchCoins();

    // 3. Filter koin global hanya yang ada di daftar favorit
    final favoriteCoins = allCoins.where((coin) {
      return favoriteCoinIds.contains(coin.id);
    }).toList();

    return favoriteCoins;
  }

  // Helper untuk format mata uang
  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return format.format(amount);
  }

  // 🔥 Fungsi untuk refresh data saat kembali dari DetailScreen
  void _refreshFavorites() {
    setState(() {
      _favoriteCoinsFuture = _fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Karena FavoriteScreen ada di BottomNav, kita TIDAK perlu Gradient Header Card
    // Kita akan gunakan AppBar standar dari MainAppScreen (yang sudah Anda atur)
    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        title: Text(
          "Koin Favorit",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),

            // FutureBuilder untuk menampilkan daftar favorit
            Expanded(
              child: FutureBuilder<List<CoinModel>>(
                future: _favoriteCoinsFuture,
                builder: (context, snapshot) {
                  if (_currentUserId == null) {
                    return const Center(
                      child: Text(
                        'Anda harus login untuk melihat daftar favorit.',
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error memuat data: ${snapshot.error}'),
                    );
                  } else if (snapshot.data!.isEmpty) {
                    return Center(
                      child: Text('Anda belum menambahkan koin ke favorit.'),
                    );
                  } else {
                    final favoriteCoins = snapshot.data!;
                    return ListView.builder(
                      itemCount: favoriteCoins.length,
                      // Tambahkan padding di bawah agar tidak tertutup BottomNav
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        final coin = favoriteCoins[index];
                        return _buildCryptoCard(
                          context,
                          coin: coin,
                          onTap: () async {
                            // Navigasi ke detail dan tunggu (await) sampai kembali
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(coin: coin),
                              ),
                            );
                            // 🔥 Refresh list setelah kembali (untuk melihat perubahan favorite)
                            _refreshFavorites();
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Pembantu untuk Data Card Crypto (diambil dari HomeScreen)
  Widget _buildCryptoCard(
    BuildContext context, {
    required CoinModel coin,
    required VoidCallback onTap,
  }) {
    final isUp = coin.priceChangePercentage24h >= 0;
    final String formattedPrice = _formatCurrency(coin.currentPrice);
    final String formattedChange =
        '${coin.priceChangePercentage24h.toStringAsFixed(2)}%';

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
