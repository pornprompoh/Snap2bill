import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:snap2bill/widgets/bill/receipt_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    try {
      await Supabase.initialize(
        url: 'https://receipt-image-test.supabase.co',
        publishableKey: 'receipt-image-test-key',
      );
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('renders the unavailable state when receipt is offline', (
    tester,
  ) async {
    final service = OfflineService()
      ..reportNetworkFailure(const SocketException('network unavailable'));
    addTearDown(service.disposeService);

    await tester.pumpWidget(
      ChangeNotifierProvider<OfflineService>.value(
        value: service,
        child: MaterialApp(
          home: Scaffold(
            body: ReceiptImage(
              imageUrl: 'https://storage.example.test/receipt.jpg',
              errorBuilder: (_, error) => Text(error.runtimeType.toString()),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('StateError'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows an unavailable state when no image is supplied', (
    tester,
  ) async {
    final service = OfflineService();
    addTearDown(service.disposeService);

    await tester.pumpWidget(
      ChangeNotifierProvider<OfflineService>.value(
        value: service,
        child: MaterialApp(
          home: Scaffold(
            body: ReceiptImage(
              errorBuilder: (_, error) => Text(error.runtimeType.toString()),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('StateError'), findsOneWidget);
  });
}
