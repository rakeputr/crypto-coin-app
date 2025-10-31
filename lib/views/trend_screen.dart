import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/coin_model.dart';
import '../services/coin_service.dart';
import 'detail_screen.dart';

class TrendScreen extends StatefulWidget {
  const TrendScreen({super.key});

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  final CoinService _coinService = CoinService();
  List<CoinModel> _coins = [];
  bool _isLoading = true;
  String _country = "Negara Tidak Dikenal";
  String _currency = "usd";

  @override
  void initState() {
    super.initState();
    _getLocationAndLoadData();
  }

  Future<void> _getLocationAndLoadData() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Layanan lokasi tidak aktif.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Izin lokasi ditolak.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Izin lokasi ditolak permanen.");
      }

      final position = await Geolocator.getCurrentPosition();

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks.first;
      final country = place.country ?? "Unknown";

      final currency = _coinService.mapCountryToCurrency(country);

      final coins = await _coinService.fetchCoinsByCountry(country);

      if (!mounted) return;

      setState(() {
        _country = country;
        _currency = currency;
        _coins = coins;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _country = "Gagal mengambil lokasi";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildGradientHeaderCard(topPadding),
          Padding(
            padding: EdgeInsets.only(top: topPadding + 200),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _coins.isEmpty
                ? const Center(child: Text("Tidak ada data crypto ditemukan"))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          "Trending di $_country ($_currency) 🔥",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _coins.length,
                            itemBuilder: (context, index) {
                              final coin = _coins[index];
                              return _buildCryptoCard(
                                title:
                                    '${coin.name} (${coin.symbol.toUpperCase()})',
                                subtitle:
                                    'Harga: ${_currency.toUpperCase()} ${coin.currentPrice.toStringAsFixed(2)} | 24h: ${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
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
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeaderCard(double topPadding) {
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
          children: const [
            SizedBox(height: 10),
            Text(
              'Trending Market Crypto',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Berdasarkan Lokasi Kamu 🌍',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCryptoCard({
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
