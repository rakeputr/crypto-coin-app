import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../models/community_model.dart';
import '../services/database_helper.dart';

const Color _primaryColor = Color(0xFF7B1FA2);
const Color _secondaryColor = Color(0xFFE53935);

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFFE53935)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people_alt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    community.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
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
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _secondaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _secondaryColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 24),
        ),
      ),
    );

    return communityMarkers;
  }

  void _showCommunityDetails(BuildContext context, CommunityModel community) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B1FA2), Color(0xFFE53935)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      community.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Latitude: ${community.location.latitude.toStringAsFixed(4)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Longitude: ${community.location.longitude.toStringAsFixed(4)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFFE53935)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: _secondaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _launchGoogleMaps(
                        community.location.latitude,
                        community.location.longitude,
                      );
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.near_me, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Buka di Google Maps',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Komunitas Crypto Terdekat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7B1FA2), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
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
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B1FA2), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }
}
