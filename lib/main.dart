import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome_screen.dart';
import 'services/settings_service.dart';
import 'utils/app_themes.dart';

void main() {
  // Pre-load fonts for Arabic support on Web
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final SettingsService _settings = SettingsService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        // تحديد وضع الثيم
        ThemeMode themeMode;
        if (_settings.theme == 'system') {
          themeMode = ThemeMode.system; // اتبع نظام الهاتف
        } else if (_settings.theme == 'dark') {
          themeMode = ThemeMode.dark;
        } else {
          themeMode = ThemeMode.light;
        }

        // تحديد اللغة
        Locale? locale;
        if (_settings.languageCode != 'system') {
          locale = Locale(_settings.languageCode);
        }
        // إذا كانت 'system'، سيتم استخدام لغة الهاتف تلقائياً

        return MaterialApp(
          title: 'Football Scores',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeMode,
          locale: locale, // null = استخدم لغة الهاتف
          supportedLocales: const [Locale('en'), Locale('ar'), Locale('tr')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // اختيار اللغة الأقرب للغة الهاتف
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            // إذا اختار المستخدم لغة محددة، استخدمها
            if (_settings.languageCode != 'system') {
              return Locale(_settings.languageCode);
            }

            // وإلا، جرب مطابقة لغة الهاتف
            if (deviceLocale != null) {
              for (var locale in supportedLocales) {
                if (locale.languageCode == deviceLocale.languageCode) {
                  return locale;
                }
              }
            }

            // افتراضي: الإنجليزية
            return const Locale('en');
          },
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
