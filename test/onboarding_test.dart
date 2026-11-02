import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap2bill/screens/common/onboarding_screen.dart';
import 'package:snap2bill/services/onboarding/onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('onboarding completion is persisted on this device', () async {
    const service = OnboardingService();

    expect(await service.hasCompleted(), isFalse);
    await service.markCompleted();
    expect(await service.hasCompleted(), isTrue);
  });

  testWidgets('tutorial advances through the app features and finishes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const OnboardingScreen(destinationRoute: '/done'),
        routes: {
          '/done': (_) => const Scaffold(body: Text('Tutorial complete')),
        },
      ),
    );

    expect(find.text('เริ่มจากสแกนใบเสร็จ'), findsOneWidget);
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();
    }

    expect(find.text('ตรวจยอดและชำระเงิน'), findsOneWidget);
    await tester.tap(find.text('เริ่มใช้งาน'));
    await tester.pumpAndSettle();

    expect(find.text('Tutorial complete'), findsOneWidget);
    expect(await const OnboardingService().hasCompleted(), isTrue);
  });

  testWidgets('tutorial supports going back to the previous step', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const OnboardingScreen(destinationRoute: '/done'),
        routes: {
          '/done': (_) => const Scaffold(body: Text('Tutorial complete')),
        },
      ),
    );

    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();
    expect(find.text('ชวนเพื่อนเข้ามาหารบิล'), findsOneWidget);

    await tester.tap(find.text('ย้อนกลับ'));
    await tester.pumpAndSettle();
    expect(find.text('เริ่มจากสแกนใบเสร็จ'), findsOneWidget);
  });
}
