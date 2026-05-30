import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/visualizer_provider.dart';
class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final currentVisualizer = ref.watch(visualizerProvider);
    final themeItems = [
      {
        'mode': AppThemeMode.seoulNight,
        'name': 'Seoul Night',
        'desc': 'Warm Han River neon glow',
        'bg': const Color(0xFF0D1020),
        'accent': const Color(0xFFE48BA7),
        'primary': const Color(0xFF8BA4E4),
        'surface': const Color(0xFF161A30),
        'isDark': true
      },
      {
        'mode': AppThemeMode.cherryBlossom,
        'name': 'Cherry Blossom',
        'desc': 'Soft spring flowers & cream',
        'bg': const Color(0xFFF7F4F1),
        'accent': const Color(0xFFD9AAA2),
        'primary': const Color(0xFF7C9C95),
        'surface': const Color(0xFFEFECE9),
        'isDark': false
      },
      {
        'mode': AppThemeMode.hanokSerenity,
        'name': 'Hanok Serenity',
        'desc': 'Slow traditional tea house wood',
        'bg': const Color(0xFFF4EFEA),
        'accent': const Color(0xFFA78B71),
        'primary': const Color(0xFF5E6F5E),
        'surface': const Color(0xFFEBE5DC),
        'isDark': false
      },
      {
        'mode': AppThemeMode.cloudMorning,
        'name': 'Cloud Morning',
        'desc': 'Misty morning mountain fog',
        'bg': const Color(0xFFECEFF1),
        'accent': const Color(0xFF78909C),
        'primary': const Color(0xFF455A64),
        'surface': const Color(0xFFCFD8DC),
        'isDark': false
      },
      {
        'mode': AppThemeMode.midnightInk,
        'name': 'Midnight Ink',
        'desc': 'Classic dynamic brush painting',
        'bg': const Color(0xFF121212),
        'accent': const Color(0xFFFFFFFF),
        'primary': const Color(0xFF888888),
        'surface': const Color(0xFF1E1E1E),
        'isDark': true
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Studio',
                      style: AppTextStyles.headline1.copyWith(
                        fontSize: 28,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Immerse RaagaFlow in a luxury Korean-inspired visual canvas.',
                      style: AppTextStyles.trackArtist.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Active Theme Indicator ───
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.accent.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.spa_rounded,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Aesthetic',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            themeItems.firstWhere((t) => t['mode'] == currentTheme)['name'] as String,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Theme Grid ───
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = themeItems[index];
                    final mode = item['mode'] as AppThemeMode;
                    final isSelected = currentTheme == mode;
                    final bg = item['bg'] as Color;
                    final primaryColor = item['primary'] as Color;
                    final accentColor = item['accent'] as Color;
                    final surfaceColor = item['surface'] as Color;
                    final isDark = item['isDark'] as bool;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(themeProvider.notifier).setTheme(mode);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : AppColors.divider.withValues(alpha: 0.15),
                              width: isSelected ? 2.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                              if (isSelected)
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.1),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFFF7F3F0)
                                            : const Color(0xFF2A2523),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['desc'] as String,
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFFF7F3F0).withValues(alpha: 0.6)
                                            : const Color(0xFF2A2523).withValues(alpha: 0.6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Visual Color Dots Bar
                                    Row(
                                      children: [
                                        _colorDot(bg, 'BG', isDark),
                                        const SizedBox(width: 8),
                                        _colorDot(surfaceColor, 'SFC', isDark),
                                        const SizedBox(width: 8),
                                        _colorDot(primaryColor, 'PRM', isDark),
                                        const SizedBox(width: 8),
                                        _colorDot(accentColor, 'ACC', isDark),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: isDark ? const Color(0xFF0D1020) : Colors.white,
                                    size: 16,
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.03),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    size: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: themeItems.length,
                ),
              ),
            ),

            // ─── Visualizer Studio ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visualizer Studio',
                      style: AppTextStyles.headline1.copyWith(
                        fontSize: 24,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose how you want to experience the music.',
                      style: AppTextStyles.trackArtist.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 180),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildVisualizerOption(
                    context,
                    ref,
                    style: VisualizerStyle.classic,
                    currentStyle: currentVisualizer,
                    title: 'Classic Art',
                    desc: 'A breathing, shadow-cast album aesthetic.',
                    icon: Icons.album_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildVisualizerOption(
                    context,
                    ref,
                    style: VisualizerStyle.vinyl,
                    currentStyle: currentVisualizer,
                    title: 'Premium Vinyl',
                    desc: 'A luxurious spinning vinyl record experience.',
                    icon: Icons.graphic_eq_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildVisualizerOption(
                    context,
                    ref,
                    style: VisualizerStyle.ambient,
                    currentStyle: currentVisualizer,
                    title: '3D Ambient Orbit',
                    desc: 'A gorgeous gyroscopic holographic ring breathing with the beat.',
                    icon: Icons.blur_circular_rounded,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorDot(Color color, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.computeLuminance() > 0.6 ? Colors.black87 : Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildVisualizerOption(
    BuildContext context,
    WidgetRef ref, {
    required VisualizerStyle style,
    required VisualizerStyle currentStyle,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final isSelected = style == currentStyle;
    return GestureDetector(
      onTap: () {
        ref.read(visualizerProvider.notifier).setStyle(style);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.divider.withValues(alpha: 0.1),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.1),
                blurRadius: 16,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
