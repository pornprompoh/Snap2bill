import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/routes/app_routes.dart';
import 'package:snap2bill/screens/common/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    try {
      await Supabase.initialize(
        url: 'https://splash-route-test.supabase.co',
        publishableKey: 'splash-route-test-key',
        httpClient: MockClient((_) async => http.Response('', 204)),
      );
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('routes unauthenticated users to login after the splash delay', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SplashScreen(),
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('login route')),
        },
      ),
    );
    expect(find.text('Snap2Bill'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pump();

    expect(find.text('login route'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
