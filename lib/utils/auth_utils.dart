import 'dart:convert';
import 'package:crypto/crypto.dart';

// Fungsi untuk mengenkripsi (hashing) password menggunakan SHA-256
String hashPassword(String password) {
  // Convert string ke List of bytes
  final bytes = utf8.encode(password);

  // Hasilkan hash SHA-256
  final digest = sha256.convert(bytes);

  // Kembalikan hash dalam format string hex
  return digest.toString();
}
