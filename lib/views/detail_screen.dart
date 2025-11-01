import 'package:flutter/material.dart';
import 'package:project_crypto_app/models/coin_model.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

// Konstanta warna utama
const Color _primaryColor = Color(0xFF7B1FA2);
const Color _accentColor = Color(0xFFE53935);

// Struktur data untuk Timezone
class TimeZoneData {
  final String label;
  final String offset;

  const TimeZoneData(this.label, this.offset);
}

// Struktur data untuk Mata Uang
class CurrencyData {
  final String code;
  final String symbol;
  final double exchangeRate;
  final String locale;

  const CurrencyData(this.code, this.symbol, this.exchangeRate, this.locale);
}

// Daftar zona waktu yang tersedia
const List<TimeZoneData> allTimeZones = [
  TimeZoneData('WIB (Jakarta)', '+0700'),
  TimeZoneData('WITA (Bali)', '+0800'),
  TimeZoneData('WIT (Ambon)', '+0900'),
  TimeZoneData('London (BST)', '+0100'),
];

// Daftar mata uang yang tersedia
const List<CurrencyData> allCurrencies = [
  CurrencyData('USD', '\$', 1.0, 'en_US'),
  CurrencyData('IDR', 'Rp', 16500.0, 'id_ID'),
  CurrencyData('EUR', '€', 0.92, 'fr_FR'),
  CurrencyData('GBP', '£', 0.81, 'en_GB'),
];

class DetailScreen extends StatefulWidget {
  final CoinModel coin;
  const DetailScreen({Key? key, required this.coin}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // STATE untuk fitur favorite dan collapse
  bool _isTimeExpanded = false;
  bool _isCurrencyExpanded = false;

  // STATE untuk status favorite dan ID Pengguna
  bool _isFavorite = false;
  String? _currentUserId;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadUserIdAndFavoriteStatus();
  }

  // FUNGSI: Memuat ID pengguna dan status favorite
  void _loadUserIdAndFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final isFav = await dbHelper.isFavorite(userId, widget.coin.id);
      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _isFavorite = isFav;
        });
      }
    }
  }

  // FUNGSI: Toggle status favorite dan Kirim Notifikasi
  void _toggleFavorite() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk menambah ke favorit.'),
        ),
      );
      return;
    }

    final coinId = widget.coin.id;
    String notificationBody = '';

    if (_isFavorite) {
      await dbHelper.removeFavorite(_currentUserId!, coinId);
      notificationBody = '${widget.coin.name} telah dihapus dari Favorit.';
    } else {
      await dbHelper.addFavorite(_currentUserId!, coinId);
      notificationBody = '${widget.coin.name} telah ditambahkan ke Favorit!';
    }

    if (mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
      });

      // KIRIM NOTIFIKASI LOKAL
      NotificationService.showNotification(
        title: 'Perubahan Daftar Favorit',
        body: notificationBody,
      );
    }
  }

  // Helper untuk format mata uang USD
  String _formatCurrency(double amount, CurrencyData currency) {
    final convertedAmount = amount * currency.exchangeRate;

    final format = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
    );
    return format.format(convertedAmount);
  }

  // Helper untuk format persentase
  String _formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(2)}%';
  }

  // Helper yang mengembalikan string waktu lengkap
  String _formatDateTimeWithTimeZone(String isoString, String offset) {
    try {
      final dateTime = DateTime.parse(isoString);
      final hourOffset = int.parse(offset.substring(0, 3));
      final minuteOffset = int.parse(offset.substring(3, 5));
      final offsetDuration = Duration(hours: hourOffset, minutes: minuteOffset);
      final localTime = dateTime.add(offsetDuration);
      final formatter = DateFormat('dd MMM yyyy HH:mm:ss');
      return formatter.format(localTime);
    } catch (e) {
      return "Waktu tidak valid";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Detail ${widget.coin.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        // 🔥 HAPUS: actions: [...]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildPriceHeader(),

            // 🔥 TAMBAHKAN: Tombol Love di sini
            _buildFavoriteButton(),

            const SizedBox(height: 20),

            _buildKeyStatsCard(),
            const SizedBox(height: 20),

            // --- DETAIL TAMBAHAN ---

            // 1. Simbol (Format satu baris)
            _buildDetailRow(
              'Simbol',
              widget.coin.symbol.toUpperCase(),
              icon: Icons.sell_outlined,
              isTwoLineFormat: false,
            ),

            // 2. Konversi Mata Uang
            _buildExpandableCurrencyRow(),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isCurrencyExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  ...allCurrencies.sublist(1).map((currency) {
                    final String formattedAmount = _formatCurrency(
                      widget.coin.currentPrice,
                      currency,
                    );

                    return _buildDetailRow(
                      'Harga ${currency.code}',
                      formattedAmount,
                      icon: Icons.paid_outlined,
                      isTwoLineFormat: false,
                    );
                  }).toList(),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),

            // 3. Zona Waktu
            _buildExpandableTimeRow(),

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isTimeExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  ...allTimeZones.sublist(1).map((tz) {
                    final String formattedTime = _formatDateTimeWithTimeZone(
                      widget.coin.lastUpdated,
                      tz.offset,
                    );

                    return _buildDetailRow(
                      'Zona ${tz.label}',
                      formattedTime,
                      icon: Icons.access_time_filled,
                      isTwoLineFormat: true,
                    );
                  }).toList(),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 WIDGET BARU: Tombol Favorite yang dipindahkan
  Widget _buildFavoriteButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Center(
        child: InkWell(
          onTap: _toggleFavorite,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _isFavorite ? _accentColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _accentColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _accentColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isFavorite ? 'DI FAVORIT' : 'TAMBAH KE FAVORIT',
                  style: const TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceHeader() {
    final isPositive = widget.coin.priceChangePercentage24h >= 0;
    final color = isPositive ? Colors.green.shade700 : _accentColor;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final usdCurrency = allCurrencies.firstWhere((c) => c.code == 'USD');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              widget.coin.image,
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.currency_bitcoin,
                size: 40,
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.coin.name, // Judul Coin
                textAlign: TextAlign.center, // Opsional: Judul tetap di tengah
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Text(
          _formatCurrency(widget.coin.currentPrice, usdCurrency),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 5),
            Text(
              _formatPercentage(widget.coin.priceChangePercentage24h),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Text(
              ' (24h)',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // ... (Widget _buildKeyStatsCard, _buildStatItem, _buildExpandableCurrencyRow, _buildExpandableTimeRow, _buildDetailRow tetap sama) ...

  Widget _buildKeyStatsCard() {
    final usdCurrency = allCurrencies.firstWhere((c) => c.code == 'USD');
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildStatItem(
              Icons.trending_up,
              'Harga Tertinggi (24j)',
              _formatCurrency(widget.coin.high24h, usdCurrency),
              Colors.green,
            ),
            const Divider(),
            _buildStatItem(
              Icons.trending_down,
              'Harga Terendah (24j)',
              _formatCurrency(widget.coin.low24h, usdCurrency),
              _accentColor,
            ),
            const Divider(),
            _buildStatItem(
              Icons.query_stats,
              'Kapitalisasi Pasar',
              _formatCurrency(widget.coin.marketCap, usdCurrency),
              _primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCurrencyRow() {
    final CurrencyData usd = allCurrencies.firstWhere((c) => c.code == 'USD');
    final String formattedPrice = _formatCurrency(
      widget.coin.currentPrice,
      usd,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _isCurrencyExpanded
            ? const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              )
            : BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isCurrencyExpanded = !_isCurrencyExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.paid_outlined, color: _primaryColor, size: 20),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konversi Mata Uang',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isCurrencyExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: _primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableTimeRow() {
    final TimeZoneData mainTz = allTimeZones.first;
    final String mainTime = _formatDateTimeWithTimeZone(
      widget.coin.lastUpdated,
      mainTz.offset,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _isTimeExpanded
            ? const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              )
            : BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isTimeExpanded = !_isTimeExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.update, color: _primaryColor, size: 20),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terakhir Diperbarui (${mainTz.label})',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mainTime,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isTimeExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: _primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    required IconData icon,
    required bool isTwoLineFormat,
  }) {
    if (!isTwoLineFormat) {
      return Container(
        // Style untuk Simbol dan Konversi (Horizontal)
        margin: _isCurrencyExpanded || _isTimeExpanded
            ? const EdgeInsets.only(bottom: 0)
            : const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: _isCurrencyExpanded || _isTimeExpanded
              ? null
              : BorderRadius.circular(10),
          border: _isCurrencyExpanded || _isTimeExpanded
              ? null
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primaryColor, size: 20),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      // Style untuk Zona Waktu (Vertikal/Dua Baris)
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 16),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
