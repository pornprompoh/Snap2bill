import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:snap2bill/widgets/common/offline_status_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    try {
      await Supabase.initialize(
        url: 'https://offline-test.supabase.co',
        publishableKey: 'offline-test-key',
      );
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('offline operations survive serialization and can be removed', () async {
    final queue = OfflineQueue();

    await queue.enqueue(
      type: 'update_bill',
      payload: {
        'id': 'bill-1',
        'data': {'status': 'completed'},
      },
    );

    final operations = await queue.readAll();
    expect(operations, hasLength(1));
    expect(operations.single.type, 'update_bill');
    expect(operations.single.payload['id'], 'bill-1');

    await queue.remove(operations.single.id);
    expect(await queue.readAll(), isEmpty);
  });

  test(
    'network errors are recognized without swallowing application errors',
    () {
      expect(
        OfflineService.isLikelyNetworkError(
          const SocketException('failed host lookup'),
        ),
        isTrue,
      );
      expect(
        OfflineService.isLikelyNetworkError(StateError('RLS denied')),
        isFalse,
      );
      for (final message in [
        'network unavailable',
        'request timeout',
        'connection reset',
        'ClientException: request failed',
      ]) {
        expect(OfflineService.isLikelyNetworkError(Exception(message)), isTrue);
      }
    },
  );

  test('network failures transition service to offline', () async {
    final service = OfflineService();
    service.reportNetworkFailure(const SocketException('Failed host lookup'));

    expect(service.isOffline, isTrue);
    service.reportNetworkFailure(StateError('permission denied'));
    expect(service.isOffline, isTrue);

    await service.disposeService();
  });

  test(
    'flush applies queued updates, payment actions, and guest membership',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://offline-queue-test.supabase.co',
        'test-anon-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/lobbies')) {
            return http.Response(
              jsonEncode({
                'receipt_json': {
                  'room_members': [
                    {'id': 'existing', 'name': 'Existing'},
                  ],
                },
              }),
              200,
              request: request,
              headers: const {'content-type': 'application/json'},
            );
          }
          return http.Response('', 204, request: request);
        }),
      );
      addTearDown(client.dispose);

      final connectivity = _MockConnectivity();
      when(
        connectivity.checkConnectivity,
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => const Stream<List<ConnectivityResult>>.empty());

      final queue = OfflineQueue();
      await queue.enqueue(
        type: 'update_bill',
        payload: {
          'id': 'bill-1',
          'data': {'status': 'settled'},
        },
      );
      await queue.enqueue(
        type: 'update_profile',
        payload: {
          'id': 'profile-1',
          'data': {'display_name': 'Mina'},
        },
      );
      await queue.enqueue(
        type: 'update_participant',
        payload: {
          'bill_id': 'bill-1',
          'profile_id': 'profile-1',
          'data': {'status': 'paid'},
        },
      );
      await queue.enqueue(
        type: 'submit_bill_payment',
        payload: {
          'bill_id': 'bill-1',
          'profile_id': 'profile-1',
          'slip_data': 'data:image/jpeg;base64,dGVzdA==',
        },
      );
      await queue.enqueue(
        type: 'set_bill_payment_status',
        payload: {
          'bill_id': 'bill-1',
          'profile_id': 'profile-1',
          'status': 'paid',
        },
      );
      await queue.enqueue(
        type: 'add_room_guest_member',
        payload: {
          'room_code': 'ROOM01',
          'member': {'id': 'existing', 'name': 'Existing'},
        },
      );

      final service = OfflineService(
        connectivity: connectivity,
        queue: queue,
        client: client,
      );
      await service.start();

      expect(await queue.readAll(), isEmpty);
      expect(service.isSyncing, isFalse);
      expect(
        requests.map((request) => '${request.method} ${request.url.path}'),
        containsAll([
          'PATCH /rest/v1/bills',
          'PATCH /rest/v1/profiles',
          'PATCH /rest/v1/bill_participants',
          'POST /rest/v1/rpc/submit_bill_payment',
          'POST /rest/v1/rpc/set_bill_payment_status',
          'GET /rest/v1/lobbies',
          'PATCH /rest/v1/lobbies',
        ]),
      );

      final participantPatch = requests.firstWhere(
        (request) => request.url.path.endsWith('/bill_participants'),
      );
      expect(participantPatch.url.queryParameters['bill_id'], 'eq.bill-1');
      expect(
        participantPatch.url.queryParameters['profile_id'],
        'eq.profile-1',
      );

      final paymentRequest = requests.firstWhere(
        (request) => request.url.path.endsWith('/rpc/submit_bill_payment'),
      );
      expect(
        jsonDecode(paymentRequest.body)['p_slip_data'],
        'data:image/jpeg;base64,dGVzdA==',
      );

      final guestUpdate = requests.last;
      final updatedReceipt = jsonDecode(guestUpdate.body)['receipt_json'];
      expect(updatedReceipt['room_members'], hasLength(1));
      expect(updatedReceipt['room_members'].single['id'], 'existing');

      await service.disposeService();
    },
  );

  test(
    'service reports offline state and does not flush while offline',
    () async {
      final connectivity = _MockConnectivity();
      when(
        connectivity.checkConnectivity,
      ).thenAnswer((_) async => [ConnectivityResult.none]);
      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => const Stream<List<ConnectivityResult>>.empty());

      final service = OfflineService(connectivity: connectivity);
      await service.start();

      expect(service.isOffline, isTrue);
      expect(service.isSyncing, isFalse);
      await service.flush();
      expect(service.isSyncing, isFalse);
      await service.disposeService();
    },
  );

  test(
    'service follows connectivity transitions and keeps failed work queued',
    () async {
      final connectivity = _MockConnectivity();
      final changes = StreamController<List<ConnectivityResult>>.broadcast();
      when(
        connectivity.checkConnectivity,
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => changes.stream);

      final queue = OfflineQueue();
      await queue.enqueue(type: 'not_supported', payload: {'id': 'operation'});
      final service = OfflineService(connectivity: connectivity, queue: queue);
      await service.start();

      expect(service.isOnline, isTrue);
      expect(service.isSyncing, isFalse);
      expect(await queue.readAll(), hasLength(1));

      changes.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(service.isOffline, isTrue);

      changes.add([ConnectivityResult.mobile]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(service.isOnline, isTrue);
      expect(service.isSyncing, isFalse);
      expect(await queue.readAll(), hasLength(1));

      await service.disposeService();
      await changes.close();
    },
  );

  testWidgets('banner renders its child', (tester) async {
    final service = OfflineService();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: service,
        child: const MaterialApp(
          home: Scaffold(body: OfflineStatusBanner(child: Text('content'))),
        ),
      ),
    );

    expect(find.text('content'), findsOneWidget);
    await service.disposeService();
  });
}
