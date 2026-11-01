import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/bill_progress_helper.dart';

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

  Map<String, dynamic> toMap() => {
        'id': id,
        'bill_id': billId,
        'shop_name': shopName,
        'recipient_id': recipientId,
        'recipient_name': recipientName,
        'sender_id': senderId,
        'sender_name': senderName,
        'amount': amount,
        'title': title,
        'message': message,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };

  factory InAppNotificationItem.fromMap(Map<String, dynamic> map) =>
      InAppNotificationItem(
        id: map['id']?.toString() ?? '',
        billId: map['bill_id']?.toString() ?? '',
        shopName: map['shop_name']?.toString() ?? 'ไม่ระบุชื่อร้าน',
        recipientId: map['recipient_id']?.toString() ?? '',
        recipientName: map['recipient_name']?.toString() ?? 'เพื่อน',
        senderId: map['sender_id']?.toString() ?? '',
        senderName: map['sender_name']?.toString() ?? 'เจ้าของบิล',
        amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
        title: map['title']?.toString() ?? 'สะกิดเตือนบิล',
        message: map['message']?.toString() ?? '',
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
        isRead: map['is_read'] == true,
      );
}

class InAppNotificationService {
  static final InAppNotificationService instance = InAppNotificationService._();
  InAppNotificationService._();

  static const String _storageKey = 'snap2bill_in_app_notifications';
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<List<InAppNotificationItem>> getNotifications({String? currentUserId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        unreadCount.value = 0;
        return [];
      }
      final List<dynamic> list = jsonDecode(raw);
      final items = list
          .map((e) => InAppNotificationItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final filtered = (currentUserId != null && currentUserId.isNotEmpty)
          ? items.where((it) => it.recipientId == currentUserId || it.senderId == currentUserId).toList()
          : items;

      unreadCount.value = filtered.where((e) => !e.isRead).length;
      return filtered;
    } catch (e) {
      debugPrint('Error getting in-app notifications: $e');
      return [];
    }
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
    if (unpaidMembers.isEmpty) return 0;

    final newItems = <InAppNotificationItem>[];
    final now = DateTime.now();

    for (final member in unpaidMembers) {
      final item = InAppNotificationItem(
        id: 'notif_${now.millisecondsSinceEpoch}_${member.id}',
        billId: billId,
        shopName: shopName,
        recipientId: member.id,
        recipientName: member.name,
        senderId: senderId,
        senderName: senderName,
        amount: member.amount,
        title: '📢 สะกิดเตือนค่าอาหาร: $shopName',
        message: 'คุณมียอดค้างชำระ ฿${member.amount.toStringAsFixed(2)} '
            'ของตี้ "$shopName" จาก $senderName รบกวนโอนเงินพร้อมแนบสลิปด้วยเน้อ 🙏',
        createdAt: now,
        isRead: false,
      );
      newItems.add(item);

      // Best effort sync with Supabase notifications table if configured
      try {
        await Supabase.instance.client.from('notifications').insert({
          'bill_id': billId,
          'recipient_id': member.id.startsWith('guest_') ? null : member.id,
          'sender_id': senderId,
          'amount': member.amount,
          'title': item.title,
          'message': item.message,
          'created_at': now.toIso8601String(),
        });
      } catch (_) {
        // Table may not exist yet in Supabase - graceful fallback
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getNotifications();
      final all = [...newItems, ...existing];
      // Keep only last 100 notifications
      final trimmed = all.take(100).map((e) => e.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(trimmed));
      unreadCount.value = all.where((e) => !e.isRead).length;
    } catch (e) {
      debugPrint('Error saving notifications to SharedPreferences: $e');
    }

    return newItems.length;
  }

  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getNotifications();
      for (final it in existing) {
        it.isRead = true;
      }
      final trimmed = existing.map((e) => e.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(trimmed));
      unreadCount.value = 0;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getNotifications();
      for (final it in existing) {
        if (it.id == id) it.isRead = true;
      }
      final trimmed = existing.map((e) => e.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(trimmed));
      unreadCount.value = existing.where((e) => !e.isRead).length;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}

