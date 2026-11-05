import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap2bill/services/onboarding/onboarding_service.dart';

void main() {
  const service = OnboardingService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reports onboarding incomplete when no preference exists', () async {
    expect(await service.hasCompleted(), isFalse);
  });

  test('persists onboarding completion', () async {
    await service.markCompleted();

    expect(await service.hasCompleted(), isTrue);
  });
}
