import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap2bill/services/notifications/in_app_notification_service.dart';
import 'package:snap2bill/widgets/bill/notification_center_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

var _responseStatus = 200;
var _responseRows = <Map<String, dynamic>>[];
final _requests = <http.Request>[];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://notification-dialog-test.supabase.co',
        publishableKey: 'notification-dialog-test-key',
        httpClient: MockClient((request) async {
          _requests.add(request);
          if (request.url.path.endsWith('/rest/v1/notifications')) {
            return http.Response(
              jsonEncode(
                _responseStatus == 200
                    ? _responseRows
                    : {'message': 'service unavailable', 'code': '500'},
              ),
              _responseStatus,
              request: request,
              headers: const {'content-type': 'application/json'},
            );
          }
          return http.Response('', 204, request: request);
        }),
      );
    } catch (_) {}
  });

  setUp(() {
    _responseStatus = 200;
    _responseRows = [];
    _requests.clear();
  });

  testWidgets('renders empty state after notifications finish loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NotificationCenterDialog(currentUserId: 'user-1')),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('ศูนย์แจ้งเตือน'), findsOneWidget);
    expect(find.text('ยังไม่มีการแจ้งเตือน'), findsOneWidget);
    expect(find.text('อ่านทั้งหมดแล้ว'), findsOneWidget);
  });

  testWidgets('shows an error state when notification loading fails', (
    tester,
  ) async {
    _responseStatus = 500;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NotificationCenterDialog(currentUserId: 'user-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('โหลดการแจ้งเตือนไม่สำเร็จ กรุณาลองอีกครั้ง'),
      findsOneWidget,
    );
  });

  testWidgets('shows notification rows with unread and read states', (
    tester,
  ) async {
    _responseRows = [
      {
        'id': 'notice-1',
        'bill_id': 'bill-1',
        'recipient_id': 'user-1',
        'shop_name': 'Cafe',
        'sender_name': 'Bill owner',
        'message': 'Please pay',
        'created_at': '2026-11-05T10:00:00Z',
        'amount': 50,
        'is_read': false,
      },
      {
        'id': 'notice-2',
        'bill_id': 'bill-2',
        'recipient_id': 'user-1',
        'shop_name': 'Tea shop',
        'sender_name': 'Friend',
        'message': 'Payment update',
        'created_at': '2026-11-04T10:00:00Z',
        'amount': 20,
        'is_read': true,
      },
    ];
    final loaded = await InAppNotificationService.instance.refreshNotifications(
      currentUserId: 'user-1',
    );
    expect(loaded, hasLength(2));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NotificationCenterDialog(currentUserId: 'user-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Cafe'), findsOneWidget);
    expect(find.textContaining('Tea shop'), findsOneWidget);
    expect(find.text('Please pay'), findsOneWidget);
    expect(find.text('Payment update'), findsOneWidget);
  });

  testWidgets('marks all notifications as read from the dialog action', (
    tester,
  ) async {
    _responseRows = [
      {
        'id': 'notice-1',
        'bill_id': 'bill-1',
        'recipient_id': 'user-1',
        'shop_name': 'Cafe',
        'message': 'Please pay',
        'created_at': '2026-11-05T10:00:00Z',
        'amount': 50,
        'is_read': false,
      },
    ];
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NotificationCenterDialog(currentUserId: 'user-1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('อ่านทั้งหมดแล้ว'));
    await tester.pumpAndSettle();

    expect(
      _requests.any(
        (request) =>
            request.method == 'PATCH' &&
            request.url.path.endsWith('/rest/v1/notifications'),
      ),
      isTrue,
    );
  });
}
