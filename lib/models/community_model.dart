import 'package:latlong2/latlong.dart';

class CommunityModel {
  final int id;
  final String name;
  final LatLng location;

  CommunityModel({
    required this.id,
    required this.name,
    required this.location,
  });

  factory CommunityModel.fromMap(Map<String, dynamic> map) {
    return CommunityModel(
      id: map['id'] as int,
      name: map['name'] as String,
      location: LatLng(map['latitude'] as double, map['longitude'] as double),
    );
  }
}
