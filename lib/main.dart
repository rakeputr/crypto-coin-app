import 'package:flutter/material.dart';
import 'package:project_crypto_app/views/developer_screen.dart';
import 'package:project_crypto_app/views/login_screen.dart';
import 'package:project_crypto_app/views/main_app_screen.dart';
import 'package:project_crypto_app/views/register_screen.dart';
import 'package:project_crypto_app/views/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_crypto_app/services/notification_service.dart';

bool isUserLoggedIn = false;
late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  prefs = await SharedPreferences.getInstance();
  isUserLoggedIn = prefs.getString('userId')?.isNotEmpty ?? false;

  await NotificationService.init();
  await NotificationService.scheduleDailyNotification();

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
