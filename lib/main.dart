import 'package:flutter/material.dart';
import 'package:project_crypto_app/views/developer_screen.dart';
import 'package:project_crypto_app/views/login_screen.dart';
import 'package:project_crypto_app/views/main_app_screen.dart';
import 'package:project_crypto_app/views/register_screen.dart';
import 'package:project_crypto_app/views/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_crypto_app/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';

bool isUserLoggedIn = false;
late SharedPreferences prefs;

Future<void> _initLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    debugPrint('Layanan lokasi tidak aktif. Membuka pengaturan lokasi...');
    await Geolocator.openLocationSettings();
    return;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('Izin lokasi ditolak oleh pengguna.');
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    debugPrint('Izin lokasi ditolak secara permanen.');
    return;
  }

  debugPrint('Izin lokasi diberikan ✅');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  prefs = await SharedPreferences.getInstance();
  isUserLoggedIn = prefs.getString('userId')?.isNotEmpty ?? false;

  await NotificationService.init();
  await NotificationService.scheduleDailyNotification();

  await _initLocation();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget initialScreen = isUserLoggedIn
        ? const MainAppScreen()
        : WelcomeScreen();

    return MaterialApp(
      title: 'CoinLens Crypto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: initialScreen,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainAppScreen(),
        '/developer': (context) => const DeveloperScreen(),
      },
    );
  }
}
