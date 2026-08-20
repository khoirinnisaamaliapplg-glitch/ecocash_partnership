import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String _onboardingKey = 'has_seen_onboarding';

  // Tandai bahwa onboarding sudah selesai
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // Cek apakah sudah pernah onboarding
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }
}