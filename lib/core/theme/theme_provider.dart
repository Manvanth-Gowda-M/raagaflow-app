import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/hive_service.dart';
import 'app_colors.dart';

enum AppThemeMode {
  cherryBlossom,
  seoulNight,
  hanokSerenity,
  cloudMorning,
  midnightInk,
}

class ThemeColorsConfig {
  final Color background;
  final Color surface;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceDim;
  final Color surfaceContainerLowest;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color tertiary;
  final Color like;
  final LinearGradient accentGradient;
  final LinearGradient premiumGradient;
  final LinearGradient surfaceGradient;

  const ThemeColorsConfig({
    required this.background,
    required this.surface,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceDim,
    required this.surfaceContainerLowest,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.tertiary,
    required this.like,
    required this.accentGradient,
    required this.premiumGradient,
    required this.surfaceGradient,
  });
}

final themeConfigs = <AppThemeMode, ThemeColorsConfig>{
  AppThemeMode.cherryBlossom: const ThemeColorsConfig(
    background: Color(0xFFF7F4F1),
    surface: Color(0xFFFDFBF9),
    surfaceContainerLow: Color(0xFFF3ECE6),
    surfaceContainerHigh: Color(0xFFEFE7E3),
    surfaceContainerHighest: Color(0xFFE5DCD7),
    surfaceDim: Color(0xFFF7F4F1),
    surfaceContainerLowest: Color(0xFFFFFDFB),
    divider: Color(0xFFDFD4CE),
    textPrimary: Color(0xFF2A2523),
    textSecondary: Color(0xFF7D736D),
    textHint: Color(0xFFA59B95),
    accent: Color(0xFFD9AAA2),
    accentLight: Color(0xFFE5C3BE),
    accentDark: Color(0xFFC88E85),
    primary: Color(0xFFD9AAA2),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFC88E85),
    tertiary: Color(0xFF8FA79B),
    like: Color(0xFFC88E85),
    accentGradient: LinearGradient(
      colors: [Color(0xFFD9AAA2), Color(0xFFC88E85)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    premiumGradient: LinearGradient(
      colors: [Color(0xFFD9AAA2), Color(0xFFC88E85), Color(0xFF8FA79B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    surfaceGradient: LinearGradient(
      colors: [Color(0xFFFDFBF9), Color(0xFFF7F4F1)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  AppThemeMode.seoulNight: const ThemeColorsConfig(
    background: Color(0xFF0D1020),
    surface: Color(0xFF151A2E),
    surfaceContainerLow: Color(0xFF121626),
    surfaceContainerHigh: Color(0xFF1C223D),
    surfaceContainerHighest: Color(0xFF242C4F),
    surfaceDim: Color(0xFF0D1020),
    surfaceContainerLowest: Color(0xFF080A14),
    divider: Color(0xFF2B3356),
    textPrimary: Color(0xFFF7F3F0),
    textSecondary: Color(0xFFAAA8B5),
    textHint: Color(0xFF6F6E80),
    accent: Color(0xFFE48BA7),
    accentLight: Color(0xFFF3BDCE),
    accentDark: Color(0xFFD36E90),
    primary: Color(0xFFE48BA7),
    onPrimary: Color(0xFF151A2E),
    secondary: Color(0xFFD36E90),
    tertiary: Color(0xFF7CAFB7),
    like: Color(0xFFD36E90),
    accentGradient: LinearGradient(
      colors: [Color(0xFFE48BA7), Color(0xFFD36E90)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    premiumGradient: LinearGradient(
      colors: [Color(0xFFE48BA7), Color(0xFFD36E90), Color(0xFF7CAFB7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    surfaceGradient: LinearGradient(
      colors: [Color(0xFF151A2E), Color(0xFF0D1020)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  AppThemeMode.hanokSerenity: const ThemeColorsConfig(
    background: Color(0xFFF4EFEA),
    surface: Color(0xFFFAF6F2),
    surfaceContainerLow: Color(0xFFEFE8E0),
    surfaceContainerHigh: Color(0xFFE8DFD7),
    surfaceContainerHighest: Color(0xFFDCD1C7),
    surfaceDim: Color(0xFFF4EFEA),
    surfaceContainerLowest: Color(0xFFFCFAF7),
    divider: Color(0xFFD4C7BB),
    textPrimary: Color(0xFF3E352F),
    textSecondary: Color(0xFF8E8278),
    textHint: Color(0xFFB3A89F),
    accent: Color(0xFFA78B71),
    accentLight: Color(0xFFCBB7A3),
    accentDark: Color(0xFF876C55),
    primary: Color(0xFFA78B71),
    onPrimary: Color(0xFFFAF6F2),
    secondary: Color(0xFF876C55),
    tertiary: Color(0xFF969A85),
    like: Color(0xFF876C55),
    accentGradient: LinearGradient(
      colors: [Color(0xFFA78B71), Color(0xFF876C55)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    premiumGradient: LinearGradient(
      colors: [Color(0xFFA78B71), Color(0xFF876C55), Color(0xFF969A85)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    surfaceGradient: LinearGradient(
      colors: [Color(0xFFFAF6F2), Color(0xFFF4EFEA)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  AppThemeMode.cloudMorning: const ThemeColorsConfig(
    background: Color(0xFFECEFF1),
    surface: Color(0xFFF5F7F8),
    surfaceContainerLow: Color(0xFFE2E6E9),
    surfaceContainerHigh: Color(0xFFDFE4E7),
    surfaceContainerHighest: Color(0xFFD2D8DC),
    surfaceDim: Color(0xFFECEFF1),
    surfaceContainerLowest: Color(0xFFF9FAFA),
    divider: Color(0xFFCFD8DC),
    textPrimary: Color(0xFF263238),
    textSecondary: Color(0xFF607D8B),
    textHint: Color(0xFF90A4AE),
    accent: Color(0xFF78909C),
    accentLight: Color(0xFFB0BEC5),
    accentDark: Color(0xFF546E7A),
    primary: Color(0xFF78909C),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF546E7A),
    tertiary: Color(0xFF90A4AE),
    like: Color(0xFF546E7A),
    accentGradient: LinearGradient(
      colors: [Color(0xFF78909C), Color(0xFF546E7A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    premiumGradient: LinearGradient(
      colors: [Color(0xFF78909C), Color(0xFF546E7A), Color(0xFF90A4AE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    surfaceGradient: LinearGradient(
      colors: [Color(0xFFF5F7F8), Color(0xFFECEFF1)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  AppThemeMode.midnightInk: const ThemeColorsConfig(
    background: Color(0xFF121212),
    surface: Color(0xFF1C1C1C),
    surfaceContainerLow: Color(0xFF171717),
    surfaceContainerHigh: Color(0xFF262626),
    surfaceContainerHighest: Color(0xFF333333),
    surfaceDim: Color(0xFF121212),
    surfaceContainerLowest: Color(0xFF0A0A0A),
    divider: Color(0xFF3A3A3C),
    textPrimary: Color(0xFFE5E5E5),
    textSecondary: Color(0xFF8E8E93),
    textHint: Color(0xFF636366),
    accent: Color(0xFFFFFFFF),
    accentLight: Color(0xFFD1D1D6),
    accentDark: Color(0xFFAEAEB2),
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF121212),
    secondary: Color(0xFFD1D1D6),
    tertiary: Color(0xFF8E8E93),
    like: Color(0xFFE5E5E5),
    accentGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFF8E8E93)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    premiumGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFF8E8E93), Color(0xFF333333)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    surfaceGradient: LinearGradient(
      colors: [Color(0xFF1C1C1C), Color(0xFF121212)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
};

class ThemeNotifier extends Notifier<AppThemeMode> {
  static const _themeKey = 'selected_theme_mode';

  @override
  AppThemeMode build() {
    final settingsBox = HiveService.settings;
    final savedThemeIndex = settingsBox.get(_themeKey, defaultValue: null);
    if (savedThemeIndex != null && savedThemeIndex is int && savedThemeIndex >= 0 && savedThemeIndex < AppThemeMode.values.length) {
      final mode = AppThemeMode.values[savedThemeIndex];
      _applyThemeToAppColors(mode);
      return mode;
    }
    // Default to Cherry Blossom (light mode) for a clean, welcoming first experience
    _applyThemeToAppColors(AppThemeMode.cherryBlossom);
    return AppThemeMode.cherryBlossom;
  }

  void setTheme(AppThemeMode mode) {
    state = mode;
    HiveService.settings.put(_themeKey, mode.index);
    _applyThemeToAppColors(mode);
  }

  void _applyThemeToAppColors(AppThemeMode mode) {
    final cfg = themeConfigs[mode] ?? themeConfigs[AppThemeMode.seoulNight]!;
    AppColors.updateThemeColors(cfg);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(() {
  return ThemeNotifier();
});
