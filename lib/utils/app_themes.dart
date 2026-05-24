import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom App Themes with Extraordinary Dark Mode
/// Features harmonious colors, gradients, and elegant design
class AppThemes {
  // Primary Brand Colors
  static const Color _primaryGreen = Color(0xFF00C896); // Football field green
  static const Color _primaryBlue = Color(
    0xFF2563EB,
  ); // Vibrant blue (brighter)
  static const Color _accentOrange = Color(0xFFFF6B35); // Vibrant orange
  static const Color _accentPurple = Color(0xFF8B5CF6); // Royal purple

  // Light Theme Colors - Enhanced Blue
  static const Color _lightBackground = Color(0xFFF0F6FF); // Subtle blue tint
  static const Color _lightSurface = Color(0xFFFAFCFF); // Very light blue tint
  static const Color _lightCard = Color(0xFFFFFFFF);

  // Dark Theme Colors - Harmonious & Extraordinary
  static const Color _darkBackground = Color(0xFF0F172A); // Rich navy
  static const Color _darkSurface = Color(0xFF1E293B); // Slate blue
  static const Color _darkCard = Color(0xFF334155); // Lighter slate
  static const Color _darkAccent = Color(0xFF475569); // Accent slate

  /// Light Theme - Clean & Modern
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.cairo()
          .fontFamily, // خط يدعم العربية والإنجليزية والتركية
      colorScheme: const ColorScheme.light(
        primary: _primaryBlue,
        primaryContainer: Color(0xFFDBEAFE), // Light blue container
        secondary: Color(0xFF0EA5E9), // Sky blue for secondary
        secondaryContainer: Color(0xFFE0F2FE),
        tertiary: _accentPurple,
        tertiaryContainer: Color(0xFFEDE9FE),
        surface: _lightSurface,
        surfaceContainerHighest: Color(0xFFE7F0FF),
        error: Color(0xFFDC2626),
        errorContainer: Color(0xFFFEE2E2),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: Color(0xFF1E293B), // Darker blue for text
        outline: Color(0xFF64748B),
        outlineVariant: Color(0xFFBFDBFE), // Blue-tinted outline
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _lightCard,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _lightBackground,
        foregroundColor: Color(0xFF0F172A),
      ),
      textTheme: GoogleFonts.cairoTextTheme(),
    );
  }

  /// Dark Theme - Extraordinary & Harmonious
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.cairo()
          .fontFamily, // خط يدعم العربية والإنجليزية والتركية
      colorScheme: const ColorScheme.dark(
        primary: _primaryGreen, // Vibrant green for primary actions
        primaryContainer: Color(0xFF064E3B), // Deep green container
        secondary: _accentOrange, // Warm orange for secondary actions
        secondaryContainer: Color(0xFF9A3412), // Deep orange container
        tertiary: _accentPurple, // Royal purple for accents
        tertiaryContainer: Color(0xFF581C87), // Deep purple container
        surface: _darkSurface, // Rich slate for cards
        surfaceContainerHighest: _darkCard, // Deep navy background
        error: Color(0xFFEF4444), // Bright red for errors
        errorContainer: Color(0xFF7F1D1D), // Deep red container
        onPrimary: Color(0xFF0F172A), // Dark text on green
        onSecondary: Color(0xFF0F172A), // Dark text on orange
        onTertiary: Colors.white, // White text on purple
        onSurface: Color(0xFFE2E8F0), // Very light text on dark background
        outline: Color(0xFF64748B), // Muted outline
        outlineVariant: Color(0xFF475569), // Darker outline variant
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _darkBackground,
        foregroundColor: Color(0xFFF1F5F9),
      ),
      // Enhanced button themes for dark mode
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: _darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkSurface,
          foregroundColor: Color(0xFFF1F5F9),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _darkAccent),
          ),
        ),
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    );
  }

  /// Gradient Decorations for Enhanced Visual Appeal

  // Primary gradient for headers and important sections
  static BoxDecoration primaryGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                _primaryGreen,
                _primaryGreen.withValues(alpha: 0.8),
                _accentOrange.withValues(alpha: 0.6),
              ]
            : [
                _primaryBlue,
                _primaryBlue.withValues(alpha: 0.8),
                _primaryGreen.withValues(alpha: 0.6),
              ],
      ),
      borderRadius: BorderRadius.circular(16),
    );
  }

  // Subtle gradient for cards in dark mode
  static BoxDecoration cardGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) {
      return BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _darkSurface,
          _darkSurface.withValues(alpha: 0.95),
          _darkCard.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _darkAccent.withValues(alpha: 0.3)),
    );
  }

  // Background gradient for screens
  static BoxDecoration backgroundGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF0F6FF), // Light blue
            const Color(0xFFFAFCFF), // Very light blue
            Colors.white,
          ],
        ),
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _darkBackground,
          _darkBackground.withValues(alpha: 0.95),
          _darkSurface.withValues(alpha: 0.1),
        ],
      ),
    );
  }

  // Accent gradient for special elements
  static BoxDecoration accentGradient(BuildContext context, Color accentColor) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor,
          accentColor.withValues(alpha: 0.8),
          accentColor.withValues(alpha: 0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Color Palette for Consistent Usage

  // Success colors
  static const Color successLight = Color(0xFF10B981);
  static const Color successDark = Color(0xFF34D399);

  // Warning colors
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);

  // Info colors
  static const Color infoLight = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF60A5FA);

  // Neutral grays
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
}
