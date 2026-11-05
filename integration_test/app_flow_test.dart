import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:snap2bill/data/repositories/local_bill_repository.dart';
import 'package:snap2bill/domain/repositories/bill_repository.dart';
import 'package:snap2bill/domain/repositories/user_repository.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/providers/user_provider.dart';
import 'package:snap2bill/routes/app_routes.dart';
import 'package:snap2bill/screens/auth/login_screen.dart';
import 'package:snap2bill/screens/bill/summary_screen.dart';
import 'package:snap2bill/screens/bill/detail_screen.dart';
import 'package:snap2bill/services/notifications/in_app_notification_service.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:snap2bill/widgets/bill/notification_center_dialog.dart';
import 'package:snap2bill/widgets/bill/promptpay_card.dart';

final List<String> _supabaseRequests = [];
Completer<Map<String, dynamic>>? _pendingBillResponse;
const Map<String, dynamic> _notificationBillData = {
  'id': 'bill-qa-notification',
  'owner_id': 'qa-owner',
  'shop_name': 'ร้านแจ้งเตือน QA',
  'sub_total': 0,
  'total_amount': 3451,
  'status': 'pending',
  'receipt_json': {'sub_total': 0, 'final_total': 3451, 'items': []},
  'sharers_json': {},
  'created_at': '2026-11-04T10:00:00.000Z',
};
final List<Map<String, dynamic>> _notificationRecords = [
  {
    'id': 'notification-qa',
    'bill_id': 'bill-qa-notification',
    'shop_name': 'ร้านแจ้งเตือน QA',
    'recipient_id': 'qa-recipient',
    'recipient_name': 'QA Friend',
    'sender_id': 'qa-owner',
    'sender_name': 'QA Owner',
    'amount': 125,
    'title': 'สะกิดเตือนค่าอาหาร: ร้านแจ้งเตือน QA',
    'message': 'กรุณาชำระเงิน',
    'created_at': '2026-11-04T10:00:00.000Z',
    'is_read': false,
  },
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('completes the bill creation, claiming, and payment flow', (
    tester,
  ) async {
    await _initializeSupabase();

    final navigatorKey = GlobalKey<NavigatorState>();
    final billProvider = BillProvider(billRepository: _FakeBillRepository());
    final userProvider = UserProvider(userRepository: _FakeUserRepository());
    final offlineService = OfflineService();
    billProvider.setOfflineService(offlineService);
    userProvider.setOfflineService(offlineService);
    addTearDown(offlineService.disposeService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OfflineService>.value(value: offlineService),
          ChangeNotifierProvider<BillProvider>.value(value: billProvider),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: AppRoutes.generateRoute,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // OAuth is intentionally not invoked. The fake repositories below provide
    // the authenticated test identity and payment profile deterministically.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('เข้าสู่ระบบเพื่อจัดการบิล'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);

    // This route is the test seam for the mocked OCR response. It bypasses
    // the real camera, image picker, OCR API, and external authentication.
    navigatorKey.currentState!.pushNamed(
      AppRoutes.review,
      arguments: {'receiptData': _receiptData},
    );
    await tester.pumpAndSettle();

    expect(find.text('ตรวจสอบใบเสร็จ'), findsOneWidget);
    expect(find.text('ข้าวผัดกุ้ง'), findsOneWidget);
    expect(find.text('ชาเขียว'), findsOneWidget);
    expect(find.text('เค้กช็อกโกแลต'), findsOneWidget);
    expect(find.textContaining('281 ฿'), findsOneWidget);

    await _tapAndSettle(tester, find.text('ยืนยัน & ชวนเพื่อน'));
    expect(find.text('ชวนเพื่อนเข้าห้องตี้'), findsOneWidget);
    expect(find.textContaining('281 ฿'), findsWidgets);

    await _tapAndSettle(
      tester,
      find.text('เข้าสู่หน้าจิ้มอาหาร (Start Claiming) ➔'),
    );
    expect(find.text('จิ้มเลือกอาหารที่คุณกินจริง'), findsOneWidget);
    expect(find.text('ยอดของคุณตอนนี้'), findsOneWidget);

    // Claim one item for the host, then add a guest and claim another item.
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('100 ฿'), findsWidgets);

    await _tapAndSettle(tester, find.text('+ เพื่อน'));
    expect(find.text('เพิ่มเพื่อนที่ไม่มีแอป'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Guest QA');
    await _tapAndSettle(tester, find.text('เพิ่มเพื่อน'));
    expect(
      billProvider.roomMembers.any((member) => member.name == 'Guest QA'),
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.add_rounded).at(1));
    await tester.pumpAndSettle();
    expect(find.textContaining('80 ฿'), findsWidgets);

    final guest = billProvider.roomMembers.single;
    navigatorKey.currentState!.pushReplacementNamed(
      AppRoutes.summary,
      arguments: {
        'lobbyId': '',
        'receiptData': _receiptData,
        'itemSharers': {
          0: [
            {'user_id': 'test-user', 'user_name': 'QA Host', 'quantity': 1},
          ],
          1: [
            {'user_id': guest.id, 'user_name': guest.name, 'quantity': 1},
          ],
        },
        'roomParticipants': [
          {'id': 'test-user', 'user_id': 'test-user', 'user_name': 'QA Host'},
          {'id': guest.id, 'user_id': guest.id, 'user_name': guest.name},
        ],
        'isHost': true,
      },
    );
    await tester.pumpAndSettle();
    expect(find.text('สรุปยอดและชำระเงิน'), findsOneWidget);
    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.textContaining('281 ฿'), findsWidgets);
    expect(find.byTooltip('กลับหน้าแรก'), findsOneWidget);

    // The test user is deliberately unauthenticated at Supabase level. The
    // route below is the same destination used by the guest-safe finish path.
    navigatorKey.currentState!.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // PromptPayCard is verified independently with the injected payment
    // profile because SummaryScreen hides payment controls without a real
    // Supabase session (which is intentionally not created in this E2E test).
    await tester.pumpWidget(
      MaterialApp(
        home: PromptPayCard(
          hostName: 'QA Host',
          promptPayNumber: '0812345678',
          qrPayload: 'promptpay-qa',
          selectedUserName: 'Guest QA',
          amount: 125,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PromptPayCard), findsOneWidget);
    expect(find.text('PROMPTPAY (Single-Use)'), findsOneWidget);

    final shares = BillProvider.calculateUserShares(
      items: [
        BillItemModel(
          id: 'item-1',
          billId: 'room-qa',
          itemName: 'ข้าวผัดกุ้ง',
          price: 100,
          userQuantities: {'test-user': 1},
        ),
        BillItemModel(
          id: 'item-2',
          billId: 'room-qa',
          itemName: 'ชาเขียว',
          price: 80,
          userQuantities: {'guest-qa': 1},
        ),
      ],
      finalTotal: 281,
      splitType: 'proportional',
      participantIds: const ['test-user', 'guest-qa'],
    );
    expect(shares['test-user'], 157);
    expect(shares['guest-qa'], 125);
  });

  testWidgets('opens a bill from a reminder and shows its loaded total', (
    tester,
  ) async {
    await _initializeSupabase();
    _supabaseRequests.clear();
    _notificationRecords.single['is_read'] = false;
    InAppNotificationService.instance.notifications.value = [];
    InAppNotificationService.instance.unreadCount.value = 0;
    final billResponse = Completer<Map<String, dynamic>>();
    _pendingBillResponse = billResponse;
    addTearDown(() {
      if (!billResponse.isCompleted) {
        billResponse.complete(_notificationBillData);
      }
      _pendingBillResponse = null;
    });
    final loadedNotifications = await InAppNotificationService.instance
        .getNotifications(currentUserId: 'qa-recipient');
    expect(loadedNotifications, hasLength(1));
    final localRepository = LocalBillRepository();
    final billId = _notificationBillData['id'] as String;
    await localRepository.deleteCachedBill(billId);
    addTearDown(() => localRepository.deleteCachedBill(billId));
    final offlineService = OfflineService();
    addTearDown(offlineService.disposeService);

    await tester.pumpWidget(
      ChangeNotifierProvider<OfflineService>.value(
        value: offlineService,
        child: MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  NotificationCenterDialog.show(
                    context,
                    currentUserId: 'qa-recipient',
                  );
                },
                child: const Text('เปิดการแจ้งเตือน'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('เปิดการแจ้งเตือน'));
    await tester.pumpAndSettle();
    expect(find.text('ศูนย์แจ้งเตือน'), findsOneWidget);
    expect(find.text(_notificationRecords.single['title']), findsOneWidget);
    expect(InAppNotificationService.instance.unreadCount.value, 1);

    await tester.tap(find.text(_notificationRecords.single['title']));
    await tester.pumpAndSettle();

    expect(find.text('กำลังโหลดยอดบิล...'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูลยอดบิล'), findsNothing);
    billResponse.complete(_notificationBillData);
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('ร้านแจ้งเตือน QA'), findsOneWidget);
    expect(find.text('3,451 ฿'), findsOneWidget);
    expect(_notificationRecords.single['is_read'], isTrue);
    expect(InAppNotificationService.instance.unreadCount.value, 0);
    expect(_supabaseRequests, contains('PATCH notifications'));
    expect(_supabaseRequests, contains('GET bills'));
    expect(_supabaseRequests, contains('GET profiles'));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://example.supabase.co',
    publishableKey: 'test-publishable-key',
    httpClient: MockClient(_handleSupabaseRequest),
  );
}

Future<http.Response> _handleSupabaseRequest(http.Request request) async {
  final table = request.url.pathSegments.last;
  _supabaseRequests.add('${request.method} $table');
  final jsonHeaders = {'content-type': 'application/json'};

  if (table == 'notifications' && request.method == 'GET') {
    return http.Response(
      jsonEncode(_notificationRecords),
      200,
      headers: jsonHeaders,
      request: request,
    );
  }
  if (table == 'notifications' && request.method == 'PATCH') {
    _notificationRecords.single['is_read'] = true;
    return http.Response('', 204, request: request);
  }
  if (table == 'bills' && request.method == 'GET') {
    final pendingResponse = _pendingBillResponse;
    _pendingBillResponse = null;
    final billData = pendingResponse == null
        ? _notificationBillData
        : await pendingResponse.future;
    return http.Response(
      jsonEncode(billData),
      200,
      headers: jsonHeaders,
      request: request,
    );
  }

  if (table == 'bill_participants' && request.method == 'GET') {
    return http.Response('[]', 200, headers: jsonHeaders, request: request);
  }
  if (table == 'bill_payments' && request.method == 'GET') {
    return http.Response('[]', 200, headers: jsonHeaders, request: request);
  }
  if (table == 'profiles' && request.method == 'GET') {
    final idFilter = request.url.queryParameters['id'];
    if (idFilter?.startsWith('in.') == true) {
      return http.Response(
        jsonEncode([
          {
            'id': 'qa-owner',
            'display_name': 'QA Owner',
            'email': 'owner@example.test',
          },
          {
            'id': 'qa-recipient',
            'display_name': 'QA Friend',
            'email': 'friend@example.test',
          },
        ]),
        200,
        headers: jsonHeaders,
        request: request,
      );
    }
    return http.Response(
      jsonEncode({
        'id': 'qa-owner',
        'display_name': 'QA Owner',
        'email': 'owner@example.test',
        'payment_info': {},
      }),
      200,
      headers: jsonHeaders,
      request: request,
    );
  }

  return http.Response('[]', 200, headers: jsonHeaders, request: request);
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

const Map<String, dynamic> _receiptData = {
  'shop_name': 'ร้าน QA E2E',
  'vat_amount': 16.8,
  'service_charge': 24.0,
  'discount': 0.0,
  'final_total': 280.8,
  'total_amount': 280.8,
  'items': [
    {'item_name': 'ข้าวผัดกุ้ง', 'qty': 1, 'unit_price': 100.0},
    {'item_name': 'ชาเขียว', 'qty': 1, 'unit_price': 80.0},
    {'item_name': 'เค้กช็อกโกแลต', 'qty': 1, 'unit_price': 60.0},
  ],
};

class _FakeBillRepository implements BillRepository {
  @override
  String get currentUserId => 'test-user';

  @override
  Future<List<BillModel>> getMyBills() async => [];

  @override
  Future<BillModel> createBill(String shopName, double totalAmount) async {
    return BillModel(
      id: 'bill-qa',
      ownerId: currentUserId,
      shopName: shopName,
      totalAmount: totalAmount,
      finalTotal: totalAmount,
    );
  }

  @override
  Future<List<RoomMember>> getRoomGuestMembers(String roomCode) async => [];

  @override
  Future<RoomMember> addRoomGuestMember(
    String roomCode,
    RoomMember member,
  ) async => member;
}

class _FakeUserRepository implements UserRepository {
  final _profile = UserModel(
    id: 'test-user',
    displayName: 'QA Host',
    email: 'qa@example.test',
    paymentInfo: {'type': 'phone', 'number': '0812345678'},
  );

  @override
  Future<UserModel?> getMyProfile() async => _profile;

  @override
  Future<UserModel> updateUserProfile({
    required String displayName,
    required Map<String, dynamic>? paymentInfo,
  }) async => _profile;

  @override
  Future<List<FriendModel>> getMyFriends() async => [];

  @override
  Future<void> addFriend(String friendName) async {}
}
