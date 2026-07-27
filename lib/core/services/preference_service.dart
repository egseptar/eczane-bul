import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama içi kalıcı tercihleri yöneten servis.
class PreferenceService {
  PreferenceService._();
  static final PreferenceService _instance = PreferenceService._();
  static PreferenceService get instance => _instance;

  static const String _keyIsFirstLaunch = 'is_first_launch_v1';

  /// Kullanıcının onboarding ekranını daha önce tamamlayıp tamamlamadığını kontrol eder.
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsFirstLaunch) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Onboarding tamamlandığında ilk açılış bayrağını false yapar.
  Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsFirstLaunch, false);
    } catch (_) {}
  }
}
