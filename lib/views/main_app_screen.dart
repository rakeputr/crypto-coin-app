import 'package:flutter/material.dart';
import 'package:project_crypto_app/views/home_screen.dart';
import 'package:project_crypto_app/views/placeholder_screen.dart';
import 'package:project_crypto_app/views/user_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  static const Color _primaryColor = Color(0xFF7B1FA2);

  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const PlaceholderScreen(title: 'Favorit'),
    const UserScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 1:
        return 'Favorit Anda';
      case 2:
        return 'Profil Pengguna';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex != 0
          ? AppBar(
              title: Text(
                _getAppBarTitle(_selectedIndex),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,

      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorit'),
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
