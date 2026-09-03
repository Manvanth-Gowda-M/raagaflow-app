import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/spatial_audio_provider.dart';
import 'spatial_visualizer_radar.dart';

/// Clean, Simple, Next-Generation 8D Audio Control Sheet.
class SpatialAudioSheet extends ConsumerWidget {
  const SpatialAudioSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spatialState = ref.watch(spatialAudioProvider);
    final notifier = ref.read(spatialAudioProvider.notifier);
    final params = spatialState.params;
    final isEnabled = spatialState.isEnabled;
    final isBypassed = spatialState.isBypassed;

    // Top 5 most exciting & distinct 8D effects
    final mainPresets = [
      SpatialPresetType.vocalBeatSplit,
      SpatialPresetType.classic8D,
      SpatialPresetType.deep8D,
      SpatialPresetType.midnight,
      SpatialPresetType.fullOrbit,
    ];

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.15))),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Drag Handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Header: 8D Audio Toggle ──────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isEnabled ? AppColors.accentGradient : null,
                      color: isEnabled ? null : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.headphones_rounded,
                      color: isEnabled ? Colors.black : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '8D Spatial Audio',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isEnabled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isBypassed ? Colors.orange.withValues(alpha: 0.2) : AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isBypassed ? Colors.orange.withValues(alpha: 0.6) : AppColors.accent.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  isBypassed ? 'ORIGINAL' : 'ACTIVE',
                                  style: TextStyle(
                                    color: isBypassed ? Colors.orange : AppColors.accent,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '🎧 Wear headphones for the 360° sound effect',
                          style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (_) => notifier.toggle8D(),
                    activeThumbColor: Colors.black,
                    activeTrackColor: AppColors.accent,
                    inactiveThumbColor: AppColors.textHint,
                    inactiveTrackColor: AppColors.surfaceContainerHigh,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ─── A/B Comparison Toggle (Instant Before / After) ───────────
              if (isEnabled) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => notifier.setBypass(true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isBypassed ? AppColors.surfaceContainerHighest : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'ORIGINAL STEREO',
                                style: TextStyle(
                                  color: isBypassed ? AppColors.textPrimary : AppColors.textHint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => notifier.setBypass(false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: !isBypassed ? AppColors.accentGradient : null,
                              color: !isBypassed ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '8D SPATIAL EFFECT',
                                style: TextStyle(
                                  color: !isBypassed ? Colors.black : AppColors.textHint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ─── 3D Soundstage Visualizer ─────────────────────────────────
              const SpatialVisualizerRadar(size: 190),
              const SizedBox(height: 18),

              // ─── 1-Tap Effect Options ─────────────────────────────────────
              Text(
                'CHOOSE 8D EFFECT',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              ...mainPresets.map((preset) {
                final isSelected = spatialState.activePreset == preset && isEnabled;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      if (!isEnabled) notifier.toggle8D();
                      notifier.selectPreset(preset);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.6)
                              : AppColors.divider.withValues(alpha: 0.18),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withValues(alpha: 0.2)
                                  : AppColors.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              preset.icon,
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      preset.displayName,
                                      style: TextStyle(
                                        color: isSelected ? AppColors.accent : AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (preset == SpatialPresetType.vocalBeatSplit) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '🔥 POPULAR',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  preset.description,
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20)
                          else
                            Icon(Icons.circle_outlined, color: AppColors.textHint.withValues(alpha: 0.3), size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // ─── Simple 8D Strength Slider ────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '8D Effect Strength',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${(params.intensity * 100).toInt()}%',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.surfaceContainerHighest,
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withValues(alpha: 0.15),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: params.intensity.clamp(0.0, 1.0),
                      onChanged: isEnabled ? (v) => notifier.setIntensity(v) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
