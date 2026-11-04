import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/bill_progress_helper.dart';
import '../../utils/formatters.dart';

class InAppNotificationItem {
  final String id;
  final String billId;
  final String shopName;
  final String recipientId;
  final String recipientName;
  final String senderId;
  final String senderName;
  final double amount;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;

  InAppNotificationItem({
    required this.id,
    required this.billId,
    required this.shopName,
    required this.recipientId,
    required this.recipientName,
    required this.senderId,
    required this.senderName,
    required this.amount,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory InAppNotificationItem.fromMap(Map<String, dynamic> map) =>
      InAppNotificationItem(
        id: map['id']?.toString() ?? '',
        billId: map['bill_id']?.toString() ?? '',
        shopName: map['shop_name']?.toString() ?? 'ไม่ระบุชื่อร้าน',
        recipientId: map['recipient_id']?.toString() ?? '',
        recipientName: map['recipient_name']?.toString() ?? 'เพื่อน',
        senderId: map['sender_id']?.toString() ?? '',
        senderName: map['sender_name']?.toString() ?? 'เจ้าของบิล',
        amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0,
        title: map['title']?.toString() ?? 'สะกิดเตือนบิล',
        message: map['message']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        isRead: map['is_read'] == true,
      );
}

class InAppNotificationService {
  static final InAppNotificationService instance = InAppNotificationService._();
  InAppNotificationService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<List<InAppNotificationItem>> notifications =
      ValueNotifier<List<InAppNotificationItem>>([]);
  RealtimeChannel? _notificationsChannel;
  String? _subscribedUserId;

  Future<void> listenToUser(
    String userId, {
    required ValueChanged<InAppNotificationItem> onNotification,
  }) async {
    if (_subscribedUserId == userId && _notificationsChannel != null) return;

    await stopListening();
    _subscribedUserId = userId;
    notifications.value = [];
    unreadCount.value = 0;

    final channel = _supabase.channel('user_notifications_$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_id',
          value: userId,
        ),
        callback: (payload) {
          final item = InAppNotificationItem.fromMap(payload.newRecord);
          if (item.id.isEmpty ||
              item.recipientId != userId ||
              _subscribedUserId != userId ||
              notifications.value.any((existing) => existing.id == item.id)) {
            return;
          }
          _publishNotifications([item, ...notifications.value]);
          onNotification(item);
        },
      );
    _notificationsChannel = channel;
    channel.subscribe((status, error) {
      if (error != null) {
        debugPrint('In-app notification subscription error: $error');
      }
      if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        debugPrint('In-app notification subscription status: $status');
      }
    });

    await refreshNotifications(currentUserId: userId);
  }

  Future<void> stopListening() async {
    final channel = _notificationsChannel;
    _notificationsChannel = null;
    _subscribedUserId = null;
    if (channel != null) await _supabase.removeChannel(channel);
  }

  Future<List<InAppNotificationItem>> getNotifications({
    String? currentUserId,
  }) => refreshNotifications(currentUserId: currentUserId);

  Future<List<InAppNotificationItem>> refreshNotifications({
    String? currentUserId,
  }) async {
    final userId = currentUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return [];

    final rows = await _supabase
        .from('notifications')
        .select()
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    final items = rows
        .map(
          (row) =>
              InAppNotificationItem.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
    if (_subscribedUserId == null || _subscribedUserId == userId) {
      _publishNotifications(items);
    }
    return items;
  }

  Future<int> sendBillReminders({
    required String billId,
    required String shopName,
    required List<BillParticipantStatus> unpaidMembers,
    required String senderId,
    required String senderName,
    String? promptPay,
    String? bankAccount,
  }) async {
    final recipients = unpaidMembers
        .where(
          (member) =>
              member.id.isNotEmpty &&
              !member.id.startsWith('guest_') &&
              member.id != senderId,
        )
        .toList();
    if (recipients.isEmpty) return 0;

    final records = recipients.map((member) {
      final title = 'สะกิดเตือนค่าอาหาร: $shopName';
      final message =
          'คุณมียอดค้างชำระ ${AppFormatters.formatCurrency(member.amount)} '
          'ของตี้ "$shopName" จาก $senderName รบกวนโอนเงินพร้อมแนบสลิปด้วยเน้อ';
      return {
        'bill_id': billId,
        'recipient_id': member.id,
        'recipient_name': member.name,
        'sender_id': senderId,
        'sender_name': senderName,
        'shop_name': shopName,
        'amount': member.amount,
        'title': title,
        'message': message,
      };
    }).toList();

    await _supabase.from('notifications').insert(records);
    return records.length;
  }

  Future<void> markAllAsRead({String? currentUserId}) async {
    final userId = currentUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', userId)
        .eq('is_read', false);
    await refreshNotifications(currentUserId: userId);
  }

  Future<void> markAsRead(String id, {String? currentUserId}) async {
    final userId = currentUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id)
        .eq('recipient_id', userId);
    await refreshNotifications(currentUserId: userId);
  }

  void _publishNotifications(List<InAppNotificationItem> items) {
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifications.value = List.unmodifiable(items.take(100));
    unreadCount.value = notifications.value
        .where((item) => !item.isRead)
        .length;
  }
}
