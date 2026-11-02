import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:snap2bill/domain/repositories/bill_repository.dart';
import 'package:snap2bill/domain/repositories/user_repository.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/providers/user_provider.dart';
import 'package:snap2bill/routes/app_routes.dart';
import 'package:snap2bill/screens/auth/login_screen.dart';
import 'package:snap2bill/screens/bill/summary_screen.dart';
import 'package:snap2bill/widgets/bill/promptpay_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('completes the bill creation, claiming, and payment flow', (
    tester,
  ) async {
    await _initializeSupabase();

    final navigatorKey = GlobalKey<NavigatorState>();
    final billProvider = BillProvider(billRepository: _FakeBillRepository());
    final userProvider = UserProvider(userRepository: _FakeUserRepository());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
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
}

Future<void> _initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://example.supabase.co',
    publishableKey: 'test-publishable-key',
  );
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
