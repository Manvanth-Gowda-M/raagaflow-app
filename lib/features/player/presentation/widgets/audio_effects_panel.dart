import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/audio_effects_provider.dart';
import '../../../../core/theme/app_colors.dart';

class AudioEffectsPanel extends ConsumerWidget {
  const AudioEffectsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(audioEffectsProvider);
    final n = ref.read(audioEffectsProvider.notifier);

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.background,   // fully opaque — no bleed-through
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.15))),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Drag Handle ──────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Header ────────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Audio Effects',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            )),
                          Text('Professional DSP · Wear headphones for 8D',
                            style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── 8D Audio ─────────────────────────────────────────────
                  _EffectCard(
                    icon: Icons.headphones_rounded,
                    title: '8D Audio',
                    subtitle: '🎧 Flagship · 360° binaural rotation · Use headphones',
                    isActive: s.is8DEnabled,
                    intensity: s.intensity8D,
                    onToggle: () {
                      n.toggle8D();
                      if (!s.is8DEnabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.headphones, color: Colors.black, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '🎧 Wear headphones for the full 8D experience!',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.accent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            duration: const Duration(seconds: 4),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    onIntensityChange: (i) => n.set8DIntensity(i),
                  ),

                  // ─── Bass Boost ────────────────────────────────────────────
                  _EffectCard(
                    icon: Icons.speaker_rounded,
                    title: 'Bass Boost',
                    subtitle: 'Deep sub-bass · Punchy kick drums · Club energy',
                    isActive: s.isBassBoostEnabled,
                    intensity: s.intensityBass,
                    onToggle: () => n.toggleBassBoost(),
                    onIntensityChange: (i) => n.setBassIntensity(i),
                  ),

                  // ─── Surround Sound ────────────────────────────────────────
                  _EffectCard(
                    icon: Icons.surround_sound_rounded,
                    title: 'Surround Sound',
                    subtitle: 'Virtual 3D space · Wider stereo field',
                    isActive: s.isSurroundEnabled,
                    intensity: s.intensitySurround,
                    onToggle: () => n.toggleSurround(),
                    onIntensityChange: (i) => n.setSurroundIntensity(i),
                  ),

                  // ─── Vocal Boost ───────────────────────────────────────────
                  _EffectCard(
                    icon: Icons.mic_rounded,
                    title: 'Vocal Boost',
                    subtitle: 'Crystal clear vocals · Lyrics in focus',
                    isActive: s.isVocalBoostEnabled,
                    intensity: s.intensityVocal,
                    onToggle: () => n.toggleVocalBoost(),
                    onIntensityChange: (i) => n.setVocalIntensity(i),
                  ),

                  // ─── Concert Hall Reverb ───────────────────────────────────
                  _EffectCard(
                    icon: Icons.waves_rounded,
                    title: 'Concert Hall',
                    subtitle: 'Live performance ambience · Large hall reverb',
                    isActive: s.isReverbEnabled,
                    intensity: null, // Reverb is on/off only
                    onToggle: () => n.toggleReverb(),
                    onIntensityChange: null,
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Effect Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _EffectCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final EffectIntensity? intensity;
  final VoidCallback onToggle;
  final void Function(EffectIntensity)? onIntensityChange;

  const _EffectCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onToggle,
    this.intensity,
    this.onIntensityChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.45)
                : AppColors.divider.withValues(alpha: 0.2),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Main row ──
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icon pill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: isActive ? AppColors.accentGradient : null,
                        color: isActive ? null : AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isActive ? Colors.black : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title & subtitle
                    Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: isActive ? AppColors.accent : AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(color: AppColors.textHint, fontSize: 11),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    // Toggle switch
                    Switch(
                      value: isActive,
                      onChanged: (_) => onToggle(),
                      activeThumbColor: Colors.black,
                      activeTrackColor: AppColors.accent,
                      inactiveThumbColor: AppColors.textHint,
                      inactiveTrackColor: AppColors.surfaceContainerHigh,
                    ),
                  ],
                ),
              ),
            ),

            // ── Intensity picker (only shown when active and intensity is not null) ──
            if (isActive && intensity != null && onIntensityChange != null) ...[
              Divider(height: 1, color: AppColors.accent.withValues(alpha: 0.2), indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    Text('Strength:', style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: EffectIntensity.values.map((level) {
                          final isSelected = intensity == level;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => onIntensityChange!(level),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? AppColors.accentGradient : null,
                                  color: isSelected ? null : AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected ? null : Border.all(
                                    color: AppColors.divider.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  level.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.black : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
