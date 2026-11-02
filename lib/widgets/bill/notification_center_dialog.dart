import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/notifications/in_app_notification_service.dart';
import '../../theme/app_colors.dart';
import '../common/mascot_state_view.dart';

class NotificationCenterDialog extends StatefulWidget {
  final String? currentUserId;

  const NotificationCenterDialog({super.key, this.currentUserId});

  static Future<void> show(BuildContext context, {String? currentUserId}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ปิดศูนย์แจ้งเตือน',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) =>
          NotificationCenterDialog(currentUserId: currentUserId),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  @override
  State<NotificationCenterDialog> createState() =>
      _NotificationCenterDialogState();
}

class _NotificationCenterDialogState extends State<NotificationCenterDialog> {
  late Future<List<InAppNotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _notificationsFuture = InAppNotificationService.instance.getNotifications(
      currentUserId: widget.currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 420,
        height: MediaQuery.of(context).size.height * 0.68,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.pink,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ศูนย์แจ้งเตือน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.black,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await InAppNotificationService.instance.markAllAsRead();
                      if (mounted) setState(_load);
                    },
                    child: const Text(
                      'อ่านทั้งหมดแล้ว',
                      style: TextStyle(color: AppColors.pink, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<InAppNotificationItem>>(
                  future: _notificationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.pink),
                      );
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(
                        child: MascotStateView(
                          state: MascotState.empty,
                          message: 'ยังไม่มีการแจ้งเตือน',
                          detail: 'ถ้ามีความเคลื่อนไหว Bunny จะรีบบอกคุณ',
                          size: 130,
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, index) => const Divider(height: 12),
                      itemBuilder: (context, index) =>
                          _NotificationTile(item: items[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final InAppNotificationItem item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await InAppNotificationService.instance.markAsRead(item.id);
        if (!context.mounted) return;
        Navigator.pop(context);
        if (item.billId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            AppRoutes.detail,
            arguments: {'id': item.billId, 'shop_name': item.shopName},
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: item.isRead
              ? Colors.transparent
              : AppColors.pink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.isRead ? Colors.grey.shade200 : AppColors.lightPink,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: item.isRead ? Colors.grey : AppColors.pink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.black,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.pink,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade300 : AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')} • ${item.shopName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
