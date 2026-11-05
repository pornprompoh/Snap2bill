import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/routes/app_routes.dart';
import 'package:snap2bill/screens/bill/join_room_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _requests = <http.Request>[];
var _roomResponse = http.Response('[]', 200);
var _billResponse = http.Response('{}', 200);

String _testToken() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none'})));
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': 'join-user',
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'join@example.test',
        'iat': now,
        'exp': now + 3600,
      }),
    ),
  );
  return '$header.$payload.${base64Url.encode(utf8.encode('test-signature'))}';
}

Future<void> _signIn() async {
  await Supabase.instance.client.auth.setSession(
    'test-refresh-token',
    accessToken: _testToken(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await Supabase.initialize(
      url: 'https://join-room-test.supabase.co',
      publishableKey: 'join-room-test-key',
      httpClient: MockClient((request) async {
        _requests.add(request);
        if (request.url.path.endsWith('/auth/v1/user')) {
          return http.Response(
            jsonEncode({
              'id': 'join-user',
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'join@example.test',
            }),
            200,
            request: request,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/rest/v1/lobbies')) {
          return http.Response(
            _roomResponse.body,
            _roomResponse.statusCode,
            request: request,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/rest/v1/rpc/join_bill')) {
          return http.Response('', 204, request: request);
        }
        if (request.url.path.endsWith('/rest/v1/bills')) {
          return http.Response(
            _billResponse.body,
            _billResponse.statusCode,
            request: request,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response('', 204, request: request);
      }),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    _requests.clear();
    _roomResponse = http.Response('[]', 200);
    _billResponse = http.Response('{}', 200);
  });

  Widget app(String? roomId) => MaterialApp(
    routes: {
      AppRoutes.login: (_) => const Scaffold(body: Text('login destination')),
      AppRoutes.home: (_) => const Scaffold(body: Text('home destination')),
      AppRoutes.lobby: (_) => const Scaffold(body: Text('lobby destination')),
      AppRoutes.detail: (_) => const Scaffold(body: Text('detail destination')),
    },
    home: JoinRoomScreen(roomId: roomId),
  );

  testWidgets('shows an error when there is no room to resume', (tester) async {
    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();

    expect(find.textContaining('ไม่พบรหัสบิลหรือห้อง'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
  });

  testWidgets('stores a valid room id and redirects unauthenticated users', (
    tester,
  ) async {
    await tester.pumpWidget(app('123456'));
    await tester.pumpAndSettle();

    expect(find.text('login destination'), findsOneWidget);
    expect(_requests, isEmpty);
    expect(
      await SharedPreferencesAsync().getString('pending_join_room_id'),
      '123456',
    );
  });

  testWidgets('rejects malformed room ids and can clear the pending join', (
    tester,
  ) async {
    await _signIn();
    await tester.pumpWidget(app('not-a-room'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('รูปแบบรหัสบิลหรือห้องไม่ถูกต้อง'),
      findsOneWidget,
    );
    await tester.tap(find.text('กลับหน้าหลัก'));
    await tester.pumpAndSettle();
    expect(find.text('home destination'), findsOneWidget);
    expect(
      await SharedPreferencesAsync().getString('pending_join_room_id'),
      isNull,
    );
  });

  testWidgets('joins an existing six-digit lobby and clears the pending id', (
    tester,
  ) async {
    await _signIn();
    _roomResponse = http.Response(
      jsonEncode([
        {
          'host_id': 'join-user',
          'receipt_json': {'shop_name': 'Lobby Cafe'},
        },
      ]),
      200,
    );

    await tester.pumpWidget(app('123456'));
    await tester.pumpAndSettle();

    expect(find.text('lobby destination'), findsOneWidget);
    expect(
      _requests.any((request) => request.url.path.endsWith('/lobbies')),
      isTrue,
    );
    expect(
      await SharedPreferencesAsync().getString('pending_join_room_id'),
      isNull,
    );
  });

  testWidgets('joins a bill UUID through the RPC and opens its detail', (
    tester,
  ) async {
    await _signIn();
    const billId = '12345678-1234-1234-1234-123456789abc';
    _billResponse = http.Response(
      jsonEncode({'id': billId, 'shop_name': 'Shared Cafe'}),
      200,
    );

    await tester.pumpWidget(app(billId));
    await tester.pumpAndSettle();

    expect(find.text('detail destination'), findsOneWidget);
    final joinRequest = _requests.singleWhere(
      (request) => request.url.path.endsWith('/rpc/join_bill'),
    );
    expect(joinRequest.method, 'POST');
    expect(jsonDecode(joinRequest.body), {'p_bill_id': billId});
    expect(
      await SharedPreferencesAsync().getString('pending_join_room_id'),
      isNull,
    );
  });
}
