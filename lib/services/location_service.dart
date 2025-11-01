import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

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
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Waktu tunggu GPS habis.');
        },
      );
    } catch (e) {
      return null;
    }
  }

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

  Future<String> getPersonalizedLocation() async {
    try {
      final position = await getCurrentPosition();
      return await _getAddressFromPosition(position);
    } catch (e) {
      return "Lokasi Tidak Diketahui";
    }
  }
}
