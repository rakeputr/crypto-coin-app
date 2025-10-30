import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coin_model.dart';

class CoinService {
  final String baseUrl = "https://api.coingecko.com/api/v3";

  Future<List<CoinModel>> fetchCoins() async {
    final String fullUrl = "$baseUrl/coins/markets?vs_currency=usd";

    final response = await http.get(Uri.parse(fullUrl));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((v) => CoinModel.fromJson(v)).toList();
    } else {
      throw Exception("Gagal fetch data dari API CoinGecko");
    }
  }
}
