import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/domain/repositories/user_repository.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/providers/theme_provider.dart';
import 'package:snap2bill/providers/user_provider.dart';
import 'package:snap2bill/screens/bill/review_screen.dart';
import 'package:snap2bill/screens/bill/claim_screen.dart';
import 'package:snap2bill/screens/bill/lobby_screen.dart';
import 'package:snap2bill/screens/bill/scan_screen.dart';
import 'package:snap2bill/screens/common/onboarding_screen.dart';
import 'package:snap2bill/screens/home/home_screen.dart';
import 'package:snap2bill/screens/main/main_screen.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:web_socket_channel/web_socket_channel.dart';

class _MockSocket extends Mock implements WebSocketChannel {}

class _MockSocketSink extends Mock implements WebSocketSink {}

class _MockUserRepository extends Mock implements UserRepository {}

class _OfflineBillProvider extends BillProvider {
  @override
  Future<void> loadRoomMembers(String roomCode) async {}

  @override
  Future<RoomMember> addGuestMember(String name) async {
    final member = RoomMember(id: 'guest-test', name: name, isGuest: true);
    mergeRoomMembers([member]);
    return member;
  }
}

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
    final documentsDirectory = Directory(
      '${Directory.current.path}\\build\\all_screens_smoke_test_data',
    );
    await documentsDirectory.create(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => call.method == 'getApplicationDocumentsDirectory'
              ? documentsDirectory.path
              : null,
        );

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
      url: 'https://all-screens-smoke-test.supabase.co',
      publishableKey: 'all-screens-smoke-test-key',
      httpClient: MockClient((request) async {
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
      ..reportNetworkFailure(const SocketException('offline test'));
  });

  tearDown(() async {
    await offlineService.disposeService();
  });

  tearDownAll(() async {
    await socketMessages.close();
  });

  testWidgets('HomeScreen builds with its realtime transport mocked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OfflineService>.value(value: offlineService),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Snap2Bill'), findsOneWidget);

    await _disposeScreen(tester);
  });

  testWidgets('HomeScreen loads the empty state and validates room codes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OfflineService>.value(value: offlineService),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
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

  testWidgets('MainScreen builds its profile tab with dummy providers', (
    tester,
  ) async {
    final userProvider = UserProvider(userRepository: _MockUserRepository())
      ..setOfflineService(offlineService);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OfflineService>.value(value: offlineService),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(home: MainScreen(initialIndex: 2)),
      ),
    );
    await tester.pump();

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('โปรไฟล์ส่วนตัว'), findsOneWidget);

    await _disposeScreen(tester);
  });

  testWidgets('LobbyScreen builds with room-member loading stubbed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<BillProvider>(
        create: (_) => _OfflineBillProvider(),
        child: const MaterialApp(
          home: LobbyScreen(
            lobbyId: '123456',
            isHost: false,
            receiptData: {
              'shop_name': 'Lobby smoke cafe',
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
    expect(find.text('Lobby smoke cafe'), findsOneWidget);

    await _disposeScreen(tester);
  });

  testWidgets('ClaimScreen builds with a static receipt and fake realtime', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<BillProvider>(
        create: (_) => _OfflineBillProvider(),
        child: const MaterialApp(
          home: ClaimScreen(
            lobbyId: '123456',
            isHost: false,
            receiptData: {
              'shop_name': 'Claim smoke cafe',
              'items': [
                {'item_name': 'Tea', 'qty': 1, 'unit_price': 120},
              ],
            },
            roomParticipants: [
              {'id': 'friend-1', 'name': 'Smoke friend'},
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('จิ้มเลือกอาหารที่คุณกินจริง'), findsOneWidget);
    expect(find.text('Claim smoke cafe'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);

    await _disposeScreen(tester);
  });

  testWidgets('ClaimScreen updates personal quantity and shared claims', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<BillProvider>(
        create: (_) => _OfflineBillProvider(),
        child: const MaterialApp(
          home: ClaimScreen(
            lobbyId: '123456',
            isHost: false,
            receiptData: {
              'shop_name': 'Claim interaction cafe',
              'items': [
                {'item_name': 'Soup', 'qty': 2, 'unit_price': 50},
              ],
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('เหลือ 2 จาน'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('เหลือ 1 จาน'), findsOneWidget);
    expect(find.textContaining('50'), findsWidgets);

    await tester.tap(find.text('กดกินด้วยกัน (หารเท่า)'));
    await tester.pump();
    expect(find.text('กินด้วยกัน (แชร์จานนี้)'), findsOneWidget);

    await _disposeScreen(tester);
  });

  testWidgets('ClaimScreen lets the host add a guest and select their claims', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<BillProvider>(
        create: (_) => _OfflineBillProvider(),
        child: const MaterialApp(
          home: ClaimScreen(
            lobbyId: '123456',
            isHost: true,
            receiptData: {
              'shop_name': 'Host claim cafe',
              'items': [
                {'item_name': 'Noodles', 'qty': 2, 'unit_price': 80},
              ],
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('+ เพื่อน'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Guest One');
    await tester.tap(find.text('เพิ่มเพื่อน'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'เพิ่มเพื่อน "Guest One" แล้ว สามารถเลือกอาหารแทนเพื่อนได้ทันที ✅',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เลือกจานให้: Guest One').last);
    await tester.pump();
    expect(find.text('เลือกจานให้: Guest One'), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('เหลือ 1 จาน'), findsOneWidget);

    await _disposeScreen(tester);
  });

  testWidgets('ScanScreen builds its static scan controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScanScreen()));
    await tester.pump();

    expect(find.text('ถ่ายรูปใบเสร็จ'), findsOneWidget);
    expect(find.text('ถ่ายรูป'), findsOneWidget);
    expect(find.text('คลังภาพ'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('OnboardingScreen builds its initial tutorial page', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen(destinationRoute: '/finished')),
    );
    await tester.pump();

    expect(find.text('เริ่มจากสแกนใบเสร็จ'), findsOneWidget);
    expect(find.text('ถัดไป'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('ReviewScreen builds from static receipt data', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<BillProvider>(
        create: (_) => BillProvider(),
        child: const MaterialApp(
          home: ReviewScreen(
            receiptData: {
              'shop_name': 'Smoke test cafe',
              'items': [
                {'item_name': 'Tea', 'qty': 1, 'unit_price': 40},
              ],
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Smoke test cafe'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
  });
}

Future<void> _disposeScreen(WidgetTester tester) async {
  await tester.pumpWidget(const Placeholder());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await Supabase.instance.client.realtime.disconnect();
  });
}
