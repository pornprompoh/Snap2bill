import 'dart:io';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
