import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/in_app_notification_service.dart';
import '../../routes/app_routes.dart';

class NotificationCenterDialog extends StatefulWidget {
  final String? currentUserId;

  const NotificationCenterDialog({super.key, this.currentUserId});

  static Future<void> show(BuildContext context, {String? currentUserId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationCenterDialog(currentUserId: currentUserId),
    );
  }

  @override
  State<NotificationCenterDialog> createState() => _NotificationCenterDialogState();
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_outlined, color: AppColors.pink, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'ศูนย์แจ้งเตือน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.black,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  await InAppNotificationService.instance.markAllAsRead();
                  setState(() => _load());
                },
                child: const Text('อ่านทั้งหมดแล้ว', style: TextStyle(color: AppColors.pink, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<InAppNotificationItem>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.pink),
                  ),
                );
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'ไม่มีการแจ้งเตือนในขณะนี้',
                        style: TextStyle(color: AppColors.gray, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                            arguments: {
                              'id': item.billId,
                              'shop_name': item.shopName,
                            },
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
                                color: item.isRead
                                    ? Colors.grey.shade200
                                    : AppColors.lightPink,
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: item.isRead
                                                ? FontWeight.w600
                                                : FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.black,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey.shade300 : AppColors.gray,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')} • ${item.shopName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
