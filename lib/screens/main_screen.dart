import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'scan_screen.dart';     // 🚀 Import หน้าสแกน
import 'profile/profile_screen.dart';  // 🚀 Import หน้าโปรไฟล์

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 🚀 ใส่หน้าของจริงเข้าไปใน List แทนที่ Text ว่างๆ
  final List<Widget> _pages = [
    const HomeScreen(),
    const ScanScreen(), 
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: Colors.blue),
            label: 'ประวัติบิล',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner, color: Colors.blue),
            label: 'สแกนใหม่',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.blue),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}