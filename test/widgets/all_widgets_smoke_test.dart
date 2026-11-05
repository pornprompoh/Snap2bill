import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:snap2bill/utils/bill_progress_helper.dart';
import 'package:snap2bill/widgets/bill/bill_card.dart';
import 'package:snap2bill/widgets/bill/claim_item_card.dart';
import 'package:snap2bill/widgets/bill/receipt_image.dart';
import 'package:snap2bill/widgets/bill/shareable_receipt_card.dart';
import 'package:snap2bill/widgets/bill/shareable_receipt_preview_dialog.dart';
import 'package:snap2bill/widgets/common/cached_avatar.dart';
import 'package:snap2bill/widgets/friends/friend_item.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _summary = BillProgressSummary(
  totalAmount: 120,
  shopName: 'Smoke Cafe',
  ownerId: 'owner-1',
  totalMembers: 2,
  totalPayingCount: 1,
  paidCount: 0,
  unpaidCount: 1,
  percentage: 0,
  averagePerPerson: 120,
  equalPerPerson: 120,
  isEqualSplit: true,
  isSettled: false,
  unpaidMembers: [
    BillParticipantStatus(
      id: 'friend-1',
      name: 'Waiting friend',
      amount: 120,
      isOwner: false,
      isPaid: false,
      isGuest: false,
    ),
  ],
  allMembers: [
    BillParticipantStatus(
      id: 'owner-1',
      name: 'Owner',
      amount: 0,
      isOwner: true,
      isPaid: true,
      isGuest: false,
    ),
    BillParticipantStatus(
      id: 'friend-1',
      name: 'Waiting friend',
      amount: 120,
      isOwner: false,
      isPaid: false,
      isGuest: false,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late OfflineService offlineService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    try {
      await Supabase.initialize(
        url: 'https://all-widgets-smoke-test.supabase.co',
        publishableKey: 'all-widgets-smoke-test-key',
        httpClient: MockClient(
          (request) async => http.Response('[]', 200, request: request),
        ),
      );
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    offlineService = OfflineService()
      ..reportNetworkFailure(const SocketException('offline test'));
  });

  tearDown(() async {
    await offlineService.disposeService();
  });

  testWidgets('BillCard renders pending, settled and empty-total variants', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                BillCard(
                  shopName: 'Pending Cafe',
                  totalAmount: 240,
                  dateText: '2026-11-06',
                  isPendingSync: true,
                  memberCount: 3,
                  unpaidCount: 2,
                  paidCount: 0,
                  totalPayingCount: 2,
                  isEqualSplit: true,
                  averagePerPerson: 120,
                ),
                BillCard(
                  shopName: 'Settled Cafe',
                  totalAmount: 100,
                  status: 'completed',
                  unpaidCount: 0,
                  totalPayingCount: 1,
                ),
                BillCard(shopName: 'No total', totalAmount: 0),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Pending Cafe'), findsOneWidget);
    expect(find.text('รอบันทึกเมื่อออนไลน์'), findsOneWidget);
    expect(find.text('ชำระเสร็จสิ้น'), findsOneWidget);
    expect(find.text('เก็บเงินแล้ว 100%'), findsNWidgets(2));
    expect(find.text('ยังไม่มีข้อมูลยอดบิล'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('CachedAvatar renders its offline placeholder without requests', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<OfflineService>.value(
        value: offlineService,
        child: const MaterialApp(
          home: Scaffold(
            body: CachedAvatar(
              imageUrl: 'https://images.example.test/avatar.png',
              size: 40,
              placeholder: Text('offline avatar'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('offline avatar'), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('ReceiptImage renders the offline unavailable state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<OfflineService>.value(
        value: offlineService,
        child: MaterialApp(
          home: Scaffold(
            body: ReceiptImage(
              imageUrl: 'https://storage.example.test/receipt.png',
              errorBuilder: (_, error) => Text(error.runtimeType.toString()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('StateError'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('ShareableReceiptPreviewDialog renders summary actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.7)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: Dialog(
              child: ShareableReceiptPreviewDialog(
                bill: {
                  'id': 'bill-1',
                  'created_at': '2026-11-06T00:00:00Z',
                  'shop_name': 'Smoke Cafe',
                },
                summary: _summary,
                hostPromptPay: '0812345678',
                hostPromptPayType: 'phone',
                hostName: 'Owner',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ตัวอย่างบิลสรุปสำเร็จรูป'), findsOneWidget);
    expect(find.text('Smoke Cafe'), findsOneWidget);
    expect(find.text('คัดลอกข้อความ'), findsOneWidget);
    final copyButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'คัดลอกข้อความ'),
    );
    expect(copyButton.onPressed, isNotNull);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets(
    'ShareableReceiptPreviewDialog reads PromptPay from receipt data',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(0.7)),
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: Dialog(
                child: ShareableReceiptPreviewDialog(
                  bill: {
                    'id': 'bill-2',
                    'shop_name': 'Receipt PromptPay Cafe',
                    'receipt_json': {
                      'promptpay_number': '0812345678',
                      'promptpay_type': 'phone',
                    },
                  },
                  summary: _summary,
                  hostName: 'Owner',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Thai QR Payment (พร้อมเพย์)'), findsOneWidget);

      await tester.pumpWidget(const Placeholder());
    },
  );

  testWidgets('ShareableReceiptPreviewDialog validates PromptPay setup input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.7)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: Dialog(
              child: ShareableReceiptPreviewDialog(
                bill: const {'id': '', 'shop_name': 'Setup Cafe'},
                summary: _summary,
                hostName: 'Owner',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('ตั้งค่า PromptPay'));
    await tester.tap(find.text('ตั้งค่า PromptPay'));
    await tester.pumpAndSettle();
    expect(find.text('เบอร์โทรศัพท์ (10 หลัก)'), findsOneWidget);

    await tester.tap(find.text('บันทึก'));
    await tester.pump();
    expect(
      find.text('กรุณากรอกเบอร์มือถือ 10 หลัก (ขึ้นต้นด้วย 0)'),
      findsOneWidget,
    );

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('FriendItem renders host, selection, and custom trailing state', (
    tester,
  ) async {
    var changed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FriendItem(
            name: 'Room host',
            isHost: true,
            amountText: '฿120',
            isSelected: true,
            trailing: const Icon(Icons.check),
            onSelectionChanged: (value) => changed = value ?? false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Room host'), findsOneWidget);
    expect(find.text('฿120'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    await tester.tap(find.text('Room host'));
    expect(changed, isFalse);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('FriendAvatar handles host, current user, and empty initials', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              FriendAvatar(name: 'Mina Wong', isHost: true),
              FriendAvatar(name: 'Current user', isCurrentUser: true),
              FriendAvatar(name: '   '),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('MW'), findsOneWidget);
    expect(find.text('คุณ'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    expect(find.byTooltip('Mina Wong • หัวหน้าห้อง'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('ClaimItemCard supports adding and sharing an alcoholic item', (
    tester,
  ) async {
    var quantityChange = 0;
    var shared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClaimItemCard(
            itemName: 'เบียร์',
            itemQuantity: 2,
            unitPrice: 80,
            claimingUserId: 'user-1',
            itemClaims: const {},
            sharedUsers: const {},
            userNames: const {},
            onChangeQuantity: (delta) => quantityChange = delta,
            onToggleShared: () => shared = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('คนไม่ดื่ม ไม่ต้องจ่าย! ปล่อยไว้ที่ 0 ได้เลย'),
      findsOneWidget,
    );
    expect(find.text('เหลือ 2 จาน'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded));
    expect(quantityChange, 1);
    await tester.tap(find.text('กดกินด้วยกัน (หารเท่า)'));
    expect(shared, isTrue);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('ClaimItemCard shows fully claimed and shared-user details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClaimItemCard(
            itemName: 'Shared plate',
            itemQuantity: 2,
            unitPrice: 60,
            claimingUserId: 'user-1',
            itemClaims: const {'user-1': 1, 'user-2': 1},
            sharedUsers: const {'user-1', 'user-2'},
            userNames: const {'user-1': 'Mina', 'user-2': 'Noah'},
            onChangeQuantity: (_) {},
            onToggleShared: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('✓ เคลมครบแล้ว ✨'), findsOneWidget);
    expect(find.textContaining('Mina'), findsOneWidget);
    expect(find.textContaining('Noah'), findsOneWidget);
    expect(find.textContaining('หารร่วมกัน 2 คน'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('ShareableReceiptCard shows owner payment setup guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShareableReceiptCard(
              bill: const {'id': 'bill-12345678', 'created_at': '2026-11-06'},
              summary: _summary,
              hostBankAccount: '123-456',
              hostBankName: 'Test Bank',
              hostName: 'Owner',
              onConfigurePromptPay: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('#BILL-123'), findsOneWidget);
    expect(find.text('เจ้าของบิลยังไม่ได้ตั้งค่าพร้อมเพย์'), findsOneWidget);
    expect(find.text('ตั้งค่า PromptPay'), findsOneWidget);
    expect(find.textContaining('โอนเข้าบัญชี'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('ShareableReceiptCard renders a payment QR for a valid number', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShareableReceiptCard(
              bill: const {'id': 'bill-2'},
              summary: _summary,
              hostPromptPay: '0812345678',
              hostPromptPayType: 'phone',
              hostName: 'Owner',
              specificMemberAmount: 75,
              specificMemberName: 'Waiting friend',
              isCurrentViewerOwner: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining('พร้อมเพย์:'), findsOneWidget);
    expect(find.textContaining('75'), findsWidgets);
    expect(find.text('เจ้าของบิลยังไม่ได้ตั้งค่าพร้อมเพย์'), findsNothing);

    await tester.pumpWidget(const Placeholder());
  });
}
