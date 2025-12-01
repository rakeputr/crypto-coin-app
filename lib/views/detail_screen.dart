import 'package:flutter/material.dart';
import 'package:project_crypto_app/models/coin_model.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/favorite_service.dart';
import '../services/notification_service.dart';

const Color _primaryColor = Color(0xFF6C63FF);
const Color _successColor = Color(0xFF26C281);
const Color _dangerColor = Color(0xFFEF4444);

class TimeZoneData {
  final String label;
  final String offset;
  const TimeZoneData(this.label, this.offset);
}

class CurrencyData {
  final String code;
  final String symbol;
  final double exchangeRate;
  final String locale;
  const CurrencyData(this.code, this.symbol, this.exchangeRate, this.locale);
}

const List<TimeZoneData> allTimeZones = [
  TimeZoneData('WIB (Jakarta)', '+0700'),
  TimeZoneData('WITA (Bali)', '+0800'),
  TimeZoneData('WIT (Ambon)', '+0900'),
  TimeZoneData('London (BST)', '+0100'),
];

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
  final FavoriteService _favoriteService = FavoriteService();

  bool _isTimeExpanded = false;
  bool _isCurrencyExpanded = false;
  bool _isFavorite = false;
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadUserIdAndFavoriteStatus();
  }

  Future<void> _loadUserIdAndFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final isFav = await _favoriteService.isFavorite(userId, widget.coin.id);
      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _isFavorite = isFav;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must login to add favorites'),
          backgroundColor: _dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final coinId = widget.coin.id;
    String notificationBody = '';

    if (_isFavorite) {
      await _favoriteService.removeFavorite(_currentUserId!, coinId);
      notificationBody = '${widget.coin.name} removed from favorites';
    } else {
      await _favoriteService.addFavorite(_currentUserId!, coinId);
      notificationBody = '${widget.coin.name} added to favorites!';
    }

    if (mounted) {
      setState(() => _isFavorite = !_isFavorite);

      NotificationService.showNotification(
        title: 'Favorites Updated',
        body: notificationBody,
      );
    }
  }

  String _formatCurrency(double amount, CurrencyData currency) {
    final convertedAmount = amount * currency.exchangeRate;
    final format = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
    );
    return format.format(convertedAmount);
  }

  String _formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(2)}%';
  }

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
      return "Invalid time";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.coin.priceChangePercentage24h >= 0;
    final changeColor = isPositive ? _successColor : _dangerColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 3,
              ),
            )
          : CustomScrollView(
              slivers: [
                _buildModernAppBar(changeColor),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildPriceCard(changeColor),
                        const SizedBox(height: 20),
                        _buildKeyStatsCard(),
                        const SizedBox(height: 20),
                        _buildExpandableCurrencySection(),
                        const SizedBox(height: 12),
                        _buildExpandableTimeSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModernAppBar(Color changeColor) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: _primaryColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isFavorite
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red.shade300 : Colors.white,
                size: 22,
              ),
            ),
            onPressed: _toggleFavorite,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 20, 60, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.network(
                    widget.coin.image,
                    height: 48,
                    width: 48,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.currency_bitcoin,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.coin.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(Color changeColor) {
    final usdCurrency = allCurrencies.firstWhere((c) => c.code == 'USD');
    final isPositive = widget.coin.priceChangePercentage24h >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Price',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(widget.coin.currentPrice, usdCurrency),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 20,
                  color: changeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatPercentage(widget.coin.priceChangePercentage24h),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: changeColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(24h)',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStatsCard() {
    final usdCurrency = allCurrencies.firstWhere((c) => c.code == 'USD');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            Icons.arrow_upward,
            '24h High',
            _formatCurrency(widget.coin.high24h, usdCurrency),
            _successColor,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            Icons.arrow_downward,
            '24h Low',
            _formatCurrency(widget.coin.low24h, usdCurrency),
            _dangerColor,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            Icons.donut_large,
            'Market Cap',
            _formatCurrency(widget.coin.marketCap, usdCurrency),
            _primaryColor,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            Icons.code,
            'Symbol',
            widget.coin.symbol.toUpperCase(),
            Colors.grey.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableCurrencySection() {
    final usd = allCurrencies.first;
    final formattedPrice = _formatCurrency(widget.coin.currentPrice, usd);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _isCurrencyExpanded = !_isCurrencyExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.currency_exchange,
                      color: _primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Currency Conversion',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedPrice,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3142),
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
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isCurrencyExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: allCurrencies.sublist(1).map((currency) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currency.code,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatCurrency(widget.coin.currentPrice, currency),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableTimeSection() {
    final mainTz = allTimeZones.first;
    final mainTime = _formatDateTimeWithTimeZone(
      widget.coin.lastUpdated,
      mainTz.offset,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isTimeExpanded = !_isTimeExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: _primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Updated (${mainTz.label})',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mainTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3142),
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
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isTimeExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: allTimeZones.sublist(1).map((tz) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tz.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDateTimeWithTimeZone(
                          widget.coin.lastUpdated,
                          tz.offset,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
