import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppColors {
  AppColors._();

  static bool get isDark => AppTheme.themeNotifier.value == ThemeMode.dark;

  // Primary Medical Blues
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryBlueDark = Color(0xFF003C8F);
  static const Color primaryBlueLight = Color(0xFF5E92F3);
  static const Color primaryBlueSurface = Color(0xFFE3F2FD);

  // Teal / Turkuaz
  static const Color teal = Color(0xFF00897B);
  static const Color tealDark = Color(0xFF00574B);
  static const Color tealLight = Color(0xFF4EBAAA);
  static const Color tealSurface = Color(0xFFE0F2F1);

  // Accent Green
  static const Color green = Color(0xFF43A047);
  static const Color greenDark = Color(0xFF2E7D32);
  static const Color greenLight = Color(0xFF76D275);
  static const Color greenSurface = Color(0xFFE8F5E9);

  // Emergency / Pharmacy Red
  static const Color emergencyRed = Color(0xFFD32F2F);
  static const Color emergencyRedDark = Color(0xFF9A0007);
  static const Color emergencyRedLight = Color(0xFFFF6659);
  static const Color emergencyRedSurface = Color(0xFFFFEBEE);

  // Neutrals
  static Color get background => isDark ? const Color(0xFF121824) : const Color(0xFFF5F7FA);
  static Color get surface => isDark ? const Color(0xFF1E2638) : const Color(0xFFFFFFFF);
  static Color get cardBackground => isDark ? const Color(0xFF1E2638) : const Color(0xFFFFFFFF);

  static Color get textPrimary => isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1A1F36);
  static Color get textSecondary => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  static Color get textTertiary => isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  static const Color textInverse = Color(0xFFFFFFFF);

  static Color get divider => isDark ? const Color(0xFF2E3A52) : const Color(0xFFE5E7EB);
  static Color get border => isDark ? const Color(0xFF2E3A52) : const Color(0xFFD1D5DB);

  // Status Colors
  static const Color openGreen = Color(0xFF16A34A);
  static const Color closedRed = Color(0xFFDC2626);
  static const Color warningOrange = Color(0xFFF59E0B);

  // Glassmorphism Navigation Colors
  static const Color emergency112 = Color(0xFFE30E13);
  static const Color hospitalActive = Color(0xFF46B3AE);
  static const Color pharmacyActive = Color(0xFFA40211);
  static const Color symptomActive = Color(0xFF2A7A82);
  static const Color menuActive = Color(0xFF5C1D24);
  static const Color iconInactive = Color(0xFF8E8E93);
  static Color get glassBackground => isDark ? const Color(0xB31C1C1E) : const Color(0xB3FFFFFF);

  // Star Rating
  static const Color starGold = Color(0xFFFBBF24);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pharmacyGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF00897B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 1.0],
  );

  // Map background placeholder
  static Color get mapBackground => isDark ? const Color(0xFF1A2232) : const Color(0xFFE8F4FD);

  // Shimmer Loading
  static Color get shimmerBase => isDark ? const Color(0xFF242F48) : const Color(0xFFE0E0E0);
  static Color get shimmerHighlight => isDark ? const Color(0xFF2E3D5E) : const Color(0xFFF5F5F5);
}
