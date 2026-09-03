import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../core/theme/app_colors.dart';
import 'player_provider.dart';

class DynamicPaletteColors {
  final Color dominant;
  final Color secondary;
  final Color accent;
  final Color backgroundGradientTop;
  final Color backgroundGradientBottom;

  const DynamicPaletteColors({
    required this.dominant,
    required this.secondary,
    required this.accent,
    required this.backgroundGradientTop,
    required this.backgroundGradientBottom,
  });

  factory DynamicPaletteColors.fallback() {
    return DynamicPaletteColors(
      dominant: AppColors.surfaceContainerLow,
      secondary: AppColors.accent.withValues(alpha: 0.3),
      accent: AppColors.accent,
      backgroundGradientTop: AppColors.surfaceContainerLow,
      backgroundGradientBottom: AppColors.background,
    );
  }
}

class DynamicPaletteNotifier extends StateNotifier<DynamicPaletteColors> {
  final Ref _ref;
  final Map<String, DynamicPaletteColors> _cache = {};
  String? _lastLoadedUrl;

  DynamicPaletteNotifier(this._ref) : super(DynamicPaletteColors.fallback()) {
    _ref.listen(playerProvider.select((s) => s.currentTrack?.imageUrl), (prev, next) {
      if (next != null && next.isNotEmpty && next != _lastLoadedUrl) {
        _extractColors(next);
      }
    });
  }

  Future<void> _extractColors(String imageUrl) async {
    _lastLoadedUrl = imageUrl;

    if (_cache.containsKey(imageUrl)) {
      state = _cache[imageUrl]!;
      return;
    }

    try {
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 16,
        size: const Size(64, 64), // Resize for fast color extraction
      ).timeout(const Duration(seconds: 4));

      final rawAccent = palette.vibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.dominantColor?.color ??
          AppColors.accent;

      // Boost saturation and optimal lightness so accent is always vivid and energetic
      final accentHsl = HSLColor.fromColor(rawAccent);
      final accent = accentHsl
          .withSaturation(accentHsl.saturation.clamp(0.65, 0.95))
          .withLightness(accentHsl.lightness.clamp(0.55, 0.72))
          .toColor();

      final dominant = palette.darkVibrantColor?.color ??
          palette.dominantColor?.color ??
          const Color(0xFF14161F);

      final secondary = palette.mutedColor?.color ??
          palette.lightMutedColor?.color ??
          accent.withValues(alpha: 0.6);

      // Deep luxury OLED obsidian canvas with subtle atmospheric color tint
      final topGradient = Color.alphaBlend(
        accent.withValues(alpha: 0.22),
        const Color(0xFF0F1118),
      );
      const bottomGradient = Color(0xFF07080C);

      final colors = DynamicPaletteColors(
        dominant: dominant,
        secondary: secondary,
        accent: accent,
        backgroundGradientTop: topGradient,
        backgroundGradientBottom: bottomGradient,
      );

      _cache[imageUrl] = colors;
      if (_lastLoadedUrl == imageUrl) {
        state = colors;
      }
    } catch (_) {
      // Graceful fallback
      state = DynamicPaletteColors.fallback();
    }
  }
}

final dynamicPaletteProvider =
    StateNotifierProvider<DynamicPaletteNotifier, DynamicPaletteColors>((ref) {
  return DynamicPaletteNotifier(ref);
});
