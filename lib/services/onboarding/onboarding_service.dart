import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _completedKey = 'snap2bill_onboarding_completed';

  const OnboardingService();

  Future<bool> hasCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_completedKey) ?? false;
  }

  Future<void> markCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_completedKey, true);
    if (!saved) {
      throw StateError('ไม่สามารถบันทึกสถานะการแนะนำการใช้งานได้');
    }
  }
}
