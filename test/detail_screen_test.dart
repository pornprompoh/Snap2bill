import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/screens/bill/detail_screen.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late OfflineService offlineService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    try {
      await Supabase.initialize(
        url: 'https://detail-screen-test.supabase.co',
        publishableKey: 'detail-screen-test-key',
      );
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    offlineService = OfflineService()
      ..reportNetworkFailure(const SocketException('network unavailable'));
  });

  tearDown(() async {
    await offlineService.disposeService();
  });

  testWidgets('renders cached bill totals, item claims, and member statuses', (
    tester,
  ) async {
    await _pumpDetail(tester, offlineService, {
      'id': 'cached-bill',
      'owner_id': 'owner-1',
      'shop_name': 'Offline Cafe',
      'created_at': '2026-11-05T10:00:00Z',
      'status': 'pending',
      'sub_total': 150,
      'receipt_json': {
        'sub_total': 150,
        'service_charge': 10,
        'vat_amount': 5,
        'discount': 15,
        'total_amount': 150,
        'final_total': 150,
        'items': [
          {'item_name': 'Tea', 'qty': 2, 'unit_price': 50},
          {
            'item_name': 'Cake',
            'qty': 1,
            'unit_price': 50,
            'claims': {'friend-1': 1},
            'shared_users': ['friend-1'],
          },
        ],
      },
      'sharers_json': {
        '0': [
          {
            'user_id': 'friend-1',
            'user_name': 'Mina',
            'quantity': 1,
            'is_shared': true,
          },
        ],
      },
      'bill_participants': [
        {'profile_id': 'owner-1', 'status': 'paid', 'amount_owed': 0},
        {'profile_id': 'friend-1', 'status': 'pending', 'amount_owed': 100},
        {'profile_id': 'guest_local', 'status': 'pending', 'amount_owed': 50},
      ],
      'bill_payments': [
        {
          'profile_id': 'friend-1',
          'status': 'reviewing',
          'slip_data': 'payment-slip',
        },
      ],
      'profiles': {
        'owner-1': {
          'display_name': 'Owner',
          'payment_info': {
            'type': 'phone',
            'number': '0812345678',
            'bank_account_number': '123456',
          },
        },
        'friend-1': {'display_name': 'Mina', 'avatar_url': null},
      },
    });

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Offline Cafe'), findsOneWidget);
    expect(find.text('150 ฿'), findsWidgets);
    expect(find.text('Tea'), findsOneWidget);
    expect(find.text('Cake'), findsOneWidget);
    expect(find.textContaining('Mina'), findsWidgets);
    expect(find.textContaining('Service Charge'), findsOneWidget);
    expect(find.textContaining('VAT'), findsWidgets);
    expect(find.textContaining('ส่วนลด'), findsOneWidget);
  });

  testWidgets('renders empty bill details without a bill id', (tester) async {
    await _pumpDetail(tester, offlineService, {
      'shop_name': 'Empty bill',
      'receipt_json': {'items': []},
    });

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Empty bill'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูลยอดบิล'), findsOneWidget);
    expect(find.text('รายการที่สั่ง (รายละเอียด)'), findsOneWidget);
  });

  testWidgets(
    'parses legacy JSON claims, payment states, and missing receipt image',
    (tester) async {
      await _pumpDetail(tester, offlineService, {
        'owner_id': 'owner-1',
        'shop_name': 'Legacy Cafe',
        'image_url': 'not-a-valid-image-url',
        'receipt_json': jsonEncode({
          'owner_id': 'owner-1',
          'split_type': 'equal',
          'final_total': 90,
          'paid_statuses': {'guest_1': 'paid'},
          'payment_slips': {'friend-1': 'slip-token'},
          'items': [
            {
              'item_name': 'Shared bowl',
              'quantity': 2,
              'price': 30,
              'claims': {'guest_1': 1},
              'shared_users': ['guest_1', 'friend-1'],
            },
            {'name': 'Unnamed item', 'qty': 'invalid', 'unit_price': 'bad'},
          ],
        }),
        'sharers_json': '{}',
        'bill_participants': [
          {'profile_id': 'friend-1', 'status': 'pending_verification'},
          {'profile_id': 'guest_1', 'status': 'paid'},
        ],
        'profiles': {
          'friend-1': {'display_name': 'Friend One'},
        },
      });

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Legacy Cafe'), findsOneWidget);
      expect(find.text('Shared bowl'), findsOneWidget);
      expect(find.text('ไม่มีชื่อ'), findsOneWidget);
      expect(find.text('ไม่พบรูปใบเสร็จของบิลนี้'), findsOneWidget);
    },
  );

  testWidgets('opens shareable receipt preview from cached bill details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDetail(tester, offlineService, {
      'shop_name': 'Share preview cafe',
      'owner_id': 'owner-1',
      'created_at': '2026-11-06T00:00:00Z',
      'receipt_json': {
        'total_amount': 120,
        'items': [
          {'item_name': 'Tea', 'qty': 1, 'unit_price': 120},
        ],
      },
      'bill_participants': [
        {'profile_id': 'friend-1', 'status': 'pending', 'amount_owed': 120},
      ],
      'profiles': {
        'friend-1': {'display_name': 'Friend One'},
      },
    });

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final shareButton = find.byTooltip('แชร์บิลสรุปสำเร็จรูป');
    expect(shareButton, findsOneWidget);

    await tester.tap(shareButton);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ตัวอย่างบิลสรุปสำเร็จรูป'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
  });
}

Future<void> _pumpDetail(
  WidgetTester tester,
  OfflineService offlineService,
  Map<String, dynamic> bill,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<OfflineService>.value(
      value: offlineService,
      child: MaterialApp(home: DetailScreen(billData: bill)),
    ),
  );
  await tester.pump();
}
