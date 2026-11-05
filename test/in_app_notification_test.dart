import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap2bill/services/notifications/in_app_notification_service.dart';
import 'package:snap2bill/utils/bill_progress_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  final notificationRows = <Map<String, dynamic>>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://notification-service-test.supabase.co',
      publishableKey: 'notification-service-test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET' &&
            request.url.path.endsWith('/rest/v1/notifications')) {
          return http.Response(
            jsonEncode(notificationRows),
            200,
            request: request,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response('', 201, request: request);
      }),
    );
  });

  setUp(() {
    requests.clear();
    notificationRows
      ..clear()
      ..addAll([
        {
          'id': 'new',
          'bill_id': 'bill-1',
          'recipient_id': 'recipient-1',
          'amount': 50,
          'created_at': '2026-11-05T10:00:00Z',
          'is_read': false,
        },
        {
          'id': 'old',
          'bill_id': 'bill-1',
          'recipient_id': 'recipient-1',
          'amount': 75,
          'created_at': '2026-11-04T10:00:00Z',
          'is_read': true,
        },
      ]);
  });

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

  group('InAppNotificationService', () {
    InAppNotificationService service() => InAppNotificationService.instance;

    test('refreshes notifications and publishes unread count', () async {
      final items = await service().refreshNotifications(
        currentUserId: 'recipient-1',
      );

      expect(items.map((item) => item.id), ['new', 'old']);
      expect(service().notifications.value, hasLength(2));
      expect(service().unreadCount.value, 1);
      expect(
        requests.single.url.queryParameters['recipient_id'],
        'eq.recipient-1',
      );
      expect(requests.single.url.queryParameters['limit'], '100');
    });

    test('sends reminders only to non-guest unpaid recipients', () async {
      final sent = await service().sendBillReminders(
        billId: 'bill-1',
        shopName: 'Cafe',
        senderId: 'owner-1',
        senderName: 'Owner',
        unpaidMembers: const [
          BillParticipantStatus(
            id: 'owner-1',
            name: 'Owner',
            amount: 25,
            isOwner: true,
            isPaid: false,
            isGuest: false,
          ),
          BillParticipantStatus(
            id: 'guest_1',
            name: 'Guest',
            amount: 25,
            isOwner: false,
            isPaid: false,
            isGuest: true,
          ),
          BillParticipantStatus(
            id: 'friend-1',
            name: 'Friend',
            amount: 50,
            isOwner: false,
            isPaid: false,
            isGuest: false,
          ),
        ],
      );

      expect(sent, 1);
      final request = requests.single;
      expect(request.method, 'POST');
      final sentRows = jsonDecode(request.body) as List<dynamic>;
      expect(sentRows, hasLength(1));
      expect(sentRows.single['recipient_id'], 'friend-1');
      expect(sentRows.single['amount'], 50);
    });

    test(
      'markAsRead updates only the selected recipient notification',
      () async {
        await service().markAsRead('new', currentUserId: 'recipient-1');

        expect(requests.first.method, 'PATCH');
        expect(requests.first.url.queryParameters['id'], 'eq.new');
        expect(
          requests.first.url.queryParameters['recipient_id'],
          'eq.recipient-1',
        );
        expect(requests.last.method, 'GET');
        expect(service().unreadCount.value, 1);
      },
    );

    test(
      'markAllAsRead updates the recipient and refreshes the list',
      () async {
        await service().markAllAsRead(currentUserId: 'recipient-1');

        expect(requests.first.method, 'PATCH');
        expect(
          requests.first.url.queryParameters['recipient_id'],
          'eq.recipient-1',
        );
        expect(requests.first.url.queryParameters['is_read'], 'eq.false');
        expect(requests.last.method, 'GET');
      },
    );
  });
}
