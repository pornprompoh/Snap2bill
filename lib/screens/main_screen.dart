import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'bill/scan_screen.dart'; // 🚀 Import หน้าสแกน
import 'profile/profile_screen.dart'; // 🚀 Import หน้าโปรไฟล์

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
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              height: 72,
              elevation: 0,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.secondary.withValues(alpha: 0.7),
              indicatorShape: const StadiumBorder(),
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.history, color: AppColors.textSecondary),
                  selectedIcon: Icon(Icons.history, color: AppColors.primary),
                  label: 'ประวัติบิล',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.textSecondary,
                  ),
                  selectedIcon: Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primary,
                  ),
                  label: 'สแกนใหม่',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.person_outline,
                    color: AppColors.textSecondary,
                  ),
                  selectedIcon: Icon(Icons.person, color: AppColors.primary),
                  label: 'โปรไฟล์',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
