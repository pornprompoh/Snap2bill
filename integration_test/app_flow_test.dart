import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snap2bill/screens/auth/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login validation starts the bill-sharing flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.byType(LoginScreen), findsOneWidget);

    final loginButton = find.text('เข้าสู่ระบบ');
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
    expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
  });
}
