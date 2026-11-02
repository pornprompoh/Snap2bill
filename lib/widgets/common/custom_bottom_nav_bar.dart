import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.history_rounded, label: 'ประวัติบิล'),
    (icon: Icons.document_scanner_outlined, label: 'แสกน'),
    (icon: Icons.person_outline_rounded, label: 'โปรไฟล์'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border, width: 1.2),
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
            for (var index = 0; index < _items.length; index++)
              _NavItem(
                icon: _items[index].icon,
                label: _items[index].label,
                isSelected: currentIndex == index,
                onTap: () => onTap(index),
                inactiveColor: colors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color inactiveColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                width: 58,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.white, size: 20),
              )
            else
              SizedBox(
                height: 32,
                child: Center(
                  child: Icon(icon, color: inactiveColor, size: 24),
                ),
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
