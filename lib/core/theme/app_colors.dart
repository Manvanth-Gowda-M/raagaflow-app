import 'package:flutter/material.dart';
import 'theme_provider.dart';

class AppColors {
  // ─── Background System ───
  static Color background = const Color(0xFF0D1020);
  static Color surface = const Color(0xFF151A2E);
  static Color surfaceContainerLow = const Color(0xFF121626);
  static Color surfaceContainerHigh = const Color(0xFF1C223D);
  static Color surfaceContainerHighest = const Color(0xFF242C4F);
  static Color surfaceDim = const Color(0xFF0D1020);
  static Color surfaceContainerLowest = const Color(0xFF080A14);

  static Color divider = const Color(0xFF2B3356);

  // ─── Text System ───
  static Color textPrimary = const Color(0xFFF7F3F0);
  static Color textSecondary = const Color(0xFFAAA8B5);
  static Color textHint = const Color(0xFF6F6E80);

  // ─── Accent System (Seoul Night defaults) ───
  static Color accent = const Color(0xFFE48BA7);
  static Color accentLight = const Color(0xFFF3BDCE);
  static Color accentDark = const Color(0xFFD36E90);
  static Color primary = const Color(0xFFE48BA7);
  static Color onPrimary = const Color(0xFF151A2E);
  static Color secondary = const Color(0xFFD36E90);
  static Color tertiary = const Color(0xFF7CAFB7);
  static Color like = const Color(0xFFD36E90);

  // ─── Gradients ───
  static LinearGradient accentGradient = const LinearGradient(
    colors: [Color(0xFFE48BA7), Color(0xFFD36E90)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient premiumGradient = const LinearGradient(
    colors: [Color(0xFFE48BA7), Color(0xFFD36E90), Color(0xFF7CAFB7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient surfaceGradient = const LinearGradient(
    colors: [Color(0xFF151A2E), Color(0xFF0D1020)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Mood Gradients ───
  static const List<Color> romanticGradient = [Color(0xFFFF6B6B), Color(0xFFFF8E8E)];
  static const List<Color> focusGradient = [Color(0xFF667EEA), Color(0xFF764BA2)];
  static const List<Color> gymGradient = [Color(0xFFFF8C42), Color(0xFFFF6B6B)];
  static const List<Color> sadGradient = [Color(0xFF6C5CE7), Color(0xFF74B9FF)];
  static const List<Color> bhaktiGradient = [Color(0xFFFFB347), Color(0xFFFDA085)];
  static const List<Color> partyGradient = [Color(0xFFF093FB), Color(0xFFF5576C)];
  static const List<Color> driveGradient = [Color(0xFF4ECDC4), Color(0xFF44B09E)];
  static const List<Color> sleepGradient = [Color(0xFF2C3E50), Color(0xFF4CA1AF)];
  static const List<Color> studyGradient = [Color(0xFF667EEA), Color(0xFF4ECDC4)];
  static const List<Color> chillGradient = [Color(0xFF74B9FF), Color(0xFF55E6C1)];
  static const List<Color> rainGradient = [Color(0xFF6C5CE7), Color(0xFF74B9FF)];
  static const List<Color> morningGradient = [Color(0xFFFFB347), Color(0xFFF7DC6F)];

  // ─── Source Badges ───
  static const Color saavnBadge   = Color(0xFFD4A0B0); // rose-gold — RaagaFlow signature
  static const Color jamendoBadge = Color(0xFF7ECFA0); // soft emerald — free/open music
  static const Color pixabayBadge = Color(0xFFAA9EDA); // muted lavender — creative commons
  static const Color youtubeBadge = Color(0xFFE8A87C); // warm amber — streaming

  // ─── Update Method ───
  static void updateThemeColors(ThemeColorsConfig cfg) {
    background = cfg.background;
    surface = cfg.surface;
    surfaceContainerLow = cfg.surfaceContainerLow;
    surfaceContainerHigh = cfg.surfaceContainerHigh;
    surfaceContainerHighest = cfg.surfaceContainerHighest;
    surfaceDim = cfg.surfaceDim;
    surfaceContainerLowest = cfg.surfaceContainerLowest;
    divider = cfg.divider;
    textPrimary = cfg.textPrimary;
    textSecondary = cfg.textSecondary;
    textHint = cfg.textHint;
    accent = cfg.accent;
    accentLight = cfg.accentLight;
    accentDark = cfg.accentDark;
    primary = cfg.primary;
    onPrimary = cfg.onPrimary;
    secondary = cfg.secondary;
    tertiary = cfg.tertiary;
    like = cfg.like;
    accentGradient = cfg.accentGradient;
    premiumGradient = cfg.premiumGradient;
    surfaceGradient = cfg.surfaceGradient;
  }
}
