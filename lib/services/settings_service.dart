import 'package:flutter/material.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Notifications
  bool newsAll = true;
  bool newsFavoritesOnly = false; // if true, implies not all

  bool matchStartAlerts = true;
  bool matchEndAlerts = true;
  bool goalAlertsOnly = false;

  // Language: ar, en, tr, system
  String languageCode = 'system';

  // Time format: '12h' or '24h'
  String timeFormat = '24h';

  // Location-based notifications
  bool locationBased = false;

  // Microphone permission
  bool microphoneEnabled = true;

  // Appearance: 'light', 'dark', or 'system'
  String theme = 'system';

  // ✅ دالة للحصول على اللغة الفعلية (تحويل 'system' إلى اللغة الحقيقية)
  String getActualLanguageCode() {
    if (languageCode == 'system') {
      // الحصول على لغة النظام
      final systemLocale = WidgetsBinding.instance.window.locale.languageCode;
      print('🌍 System locale detected: $systemLocale');

      // تحويل لغة النظام إلى اللغات المدعومة
      if (systemLocale.startsWith('ar')) return 'ar';
      if (systemLocale.startsWith('tr')) return 'tr';
      return 'en'; // الافتراضي
    }
    return languageCode;
  }

  void setNewsMode({required bool all}) {
    newsAll = all;
    newsFavoritesOnly = !all;
    notifyListeners();
  }

  void setLanguage(String code) {
    if (languageCode == code) return;
    languageCode = code;
    notifyListeners();
  }

  void setTheme(String mode) {
    if (theme == mode) return;
    theme = mode;
    notifyListeners();
  }

  void setTimeFormat(String fmt) {
    if (timeFormat == fmt) return;
    timeFormat = fmt;
    notifyListeners();
  }

  void setLocationBased(bool enabled) {
    if (locationBased == enabled) return;
    locationBased = enabled;
    notifyListeners();
  }

  void setMicrophoneEnabled(bool enabled) {
    if (microphoneEnabled == enabled) return;
    microphoneEnabled = enabled;
    notifyListeners();
  }

  void setMatchStartAlerts(bool v) {
    matchStartAlerts = v;
    notifyListeners();
  }

  void setMatchEndAlerts(bool v) {
    matchEndAlerts = v;
    notifyListeners();
  }

  void setGoalAlertsOnly(bool v) {
    goalAlertsOnly = v;
    notifyListeners();
  }
}
