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
import 'package:snap2bill/models/contact_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/providers/contact_provider.dart';
import 'package:snap2bill/routes/app_routes.dart';
import 'package:snap2bill/screens/bill/lobby_screen.dart';
import 'package:snap2bill/screens/friends/friend_list_screen.dart';
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
      url: 'https://coverage-batch-v2.supabase.co',
      publishableKey: 'coverage-v2-key',
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
        if (request.url.path.contains('/rest/v1/lobbies')) {
          if (request.url.query.contains('room_code')) {
            return http.Response(
              jsonEncode({
                'id': 'room-123456',
                'room_code': '123456',
                'shop_name': 'Room smoke café',
                'receipt_json': {
                  'shop_name': 'Room smoke café',
                  'final_total': 120,
                  'items': [
                    {'item_name': 'Tea', 'qty': 1, 'unit_price': 120},
                  ],
                },
              }),
              200,
              request: request,
              headers: const {'content-type': 'application/json'},
            );
          }
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

  testWidgets('HomeScreen shows join-room validation flow', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OfflineService>.value(value: offlineService),
          ChangeNotifierProvider<BillProvider>.value(value: BillProvider()),
        ],
        child: MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(find.text('บิลแรกของคุณเริ่มได้ที่นี่'), findsOneWidget);
    await tester.tap(find.text('มีเพื่อนสร้างห้องไว้แล้ว'));
    await tester.pumpAndSettle();
    expect(find.text('เข้าร่วมห้องหารบิล'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('เข้าร่วมเลย'));
    await tester.pump();
    expect(find.text('กรุณากรอกรหัสห้องให้ครบ 6 หลัก'), findsOneWidget);
    await _disposeScreen(tester);
  });

  testWidgets('FriendListScreen selection mode can return pasted participants', (
    tester,
  ) async {
    final provider = _FakeContactProvider([
      ContactModel(
        id: 'contact-1',
        userId: 'user-1',
        name: 'Mina',
        createdAt: DateTime.utc(2026, 11, 1),
      ),
      ContactModel(
        id: 'contact-2',
        userId: 'user-1',
        name: 'Niran',
        createdAt: DateTime.utc(2026, 11, 2),
      ),
    ]);
    await tester.pumpWidget(
      ChangeNotifierProvider<ContactProvider>.value(
        value: provider,
        child: const MaterialApp(home: FriendListScreen(selectionMode: true)),
      ),
    );
    await tester.pump();

    expect(find.text('เลือกเพื่อนจากบิลก่อนหน้า'), findsOneWidget);
    expect(find.text('กรุณาล็อกอิน'), findsOneWidget);
    await _disposeScreen(tester);
  });

  testWidgets('LobbyScreen builds and surfaces the room summary card', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<BillProvider>(
        create: (_) => BillProvider(),
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
    expect(find.text('ยอดสุทธิจากใบเสร็จ'), findsOneWidget);
    await _disposeScreen(tester);
  });
}

class _FakeContactProvider extends ContactProvider {
  _FakeContactProvider(this._contacts);

  final List<ContactModel> _contacts;

  @override
  List<ContactModel> get contacts => List.unmodifiable(_contacts);

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadContacts() async {}

  @override
  Future<void> deleteContact(String id) async {}
}

Future<void> _disposeScreen(WidgetTester tester) async {
  await tester.pumpWidget(const Placeholder());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await Supabase.instance.client.realtime.disconnect();
  });
}
