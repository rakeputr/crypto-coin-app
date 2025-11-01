import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Diperlukan untuk TimeoutException
import '../models/community_model.dart';
import '../services/database_helper.dart';

// Konstanta warna utama
const Color _primaryColor = Color(0xFF7B1FA2);
const Color _accentColor = Color(0xFFE53935);

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  // 🔥 MapController diinisialisasi secara late
  final MapController mapController = MapController();

  List<CommunityModel> _communityMarkers = [];
  LatLng _currentLocation = const LatLng(-6.2088, 106.8456); // Default Jakarta
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Panggil fungsi utama untuk memuat data
    _loadMapData();
  }

  // 🔥 FUNGSI UTAMA: Mengambil Lokasi Pengguna dan Data Komunitas
  Future<void> _loadMapData() async {
    Position? position;

    try {
      // 1. Ambil Lokasi Pengguna (dengan timeout)
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 15)); // Timeout disini

      // Izin lokasi diberikan dicetak di sini (log Anda sudah benar)
      print('Izin lokasi diberikan ✅');
    } on TimeoutException {
      // Jika terjadi Timeout, biarkan position null dan gunakan lokasi default
      print(
        'Error loading map data: TimeoutException after 0:00:15.000000: Future not completed',
      );
      position = null;
    } catch (e) {
      // Tangani error lainnya (Permission denied, service disabled, dll)
      print("Error loading map data: $e");
      position = null;
    }

    // 2. Ambil Data Komunitas dari SQLite
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

      // 🔥 PERBAIKAN: Pindahkan pemindahan peta ke sini.
      // Ini memastikan peta hanya dipindahkan setelah widget selesai di-build
      // dan MapController siap.
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

  // 🔥 FUNGSI: Membangun Marker untuk Komunitas
  List<Marker> _buildMarkers() {
    // ... (Logika marker sama) ...
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

    // Tambahkan marker untuk lokasi pengguna saat ini
    communityMarkers.add(
      Marker(
        point: _currentLocation,
        width: 60,
        height: 60,
        child: const Icon(
          Icons.my_location,
          color: _accentColor, // Warna aksen untuk lokasi sendiri
          size: 30,
        ),
      ),
    );

    return communityMarkers;
  }

  // 🔥 FUNGSI: Menampilkan detail komunitas saat marker diklik
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
              Text('Latitude: ${community.location.latitude}'),
              Text('Longitude: ${community.location.longitude}'),
              const SizedBox(height: 10),
              const Text('Bergabunglah dengan diskusi crypto terdekat!'),
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
                // 1. Layer Peta OpenStreetMap
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.project_mobile_crypto',
                ),

                // 2. Layer Marker Komunitas dan Lokasi User
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
