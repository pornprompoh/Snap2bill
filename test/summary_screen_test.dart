import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/providers/user_provider.dart';
import 'package:snap2bill/screens/bill/summary_screen.dart';
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
        url: 'https://summary-screen-test.supabase.co',
        publishableKey: 'summary-screen-test-key',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/v1/user')) {
            return http.Response(
              jsonEncode({
                'id': 'test-user',
                'aud': 'authenticated',
                'role': 'authenticated',
                'email': 'host@example.test',
              }),
              200,
              request: request,
              headers: const {'content-type': 'application/json'},
            );
          }
          return http.Response('', 204, request: request);
        }),
      );
    } catch (_) {}
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none'})));
    final payload = base64Url.encode(
      utf8.encode(
        jsonEncode({
          'sub': 'test-user',
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': 'host@example.test',
          'iat': now,
          'exp': now + 3600,
        }),
      ),
    );
    await Supabase.instance.client.auth.setSession(
      'test-refresh-token',
      accessToken: '$header.$payload.${base64Url.encode(utf8.encode('sig'))}',
    );
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

  Widget buildScreen({required String splitType}) {
    final billProvider = BillProvider()..setSplitType(splitType);
    final userProvider = _UserProviderWithProfile()
      ..setOfflineService(offlineService);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BillProvider>.value(value: billProvider),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<OfflineService>.value(value: offlineService),
      ],
      child: const MaterialApp(
        home: SummaryScreen(
          lobbyId: '',
          receiptData: {
            'shop_name': 'Cafe Test',
            'owner_id': 'test-user',
            'sub_total': 200,
            'vat_amount': 14,
            'service_charge': 10,
            'final_total': 224,
            'items': [
              {'item_name': 'Tea', 'qty': 2, 'unit_price': 50},
              {'item_name': 'Cake', 'qty': 1, 'unit_price': 100},
            ],
          },
          itemSharers: {
            0: [
              {
                'user_id': 'guest_one',
                'user_name': 'Guest One',
                'quantity': 1,
                'payment_status': 'paid',
              },
              {'user_id': 'friend_2', 'user_name': 'Friend Two', 'quantity': 1},
            ],
            1: [
              {'user_id': 'friend_2', 'user_name': 'Friend Two', 'quantity': 1},
            ],
          },
          roomParticipants: [
            {'id': 'guest_one', 'name': 'Guest One', 'is_guest': true},
            {'id': 'friend_2', 'name': 'Friend Two'},
          ],
        ),
      ),
    );
  }

  testWidgets(
    'renders bill summary, participant shares, and payment progress',
    (tester) async {
      expect(Supabase.instance.client.auth.currentUser?.id, 'test-user');
      await tester.pumpWidget(buildScreen(splitType: 'proportional'));
      await tester.pumpAndSettle();

      expect(find.text('สรุปยอดและชำระเงิน'), findsOneWidget);
      expect(find.text('Cafe Test'), findsOneWidget);
      expect(find.text('มียอดรวมทั้งโต๊ะ'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('จ่ายแล้ว'), findsOneWidget);
      expect(find.text('รอจ่าย'), findsOneWidget);
      expect(find.text('ชำระแล้ว 1/2 คน'), findsOneWidget);
      expect(find.byTooltip('ปิดบิลเสร็จสิ้น'), findsOneWidget);

      await tester.ensureVisible(find.text('รอจ่าย'));
      await tester.tap(find.text('รอจ่าย'));
      await tester.pump();
      expect(find.text('ชำระแล้ว 2/2 คน'), findsOneWidget);
    },
  );

  testWidgets('renders empty bill data without participant entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BillProvider>.value(value: BillProvider()),
          ChangeNotifierProvider<UserProvider>.value(
            value: _UserProviderWithProfile()
              ..setOfflineService(offlineService),
          ),
          ChangeNotifierProvider<OfflineService>.value(value: offlineService),
        ],
        child: const MaterialApp(
          home: SummaryScreen(
            lobbyId: '',
            receiptData: {
              'shop_name': 'Empty bill',
              'owner_id': 'test-user',
              'items': [],
            },
            itemSharers: {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Empty bill'), findsOneWidget);
    expect(find.text('บิลของเจ้าของคนเดียว'), findsOneWidget);
  });

  testWidgets('renders equal-split service charge and VAT guidance', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen(splitType: 'equal'));
    await tester.pumpAndSettle();

    expect(
      find.text('⚡ คำนวณ Service & VAT แบบหารเท่าเฉพาะคนที่กินจริง'),
      findsOneWidget,
    );
    expect(find.text('Service Charge (10%)'), findsOneWidget);
    expect(find.text('VAT (7%)'), findsOneWidget);
  });
}

class _UserProviderWithProfile extends UserProvider {
  @override
  UserModel? get currentUser => UserModel(
    id: 'test-user',
    displayName: 'Test Host',
    email: 'host@example.test',
  );
}
