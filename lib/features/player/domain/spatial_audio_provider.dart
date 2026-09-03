import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/audio_dsp/spatial_math.dart';
import '../../../core/audio_dsp/spatial_models.dart';
import '../../../core/audio_dsp/spatial_trajectory_engine.dart';

export '../../../core/audio_dsp/spatial_models.dart';

/// Complete State representation for Next-Gen 8D Spatial Audio Engine.
class SpatialAudioState {
  final bool isEnabled;
  final bool isBypassed; // True when comparing Original in A/B mode
  final SpatialPresetType activePreset;
  final ControlMode controlMode;
  final SpatialParameters params;
  final SpatialDiagnosticMetrics telemetry;
  final bool isManualDragging;

  const SpatialAudioState({
    this.isEnabled = false,
    this.isBypassed = false,
    this.activePreset = SpatialPresetType.deep8D,
    this.controlMode = ControlMode.basic,
    this.params = const SpatialParameters(
      intensity: 0.85,
      speedPreset: MovementSpeedPreset.medium,
      speedRadPerSec: 0.75,
      depthPreset: DepthPreset.balanced,
      depth: 0.70,
      orbitRadius: 0.90,
      stereoWidth: 1.35,
      centerProtection: 0.60,
      bassCrossoverHz: 120.0,
      reverbMix: 0.22,
      delayMix: 0.12,
      trajectory: TrajectoryType.orbit,
      qualityMode: QualityMode.highQuality,
    ),
    this.telemetry = const SpatialDiagnosticMetrics(),
    this.isManualDragging = false,
  });

  SpatialAudioState copyWith({
    bool? isEnabled,
    bool? isBypassed,
    SpatialPresetType? activePreset,
    ControlMode? controlMode,
    SpatialParameters? params,
    SpatialDiagnosticMetrics? telemetry,
    bool? isManualDragging,
  }) {
    return SpatialAudioState(
      isEnabled: isEnabled ?? this.isEnabled,
      isBypassed: isBypassed ?? this.isBypassed,
      activePreset: activePreset ?? this.activePreset,
      controlMode: controlMode ?? this.controlMode,
      params: params ?? this.params,
      telemetry: telemetry ?? this.telemetry,
      isManualDragging: isManualDragging ?? this.isManualDragging,
    );
  }
}

/// StateNotifier orchestrating Flutter Spatial DSP calculations, Native Android AudioFX,
/// telemetry streams, and A/B comparison logic.
class SpatialAudioNotifier extends StateNotifier<SpatialAudioState> {
  static const MethodChannel _channel = MethodChannel('com.raagaflow.audio_effects');

  final SpatialTrajectoryEngine _flutterTrajectoryEngine = SpatialTrajectoryEngine();
  Timer? _flutterAnimationTicker;
  int _currentSessionId = 0;

  // Callback to audio handler for gentle volume-level depth compensation if needed
  void Function(double pan, double depth)? onPanUpdate;

  SpatialAudioNotifier() : super(const SpatialAudioState()) {
    _channel.setMethodCallHandler(_handleNativeCall);
    _loadPreferences();
    _startFlutterKinematicTicker();
  }

  @override
  void dispose() {
    _flutterAnimationTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('spatial_8d_enabled') ?? false;
      final presetIndex = prefs.getInt('spatial_8d_preset') ?? SpatialPresetType.deep8D.index;
      final preset = (presetIndex >= 0 && presetIndex < SpatialPresetType.values.length)
          ? SpatialPresetType.values[presetIndex]
          : SpatialPresetType.deep8D;

      state = state.copyWith(
        isEnabled: isEnabled,
        activePreset: preset,
        params: preset.defaultParameters,
      );

      if (isEnabled) {
        _syncToNative();
      }
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('spatial_8d_enabled', state.isEnabled);
      await prefs.setInt('spatial_8d_preset', state.activePreset.index);
    } catch (_) {}
  }

  // ─── Native Channel Handler ───────────────────────────────────────────────

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onSpatialTelemetry') {
      final args = call.arguments as Map<dynamic, dynamic>? ?? {};
      final double x = (args['x'] as num?)?.toDouble() ?? 0.0;
      final double y = (args['y'] as num?)?.toDouble() ?? 1.0;
      final double z = (args['z'] as num?)?.toDouble() ?? 0.0;
      final double azimuth = (args['azimuth'] as num?)?.toDouble() ?? 0.0;
      final double distance = (args['distance'] as num?)?.toDouble() ?? 1.0;
      final double pan = (args['pan'] as num?)?.toDouble() ?? 0.0;
      final double depth = (args['depth'] as num?)?.toDouble() ?? 0.5;

      final double currentWidth = state.params.stereoWidth;
      // Synthesize safe correlation coefficient
      final double correlation = (1.0 - (currentWidth - 1.0).abs() * 0.25).clamp(0.2, 1.0);
      final double safeWidth = SpatialMath.calculateSafeWidth(currentWidth, correlation);

      final telemetry = SpatialDiagnosticMetrics(
        x: x,
        y: y,
        z: z,
        azimuthDegrees: azimuth,
        distance: distance,
        stereoCorrelation: correlation,
        effectiveWidth: safeWidth,
        isPhaseCompensated: safeWidth < currentWidth,
        peakDb: -0.5,
      );

      state = state.copyWith(telemetry: telemetry);
      onPanUpdate?.call(pan, depth);
    }
  }

  // ─── Flutter Local Kinematic Ticker (for Web & Desktop visualizer sync) ──

  void _startFlutterKinematicTicker() {
    _flutterAnimationTicker?.cancel();
    _flutterAnimationTicker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!state.isEnabled || state.isBypassed) return;

      final pos = _flutterTrajectoryEngine.update(0.016, state.params);
      final spherical = SpatialMath.cartesianToSpherical(pos.x, pos.y, pos.z);

      // Only update local telemetry if native isn't actively overwriting it
      if (_currentSessionId == 0) {
        final double currentWidth = state.params.stereoWidth;
        final double correlation = (1.0 - (currentWidth - 1.0).abs() * 0.25).clamp(0.2, 1.0);
        final double safeWidth = SpatialMath.calculateSafeWidth(currentWidth, correlation);

        state = state.copyWith(
          telemetry: SpatialDiagnosticMetrics(
            x: pos.x,
            y: pos.y,
            z: pos.z,
            azimuthDegrees: spherical.azimuthDegrees,
            distance: spherical.distance,
            stereoCorrelation: correlation,
            effectiveWidth: safeWidth,
            isPhaseCompensated: safeWidth < currentWidth,
            peakDb: -0.5,
          ),
        );
        onPanUpdate?.call(math.sin(spherical.azimuth), (pos.y * 0.5 + 0.5).clamp(0.0, 1.0));
      }
    });
  }

  // ─── Session Management ──────────────────────────────────────────────────

  Future<void> setAudioSessionId(int sessionId) async {
    _currentSessionId = sessionId;
    try {
      await _channel.invokeMethod('setAudioSessionId', {'sessionId': sessionId});
      _syncToNative();
    } catch (_) {}
  }

  void setTrackSeed(String trackId) {
    _flutterTrajectoryEngine.setTrackSeed(trackId);
  }

  // ─── 8D Toggle & Preset Selection ────────────────────────────────────────

  Future<void> toggle8D() async {
    final newEnabled = !state.isEnabled;
    state = state.copyWith(isEnabled: newEnabled, isBypassed: false);
    _savePreferences();
    _syncToNative();
  }

  Future<void> setBypass(bool bypass) async {
    state = state.copyWith(isBypassed: bypass);
    try {
      await _channel.invokeMethod('setBypass', {'bypass': bypass});
    } catch (_) {}
  }

  Future<void> selectPreset(SpatialPresetType preset) async {
    final newParams = preset.defaultParameters.copyWith(
      qualityMode: state.params.qualityMode,
    );
    state = state.copyWith(
      activePreset: preset,
      params: newParams,
    );
    _savePreferences();
    _syncToNative();
  }

  // ─── Parameter Controls ──────────────────────────────────────────────────

  Future<void> setIntensity(double intensity) async {
    final clamped = intensity.clamp(0.0, 1.0);
    state = state.copyWith(
      params: state.params.copyWith(intensity: clamped),
    );
    _syncToNative();
  }

  Future<void> setSpeedPreset(MovementSpeedPreset speedPreset) async {
    state = state.copyWith(
      params: state.params.copyWith(
        speedPreset: speedPreset,
        speedRadPerSec: speedPreset.radiansPerSecond,
      ),
    );
    _syncToNative();
  }

  Future<void> setDepthPreset(DepthPreset depthPreset) async {
    state = state.copyWith(
      params: state.params.copyWith(
        depthPreset: depthPreset,
        depth: depthPreset.depthValue,
      ),
    );
    _syncToNative();
  }

  Future<void> setStereoWidth(double width) async {
    final clamped = width.clamp(0.0, 2.0);
    state = state.copyWith(
      params: state.params.copyWith(stereoWidth: clamped),
    );
    _syncToNative();
  }

  Future<void> setCenterProtection(double protection) async {
    final clamped = protection.clamp(0.0, 1.0);
    state = state.copyWith(
      params: state.params.copyWith(centerProtection: clamped),
    );
    _syncToNative();
  }

  Future<void> setBassCrossover(double crossoverHz) async {
    final clamped = crossoverHz.clamp(60.0, 200.0);
    state = state.copyWith(
      params: state.params.copyWith(bassCrossoverHz: clamped),
    );
    _syncToNative();
  }

  Future<void> setReverbMix(double reverbMix) async {
    final clamped = reverbMix.clamp(0.0, 1.0);
    state = state.copyWith(
      params: state.params.copyWith(reverbMix: clamped),
    );
    _syncToNative();
  }

  Future<void> setDelayMix(double delayMix) async {
    final clamped = delayMix.clamp(0.0, 1.0);
    state = state.copyWith(
      params: state.params.copyWith(delayMix: clamped),
    );
    _syncToNative();
  }

  Future<void> setTrajectory(TrajectoryType trajectory) async {
    state = state.copyWith(
      params: state.params.copyWith(trajectory: trajectory),
    );
    _syncToNative();
  }

  Future<void> setQualityMode(QualityMode qualityMode) async {
    state = state.copyWith(
      params: state.params.copyWith(qualityMode: qualityMode),
    );
    _syncToNative();
  }

  Future<void> setControlMode(ControlMode controlMode) async {
    state = state.copyWith(controlMode: controlMode);
  }

  Future<void> setManualPosition(double x, double y) async {
    _flutterTrajectoryEngine.setManualPosition(x, y);
    try {
      await _channel.invokeMethod('setManualPosition', {'x': x, 'y': y});
    } catch (_) {}
  }

  // ─── Sync with Native Android DSP ─────────────────────────────────────────

  Future<void> _syncToNative() async {
    try {
      await _channel.invokeMethod('set8D', {
        'enabled': state.isEnabled,
        'intensity': state.params.intensity,
        'speed': state.params.speedRadPerSec,
        'depth': state.params.depth,
        'orbitRadius': state.params.orbitRadius,
        'width': state.params.stereoWidth,
        'centerProtection': state.params.centerProtection,
        'reverbMix': state.params.reverbMix,
        'trajectory': state.params.trajectory.name,
      });
    } catch (_) {}
  }
}

/// Global Riverpod Provider for Spatial Audio.
final spatialAudioProvider = StateNotifierProvider<SpatialAudioNotifier, SpatialAudioState>((ref) {
  return SpatialAudioNotifier();
});
