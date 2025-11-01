import 'package:flutter/material.dart';
import 'package:project_crypto_app/views/community_map_screen.dart';
import 'package:project_crypto_app/views/home_screen.dart';
import 'package:project_crypto_app/views/favorite_screen.dart';
import 'package:project_crypto_app/views/user_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  static const Color _primaryColor = Color(0xFF7B1FA2);

  // 🔥 Daftar widget sekarang memiliki 4 item (Favorite disisipkan)
  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(), // Index 0: Beranda
    const FavoriteScreen(), // Index 1: Favorite (Baru)
    const CommunityMapScreen(), // Index 2: Trend (Bergeser)
    const UserScreen(), // Index 3: Profil (Bergeser)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: 'Komunitas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        backgroundColor: Colors.white,
      ),
    );
  }
}
