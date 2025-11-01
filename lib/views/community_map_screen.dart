import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../models/community_model.dart';
import '../services/database_helper.dart';

const Color _primaryColor = Color(0xFF7B1FA2);
const Color _accentColor = Color(0xFFE53935);

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final MapController mapController = MapController();

  List<CommunityModel> _communityMarkers = [];
  LatLng _currentLocation = const LatLng(-7.7785, 110.4075);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  void _launchGoogleMaps(double lat, double lon) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Google Maps.')),
      );
    }
  }

  Future<void> _loadMapData() async {
    Position? position;

    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      print('TimeoutException: Gagal mendapatkan lokasi GPS.');
      position = null;
    } catch (e) {
      print("Error loading map data: $e");
      position = null;
    }

    try {
      final List<Map<String, dynamic>> maps = await dbHelper
          .getAllCommunities();
      final List<CommunityModel> communities = maps
          .map((map) => CommunityModel.fromMap(map))
          .toList();

      if (!mounted) return;

      setState(() {
        if (position != null) {
          _currentLocation = LatLng(position.latitude, position.longitude);
        }
        _communityMarkers = communities;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(_currentLocation, 12.0);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        print("Error loading community data: $e");
      });
    }
  }

  List<Marker> _buildMarkers() {
    final communityMarkers = _communityMarkers.map((community) {
      return Marker(
        point: community.location,
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () {
            _showCommunityDetails(context, community);
          },
          child: Column(
            children: [
              const Icon(Icons.people_alt, color: _primaryColor, size: 35),
              Flexible(
                child: Text(
                  community.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    communityMarkers.add(
      Marker(
        point: _currentLocation,
        width: 60,
        height: 60,
        child: const Icon(Icons.my_location, color: _accentColor, size: 30),
      ),
    );

    return communityMarkers;
  }

  void _showCommunityDetails(BuildContext context, CommunityModel community) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                community.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const Divider(),
              Text(
                'Latitude: ${community.location.latitude.toStringAsFixed(4)}',
              ),
              Text(
                'Longitude: ${community.location.longitude.toStringAsFixed(4)}',
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Tutup modal
                  _launchGoogleMaps(
                    community.location.latitude,
                    community.location.longitude,
                  );
                },
                icon: const Icon(Icons.near_me, color: Colors.white),
                label: const Text(
                  'Buka di Google Maps',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Komunitas Crypto Terdekat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 12.0,
                maxZoom: 18.0,
                minZoom: 3.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.project_mobile_crypto',
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMapData,
        backgroundColor: _accentColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
