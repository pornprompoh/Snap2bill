import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    try {
      await Supabase.initialize(
        url: 'https://login-screen-test.supabase.co',
        publishableKey: 'login-screen-test-key',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'message': 'invalid credentials'}),
            400,
            request: request,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'toggles password visibility, forgot-password, and sign-up mode',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Snap2Bill'), findsOneWidget);
      expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบเพื่อจัดการบิล'), findsOneWidget);

      final passwordField = find.byType(TextFormField).last;
      final editablePassword = find.descendant(
        of: passwordField,
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(editablePassword).obscureText, isTrue);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(tester.widget<EditableText>(editablePassword).obscureText, isFalse);

      await tester.tap(find.text('ลืมรหัสผ่าน?'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text('กรุณาติดต่อผู้ดูแลระบบเพื่อรีเซ็ตรหัสผ่าน'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('ยังไม่มีบัญชีใช่ไหม? สมัครสมาชิก'));
      await tester.tap(find.text('ยังไม่มีบัญชีใช่ไหม? สมัครสมาชิก'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('สร้างบัญชีใหม่'), findsOneWidget);
      expect(find.text('สมัครสมาชิกเพื่อเริ่มต้นใช้งาน'), findsOneWidget);
      expect(find.text('ลืมรหัสผ่าน?'), findsNothing);

      await tester.tap(find.text('มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);
    },
  );

  testWidgets('shows an explicit sign-in error for rejected credentials', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    await tester.enterText(
      find.byType(TextFormField).first,
      'bad@example.test',
    );
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบอีเมลและรหัสผ่าน'),
      findsOneWidget,
    );
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
  });
}
