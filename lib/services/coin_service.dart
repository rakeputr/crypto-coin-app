import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/coin_model.dart';

class CoinService {
  final String baseUrl = "https://api.coingecko.com/api/v3";

  Future<List<CoinModel>> fetchCoins() async {
    final String fullUrl = "$baseUrl/coins/markets?vs_currency=usd";

    try {
      final response = await http
          .get(Uri.parse(fullUrl))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw const SocketException(
                'Timeout: Koneksi terlalu lama tidak merespon.',
              );
            },
          );

      // ---- ERROR HANDLING BARU ----
      if (response.statusCode == 429) {
        throw Exception("429: Too Many Requests");
      }

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((v) => CoinModel.fromJson(v)).toList();
      } else {
        throw Exception(
          "Error ${response.statusCode}: Gagal mengambil data dari API.",
        );
      }
    } on SocketException catch (_) {
      throw Exception("Tidak ada koneksi internet.");
    } on HttpException catch (_) {
      throw Exception("Server tidak dapat diakses.");
    } on FormatException catch (_) {
      throw Exception("Format data dari server tidak valid.");
    } catch (e) {
      throw Exception("Error tidak diketahui: $e");
    }
  }

  // ------------------ OPTIONAL FEATURE: BY COUNTRY ------------------

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

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw SocketException("Timeout"),
          );

      if (response.statusCode == 429) {
        throw Exception("429: Too Many Requests");
      }

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((v) => CoinModel.fromJson(v)).toList();
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Terjadi error: $e");
    }
  }
}
