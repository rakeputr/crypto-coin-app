import 'package:latlong2/latlong.dart'; // 🔥 Perlu import ini

class CommunityModel {
  final int id;
  final String name;
  final LatLng location; // Menggunakan LatLng dari latlong2

  CommunityModel({
    required this.id,
    required this.name,
    required this.location,
  });

  factory CommunityModel.fromMap(Map<String, dynamic> map) {
    return CommunityModel(
      id: map['id'] as int,
      name: map['name'] as String,
      // Mengonversi REAL (double) dari SQLite ke objek LatLng
      location: LatLng(map['latitude'] as double, map['longitude'] as double),
    );
  }
}
