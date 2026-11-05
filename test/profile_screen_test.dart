import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/domain/repositories/user_repository.dart';
import 'package:snap2bill/data/repositories/local_bill_repository.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/theme_provider.dart';
import 'package:snap2bill/providers/user_provider.dart';
import 'package:snap2bill/screens/profile/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late UserProvider userProvider;
  late ThemeProvider themeProvider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final documentsPath = Directory(
      '${Directory.current.path}\\build\\profile_screen_test_data',
    );
    await documentsPath.create(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => call.method == 'getApplicationDocumentsDirectory'
              ? documentsPath.path
              : null,
        );
    try {
      await Supabase.initialize(
        url: 'https://profile-screen-test.supabase.co',
        publishableKey: 'profile-screen-test-key',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'id': 'profile-user',
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'profile@example.test',
            }),
            200,
            request: request,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
    } catch (_) {}
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await Supabase.instance.client.auth.setSession(
      'refresh-token',
      accessToken: _testToken('profile-user'),
    );
    await LocalBillRepository().cacheProfile({
      'id': 'profile-user',
      'display_name': 'Profile user',
      'email': 'profile@example.test',
      'payment_info': {
        'type': 'phone',
        'number': '0812345678',
        'bank_name': 'ธนาคารทดสอบ',
        'bank_account_number': '1234567890',
        'bank_account_name': 'Profile user',
      },
    });
    userProvider = UserProvider(userRepository: _FakeUserRepository());
    await userProvider.fetchCurrentUserProfile();
    themeProvider = ThemeProvider();
  });

  testWidgets('shows profile details and toggles theme mode', (tester) async {
    await _pumpProfile(tester, userProvider, themeProvider);
    await tester.pump();

    expect(find.text('โปรไฟล์ส่วนตัว'), findsOneWidget);
    expect(find.text('Profile user'), findsWidgets);
    expect(find.text('0812345678'), findsOneWidget);
    expect(find.text('เบอร์มือถือ'), findsOneWidget);
    expect(find.text('ธนาคารทดสอบ'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);

    await tester.ensureVisible(find.text('โหมดมืด (Dark Mode)'));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(themeProvider.isDarkMode, isTrue);

    await tester.ensureVisible(find.text('แก้ไขโปรไฟล์'));
    expect(userProvider.isLoading, isFalse);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'แก้ไขโปรไฟล์'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('แก้ไขโปรไฟล์'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('ข้อมูล PromptPay'), findsOneWidget);
    expect(find.text('ข้อมูลบัญชีธนาคาร (ทางเลือกเพิ่มเติม)'), findsOneWidget);
  });

  testWidgets('validates PromptPay identifier and allows cancelling edits', (
    tester,
  ) async {
    await _pumpProfile(tester, userProvider, themeProvider);
    await tester.pump();
    await tester.ensureVisible(find.text('แก้ไขโปรไฟล์'));
    await tester.tap(find.text('แก้ไขโปรไฟล์'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    await tester.tap(find.text('เลขบัตรประชาชน'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    final promptPayField = find.byType(TextFormField).at(1);
    await tester.enterText(promptPayField, '123456789012');
    await tester.ensureVisible(find.text('บันทึกข้อมูล'));
    await tester.tap(find.text('บันทึกข้อมูล'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('กรุณากรอกให้ครบ 13 หลัก'), findsOneWidget);

    await tester.tap(find.text('ยกเลิก'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('แก้ไขโปรไฟล์'), findsOneWidget);
  });
}

String _testToken(String userId) {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none'})));
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': userId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'profile@example.test',
        'iat': now,
        'exp': now + 3600,
      }),
    ),
  );
  return '$header.$payload.${base64Url.encode(utf8.encode('test-signature'))}';
}

Future<void> _pumpProfile(
  WidgetTester tester,
  UserProvider userProvider,
  ThemeProvider themeProvider,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<UserModel?> getMyProfile() async => UserModel(
    id: 'profile-user',
    displayName: 'Profile user',
    email: 'profile@example.test',
    avatarUrl: null,
    paymentInfo: {
      'type': 'phone',
      'number': '0812345678',
      'bank_name': 'ธนาคารทดสอบ',
      'bank_account_number': '1234567890',
      'bank_account_name': 'Profile user',
    },
  );

  @override
  Future<UserModel> updateUserProfile({
    required String displayName,
    required Map<String, dynamic>? paymentInfo,
  }) async => UserModel(
    id: 'profile-user',
    displayName: displayName,
    email: 'profile@example.test',
    paymentInfo: paymentInfo,
  );

  @override
  Future<List<FriendModel>> getMyFriends() async => [];

  @override
  Future<void> addFriend(String friendName) async {}
}
