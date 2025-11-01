import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class LocationService {
  // 1. Dapatkan Posisi Saat Ini
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Tes apakah layanan lokasi aktif.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Cek izin
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      // 🔥 PENTING: Tambahkan timeout eksplisit pada Future GPS (misal, 10 detik)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Jika waktu habis, lemparkan error atau kembalikan null
          throw TimeoutException('Waktu tunggu GPS habis.');
        },
      );
    } catch (e) {
      // Tangani TimeoutException atau error lainnya saat mencoba mendapatkan posisi
      return null;
    }
  }

  // 2. Ubah Koordinat menjadi Nama Kota/Negara
  Future<String> _getAddressFromPosition(Position? position) async {
    if (position == null) {
      return "Lokasi Tidak Diketahui";
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        final city = placemark.locality;
        final subAdministrativeArea = placemark.subAdministrativeArea;
        final country = placemark.country;

        if (city != null && city.isNotEmpty) {
          return city;
        } else if (subAdministrativeArea != null &&
            subAdministrativeArea.isNotEmpty) {
          return subAdministrativeArea;
        } else if (country != null && country.isNotEmpty) {
          return country;
        }
      }
      return "Lokasi";
    } catch (e) {
      return "Lokasi";
    }
  }

  // 3. Fungsi utama untuk mendapatkan string lokasi siap pakai
  Future<String> getPersonalizedLocation() async {
    try {
      final position = await getCurrentPosition();
      return await _getAddressFromPosition(position);
    } catch (e) {
      // Jika ada timeout atau error lainnya, return default
      return "Lokasi Tidak Diketahui";
    }
  }
}
