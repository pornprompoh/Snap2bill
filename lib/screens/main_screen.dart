import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'bill/scan_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ScanScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : AppColors.white;
    final navBorder = isDark ? AppColors.darkBorder : const Color(0xFFD6D6D6);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: navBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
              _buildNavItem(
                index: 0,
                icon: Icons.history_rounded,
                label: 'ประวัติบิล',
                isDark: isDark,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.document_scanner_outlined,
                label: 'แสกน',
                isDark: isDark,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person_outline_rounded,
                label: 'โปรไฟล์',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final labelColor = isSelected
        ? (isDark ? AppColors.darkTextPrimary : AppColors.black)
        : (isDark ? AppColors.darkTextSecondary : AppColors.gray);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active pink pill container or inactive icon (Matching reference image)
            if (isSelected)
              Container(
                width: 58,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: AppColors.white,
                  size: 20,
                ),
              )
            else
              SizedBox(
                height: 32,
                child: Center(
                  child: Icon(
                    icon,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.black,
                    size: 24,
                  ),
                ),
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
