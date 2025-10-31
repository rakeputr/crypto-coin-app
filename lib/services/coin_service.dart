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

  String mapCountryToCurrency(String country) {
    final mapping = {
      "Indonesia": "idr",
      "United States": "usd",
      "Japan": "jpy",
      "India": "inr",
      "Germany": "eur",
      "United Kingdom": "gbp",
      "Australia": "aud",
      "Canada": "cad",
      "China": "cny",
      "Singapore": "sgd",
    };

    return mapping[country] ?? "usd";
  }

  Future<List<CoinModel>> fetchCoinsByCountry(String country) async {
    final vsCurrency = mapCountryToCurrency(country);
    final url = "$baseUrl/coins/markets?vs_currency=$vsCurrency";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((v) => CoinModel.fromJson(v)).toList();
    } else {
      throw Exception("Gagal fetch data untuk $country");
    }
  }
}
