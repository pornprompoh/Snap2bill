import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:snap2bill/widgets/common/offline_status_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    try {
      await Supabase.initialize(
        url: 'https://offline-banner-test.supabase.co',
        publishableKey: 'offline-banner-test-key',
      );
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('shows offline guidance and keeps its child visible', (
    tester,
  ) async {
    final service = OfflineService()
      ..reportNetworkFailure(const SocketException('network unavailable'));
    addTearDown(service.disposeService);

    await tester.pumpWidget(
      ChangeNotifierProvider<OfflineService>.value(
        value: service,
        child: const MaterialApp(
          home: Scaffold(
            body: OfflineStatusBanner(child: Text('screen content')),
          ),
        ),
      ),
    );

    expect(find.textContaining('จะซิงก์เมื่อออนไลน์'), findsOneWidget);
    expect(find.text('screen content'), findsOneWidget);
  });

  testWidgets('hides the banner while connected and idle', (tester) async {
    final service = OfflineService();
    addTearDown(service.disposeService);

    await tester.pumpWidget(
      ChangeNotifierProvider<OfflineService>.value(
        value: service,
        child: const MaterialApp(
          home: Scaffold(
            body: OfflineStatusBanner(child: Text('screen content')),
          ),
        ),
      ),
    );

    expect(find.text('จะซิงก์เมื่อออนไลน์'), findsNothing);
    expect(find.text('screen content'), findsOneWidget);
  });
}
