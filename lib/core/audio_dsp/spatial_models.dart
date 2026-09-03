import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Motion Trajectory Types for 3D Sound Movement.
enum TrajectoryType {
  orbit,           // Smooth circular 360° orbit
  vocalBeatSplit,  // Asymmetric Vocal (Left) & Beat (Right) dual cross-swirl
  figureEight,     // Lemniscate of Bernoulli
  dreamSpace,      // Lissajous asynchronous harmonic flow
  cinematic,       // Ultra-slow evolving wide spatial curve
  manual,          // Interactive touch-and-drag 3D coordinate control
}

extension TrajectoryTypeExtension on TrajectoryType {
  String get label => switch (this) {
    TrajectoryType.orbit          => '360° Orbit',
    TrajectoryType.vocalBeatSplit => 'Vocal / Beat Split',
    TrajectoryType.figureEight    => 'Figure-8',
    TrajectoryType.dreamSpace     => 'Dream Flow',
    TrajectoryType.cinematic      => 'Cinematic',
    TrajectoryType.manual         => 'Manual Radar',
  };
}

/// Quality Modes for DSP Processing.
enum QualityMode {
  standard,
  highQuality,
  ultra,
}

extension QualityModeExtension on QualityMode {
  String get label => switch (this) {
    QualityMode.standard    => 'Standard',
    QualityMode.highQuality => 'High Quality',
    QualityMode.ultra       => 'Ultra',
  };
}

/// Spatial Mode: Basic (simplified 1-tap presets) vs Advanced.
enum ControlMode {
  basic,
  advanced,
}

/// Speed Presets for quick selection.
enum MovementSpeedPreset {
  slow,
  medium,
  fast,
  custom,
}

extension MovementSpeedPresetExtension on MovementSpeedPreset {
  String get label => switch (this) {
    MovementSpeedPreset.slow   => 'Slow',
    MovementSpeedPreset.medium => 'Medium',
    MovementSpeedPreset.fast   => 'Fast',
    MovementSpeedPreset.custom => 'Custom',
  };

  /// Radians per second of motion.
  double get radiansPerSecond => switch (this) {
    MovementSpeedPreset.slow   => 0.35,  // ~18.0s per full rotation
    MovementSpeedPreset.medium => 0.75,  // ~8.4s per full rotation
    MovementSpeedPreset.fast   => 1.40,  // ~4.5s per full rotation
    MovementSpeedPreset.custom => 0.75,
  };
}

/// Depth Presets for quick selection.
enum DepthPreset {
  near,
  balanced,
  far,
  custom,
}

extension DepthPresetExtension on DepthPreset {
  String get label => switch (this) {
    DepthPreset.near     => 'Near',
    DepthPreset.balanced => 'Balanced',
    DepthPreset.far      => 'Far',
    DepthPreset.custom   => 'Custom',
  };

  double get depthValue => switch (this) {
    DepthPreset.near     => 0.35,
    DepthPreset.balanced => 0.65,
    DepthPreset.far      => 1.00,
    DepthPreset.custom   => 0.65,
  };
}

/// Simplified, High-Impact 8D Presets.
enum SpatialPresetType {
  vocalBeatSplit,  // 🎤 Left Vocals & Right Beats (Asymmetric dual cross-movement)
  classic8D,       // 🎧 Classic 360° Left-to-Right Orbit
  deep8D,          // 🌌 Deep 8D Concert Hall with heavy bass
  midnight,        // 🌙 Midnight Lofi slow relaxing sway
  fullOrbit,       // ⚡ Fast 8D Swirl (Intense rotation)
  dreamSpace,      // ☁️ Ethereal floating ambient
  cinematic,       // 🎬 Grand wide movie space
  vocalFocus,      // 🎙️ Vocal Anchor
  ultraWide,       // 🔊 Maximum Stereo Width
  gentle,          // 🍃 Gentle Micro-movement
}

extension SpatialPresetTypeExtension on SpatialPresetType {
  String get displayName => switch (this) {
    SpatialPresetType.vocalBeatSplit => 'Vocal & Beat Split',
    SpatialPresetType.classic8D      => 'Classic 8D Orbit',
    SpatialPresetType.deep8D         => 'Deep 8D Concert',
    SpatialPresetType.midnight       => 'Midnight Lofi',
    SpatialPresetType.fullOrbit      => 'Fast 8D Swirl',
    SpatialPresetType.dreamSpace     => 'Dream Space',
    SpatialPresetType.cinematic      => 'Cinematic 3D',
    SpatialPresetType.vocalFocus     => 'Vocal Focus',
    SpatialPresetType.ultraWide      => 'Ultra Wide',
    SpatialPresetType.gentle         => 'Gentle 8D',
  };

  IconData get icon => switch (this) {
    SpatialPresetType.vocalBeatSplit => Icons.spatial_audio_rounded,
    SpatialPresetType.classic8D      => Icons.headphones_rounded,
    SpatialPresetType.deep8D         => Icons.speaker_group_rounded,
    SpatialPresetType.midnight       => Icons.nightlight_round,
    SpatialPresetType.fullOrbit      => Icons.speed_rounded,
    SpatialPresetType.dreamSpace     => Icons.blur_on_rounded,
    SpatialPresetType.cinematic      => Icons.theaters_rounded,
    SpatialPresetType.vocalFocus     => Icons.mic_rounded,
    SpatialPresetType.ultraWide      => Icons.surround_sound_rounded,
    SpatialPresetType.gentle         => Icons.waves_rounded,
  };

  String get tag => switch (this) {
    SpatialPresetType.vocalBeatSplit => 'Popular · Left Vocals / Right Beats',
    SpatialPresetType.classic8D      => 'Classic · 360° Left to Right',
    SpatialPresetType.deep8D         => 'Club Bass · Live Concert Space',
    SpatialPresetType.midnight       => 'Relaxing · Warm Ear-to-Ear Drift',
    SpatialPresetType.fullOrbit      => 'Intense · High Speed 8D Rotation',
    SpatialPresetType.dreamSpace     => 'Ethereal Ambient Float',
    SpatialPresetType.cinematic      => 'Expansive Soundstage',
    SpatialPresetType.vocalFocus     => 'Clear Center Vocals',
    SpatialPresetType.ultraWide      => 'Maximum Stereo Width',
    SpatialPresetType.gentle         => 'Subtle Micro-Movement',
  };

  String get description => switch (this) {
    SpatialPresetType.vocalBeatSplit => 'Vocals in left ear, beats in right ear, smoothly crossing over and rotating through your head!',
    SpatialPresetType.classic8D      => 'Smooth continuous 360° circular movement around your ears from Left to Right.',
    SpatialPresetType.deep8D         => 'Deep spatial immersion, rich concert hall reverb, and punchy sub-bass.',
    SpatialPresetType.midnight       => 'Slow, cozy, intimate binaural sway perfect for lofi, night listening, and relaxation.',
    SpatialPresetType.fullOrbit      => 'Fast-paced, high-energy 8D circular swirl for EDM, dance, and workout tracks.',
    SpatialPresetType.dreamSpace     => 'Soft wide ambience with floating ethereal Lissajous motion.',
    SpatialPresetType.cinematic      => 'Epic expansive soundstage with majestic 60-second orbit.',
    SpatialPresetType.vocalFocus     => '85% center vocal protection with surrounding instrumentals.',
    SpatialPresetType.ultraWide      => 'Maximum stereo widening with active phase-guard safety.',
    SpatialPresetType.gentle         => 'Subtle acoustic micro-movements for relaxed focused listening.',
  };

  SpatialParameters get defaultParameters => switch (this) {
    SpatialPresetType.vocalBeatSplit => const SpatialParameters(
      intensity: 0.95,
      speedPreset: MovementSpeedPreset.medium,
      speedRadPerSec: 0.85,
      depthPreset: DepthPreset.far,
      depth: 0.95,
      orbitRadius: 1.45,
      stereoWidth: 1.80,
      centerProtection: 0.10,
      bassCrossoverHz: 120.0,
      reverbMix: 0.30,
      delayMix: 0.20,
      trajectory: TrajectoryType.vocalBeatSplit,
    ),
    SpatialPresetType.classic8D => const SpatialParameters(
      intensity: 0.95,
      speedPreset: MovementSpeedPreset.medium,
      speedRadPerSec: 0.75,
      depthPreset: DepthPreset.far,
      depth: 0.90,
      orbitRadius: 1.40,
      stereoWidth: 1.70,
      centerProtection: 0.30,
      bassCrossoverHz: 120.0,
      reverbMix: 0.30,
      delayMix: 0.18,
      trajectory: TrajectoryType.orbit,
    ),
    SpatialPresetType.deep8D => const SpatialParameters(
      intensity: 1.00,
      speedPreset: MovementSpeedPreset.medium,
      speedRadPerSec: 0.80,
      depthPreset: DepthPreset.far,
      depth: 1.00,
      orbitRadius: 1.50,
      stereoWidth: 1.90,
      centerProtection: 0.25,
      bassCrossoverHz: 130.0,
      reverbMix: 0.45,
      delayMix: 0.25,
      trajectory: TrajectoryType.orbit,
    ),
    SpatialPresetType.midnight => const SpatialParameters(
      intensity: 0.85,
      speedPreset: MovementSpeedPreset.slow,
      speedRadPerSec: 0.30,
      depthPreset: DepthPreset.balanced,
      depth: 0.85,
      orbitRadius: 1.25,
      stereoWidth: 1.50,
      centerProtection: 0.40,
      bassCrossoverHz: 150.0,
      reverbMix: 0.35,
      delayMix: 0.15,
      trajectory: TrajectoryType.figureEight,
    ),
    SpatialPresetType.fullOrbit => const SpatialParameters(
      intensity: 1.00,
      speedPreset: MovementSpeedPreset.fast,
      speedRadPerSec: 1.40,
      depthPreset: DepthPreset.far,
      depth: 0.95,
      orbitRadius: 1.45,
      stereoWidth: 1.75,
      centerProtection: 0.20,
      bassCrossoverHz: 120.0,
      reverbMix: 0.30,
      delayMix: 0.15,
      trajectory: TrajectoryType.orbit,
    ),
    SpatialPresetType.dreamSpace => const SpatialParameters(
      intensity: 0.80,
      speedPreset: MovementSpeedPreset.slow,
      speedRadPerSec: 0.40,
      depthPreset: DepthPreset.balanced,
      depth: 0.75,
      orbitRadius: 0.90,
      stereoWidth: 1.45,
      centerProtection: 0.55,
      bassCrossoverHz: 110.0,
      reverbMix: 0.40,
      delayMix: 0.25,
      trajectory: TrajectoryType.dreamSpace,
    ),
    SpatialPresetType.cinematic => const SpatialParameters(
      intensity: 0.90,
      speedPreset: MovementSpeedPreset.slow,
      speedRadPerSec: 0.18,
      depthPreset: DepthPreset.far,
      depth: 0.95,
      orbitRadius: 1.10,
      stereoWidth: 1.70,
      centerProtection: 0.50,
      bassCrossoverHz: 100.0,
      reverbMix: 0.45,
      delayMix: 0.22,
      trajectory: TrajectoryType.cinematic,
    ),
    SpatialPresetType.vocalFocus => const SpatialParameters(
      intensity: 0.70,
      speedPreset: MovementSpeedPreset.medium,
      speedRadPerSec: 0.60,
      depthPreset: DepthPreset.near,
      depth: 0.45,
      orbitRadius: 0.80,
      stereoWidth: 1.25,
      centerProtection: 0.88,
      bassCrossoverHz: 130.0,
      reverbMix: 0.15,
      delayMix: 0.08,
      trajectory: TrajectoryType.orbit,
    ),
    SpatialPresetType.ultraWide => const SpatialParameters(
      intensity: 0.90,
      speedPreset: MovementSpeedPreset.medium,
      speedRadPerSec: 0.70,
      depthPreset: DepthPreset.balanced,
      depth: 0.65,
      orbitRadius: 1.15,
      stereoWidth: 1.90,
      centerProtection: 0.45,
      bassCrossoverHz: 140.0,
      reverbMix: 0.25,
      delayMix: 0.18,
      trajectory: TrajectoryType.orbit,
    ),
    SpatialPresetType.gentle => const SpatialParameters(
      intensity: 0.45,
      speedPreset: MovementSpeedPreset.slow,
      speedRadPerSec: 0.25,
      depthPreset: DepthPreset.near,
      depth: 0.35,
      orbitRadius: 0.55,
      stereoWidth: 1.10,
      centerProtection: 0.80,
      bassCrossoverHz: 150.0,
      reverbMix: 0.12,
      delayMix: 0.05,
      trajectory: TrajectoryType.dreamSpace,
    ),
  };
}

/// Parameters for 3D Spatial Audio Engine.
@immutable
class SpatialParameters {
  final double intensity;            // 0.0 to 1.0 (Master 8D intensity)
  final MovementSpeedPreset speedPreset;
  final double speedRadPerSec;       // Radians / second
  final DepthPreset depthPreset;
  final double depth;                // 0.0 (near) to 1.0 (deep)
  final double orbitRadius;          // 0.0 to 1.5
  final double stereoWidth;          // 0.0 (mono) to 2.0 (ultra-wide)
  final double centerProtection;     // 0.0 (free) to 1.0 (rock-solid mono center)
  final double bassCrossoverHz;      // 60.0 to 200.0 Hz
  final double reverbMix;            // 0.0 to 1.0
  final double delayMix;             // 0.0 to 1.0
  final TrajectoryType trajectory;
  final QualityMode qualityMode;

  const SpatialParameters({
    this.intensity = 0.90,
    this.speedPreset = MovementSpeedPreset.medium,
    this.speedRadPerSec = 0.85,
    this.depthPreset = DepthPreset.balanced,
    this.depth = 0.75,
    this.orbitRadius = 1.05,
    this.stereoWidth = 1.50,
    this.centerProtection = 0.20,
    this.bassCrossoverHz = 120.0,
    this.reverbMix = 0.20,
    this.delayMix = 0.15,
    this.trajectory = TrajectoryType.vocalBeatSplit,
    this.qualityMode = QualityMode.highQuality,
  });

  SpatialParameters copyWith({
    double? intensity,
    MovementSpeedPreset? speedPreset,
    double? speedRadPerSec,
    DepthPreset? depthPreset,
    double? depth,
    double? orbitRadius,
    double? stereoWidth,
    double? centerProtection,
    double? bassCrossoverHz,
    double? reverbMix,
    double? delayMix,
    TrajectoryType? trajectory,
    QualityMode? qualityMode,
  }) {
    return SpatialParameters(
      intensity: intensity ?? this.intensity,
      speedPreset: speedPreset ?? this.speedPreset,
      speedRadPerSec: speedRadPerSec ?? this.speedRadPerSec,
      depthPreset: depthPreset ?? this.depthPreset,
      depth: depth ?? this.depth,
      orbitRadius: orbitRadius ?? this.orbitRadius,
      stereoWidth: stereoWidth ?? this.stereoWidth,
      centerProtection: centerProtection ?? this.centerProtection,
      bassCrossoverHz: bassCrossoverHz ?? this.bassCrossoverHz,
      reverbMix: reverbMix ?? this.reverbMix,
      delayMix: delayMix ?? this.delayMix,
      trajectory: trajectory ?? this.trajectory,
      qualityMode: qualityMode ?? this.qualityMode,
    );
  }
}

/// Live Telemetry & Diagnostic Metrics for Spatial Engine.
@immutable
class SpatialDiagnosticMetrics {
  final double x;
  final double y;
  final double z;
  final double azimuthDegrees;
  final double distance;
  final double stereoCorrelation;
  final double effectiveWidth;
  final bool isPhaseCompensated;
  final double peakDb;

  const SpatialDiagnosticMetrics({
    this.x = 0.0,
    this.y = 1.0,
    this.z = 0.0,
    this.azimuthDegrees = 0.0,
    this.distance = 1.0,
    this.stereoCorrelation = 0.85,
    this.effectiveWidth = 1.30,
    this.isPhaseCompensated = false,
    this.peakDb = -0.5,
  });
}
