import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/services/notifications/in_app_notification_service.dart';

void main() {
  group('InAppNotificationItem', () {
    test('parses persisted notification fields', () {
      final item = InAppNotificationItem.fromMap({
        'id': 'notification-id',
        'bill_id': 'bill-id',
        'shop_name': 'ร้านอาหาร',
        'recipient_id': 'recipient-id',
        'recipient_name': 'เพื่อน',
        'sender_id': 'sender-id',
        'sender_name': 'เจ้าของบิล',
        'amount': '125.50',
        'title': 'แจ้งเตือน',
        'message': 'กรุณาชำระเงิน',
        'created_at': '2026-11-04T10:00:00.000Z',
        'is_read': true,
      });

      expect(item.id, 'notification-id');
      expect(item.billId, 'bill-id');
      expect(item.shopName, 'ร้านอาหาร');
      expect(item.recipientId, 'recipient-id');
      expect(item.amount, 125.5);
      expect(item.isRead, isTrue);
      expect(item.createdAt, DateTime.utc(2026, 11, 4, 10));
    });

    test('uses safe defaults for missing optional data', () {
      final item = InAppNotificationItem.fromMap({});

      expect(item.id, isEmpty);
      expect(item.shopName, 'ไม่ระบุชื่อร้าน');
      expect(item.recipientName, 'เพื่อน');
      expect(item.amount, 0);
      expect(item.isRead, isFalse);
      expect(
        item.createdAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    });
  });
}
