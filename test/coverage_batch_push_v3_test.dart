import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/data/repositories/local_bill_repository.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/screens/bill/lobby_screen.dart';
import 'package:snap2bill/screens/home/home_screen.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _MockSocket extends Mock implements WebSocketChannel {}

class _MockSocketSink extends Mock implements WebSocketSink {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late OfflineService offlineService;
  late _MockSocket socket;
  late _MockSocketSink socketSink;
  late StreamController<dynamic> socketMessages;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    socket = _MockSocket();
    socketSink = _MockSocketSink();
    socketMessages = StreamController<dynamic>.broadcast();
    when(() => socket.ready).thenAnswer((_) async {});
    when(() => socket.stream).thenAnswer((_) => socketMessages.stream);
    when(() => socket.sink).thenReturn(socketSink);
    when(() => socketSink.add(any())).thenReturn(null);
    when(() => socketSink.close(any(), any())).thenAnswer((_) async {});
    when(() => socketSink.done).thenAnswer((_) async {});

    await Supabase.initialize(
      url: 'https://coverage-batch-v3.supabase.co',
      publishableKey: 'coverage-v3-key',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/v1/user')) {
          return http.Response(
            jsonEncode({
              'id': 'user-1',
              'email': 'host@example.test',
              'aud': 'authenticated',
              'role': 'authenticated',
            }),
            200,
            request: request,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response('[]', 200, request: request);
      }),
      realtimeClientOptions: RealtimeClientOptions(
        transport: (_, _) => socket,
        disconnectOnEmptyChannelsAfter: Duration.zero,
      ),
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

  tearDownAll(() async {
    await socketMessages.close();
  });

  testWidgets('HomeScreen renders a seeded bill list and filter tabs', (tester) async {
    final repo = LocalBillRepository();
    print('DEBUG before saveLocalBill');
    await repo.saveLocalBill(
      bill: {
        'id': 'bill-1',
        'owner_id': 'user-1',
        'shop_name': 'Cafe Aroma',
        'created_at': '2026-11-05T10:00:00Z',
        'status': 'completed',
        'total_amount': 200,
      },
      participants: [
        {'profile_id': 'user-1', 'status': 'paid', 'amount_owed': 0},
        {'profile_id': 'friend-1', 'status': 'paid', 'amount_owed': 200},
      ],
    );
    print('DEBUG after saveLocalBill');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OfflineService>.value(value: offlineService),
          ChangeNotifierProvider<BillProvider>.value(value: BillProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(find.text('Cafe Aroma'), findsOneWidget);
    expect(find.text('สำเร็จ (1)'), findsOneWidget);
    await tester.tap(find.text('สำเร็จ (1)'));
    await tester.pump();

    await tester.pumpWidget(const Placeholder());
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await Supabase.instance.client.realtime.disconnect();
    });
  });

  testWidgets('LobbyScreen renders participant data from the provider', (
    tester,
  ) async {
    final provider = BillProvider();
    provider.addRoomParticipants('123456', [
      UserModel(id: 'user-1', displayName: 'Alice', email: 'alice@example.test'),
      UserModel(id: 'user-2', displayName: 'Bob', email: 'bob@example.test'),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<BillProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: LobbyScreen(
            lobbyId: '123456',
            isHost: false,
            receiptData: {
              'shop_name': 'Lobby smoke café',
              'final_total': 120,
              'items': [
                {'item_name': 'Tea', 'qty': 1, 'unit_price': 120},
              ],
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ชวนเพื่อนเข้าห้องตี้'), findsOneWidget);
    expect(find.text('Lobby smoke café'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await Supabase.instance.client.realtime.disconnect();
    });
  });
}
