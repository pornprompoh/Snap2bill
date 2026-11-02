import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class CustomTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final Color foregroundColor;
  final int unreadCount;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onFriendsPressed;

  const CustomTopAppBar({
    super.key,
    this.title = 'Snap2Bill',
    required this.backgroundColor,
    required this.foregroundColor,
    this.unreadCount = 0,
    this.onNotificationsPressed,
    this.onFriendsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        if (onNotificationsPressed != null)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: foregroundColor,
                  size: 26,
                ),
                tooltip: 'การแจ้งเตือน',
                onPressed: onNotificationsPressed,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.pink,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        if (onFriendsPressed != null)
          IconButton(
            icon: Icon(
              Icons.people_alt_outlined,
              color: foregroundColor,
              size: 26,
            ),
            tooltip: 'เพื่อนในตี้',
            onPressed: onFriendsPressed,
          ),
        if (onNotificationsPressed != null || onFriendsPressed != null)
          const SizedBox(width: 8),
      ],
    );
  }
}
