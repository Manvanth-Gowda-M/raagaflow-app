import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Intensity level for each audio effect.
enum EffectIntensity {
  normal,   // 60% power
  strong,   // 80% power
  extreme,  // 100% power
}

extension EffectIntensityValue on EffectIntensity {
  int get bassStrength => switch (this) {
    EffectIntensity.normal  => 700,
    EffectIntensity.strong  => 850,
    EffectIntensity.extreme => 1000,
  };

  int get surroundStrength => switch (this) {
    EffectIntensity.normal  => 700,
    EffectIntensity.strong  => 900,
    EffectIntensity.extreme => 1000,
  };

  int get vocalStrength => switch (this) {
    EffectIntensity.normal  => 600,
    EffectIntensity.strong  => 800,
    EffectIntensity.extreme => 1000,
  };

  int get eightDStrength => switch (this) {
    EffectIntensity.normal  => 600,
    EffectIntensity.strong  => 800,
    EffectIntensity.extreme => 1000,
  };

  String get label => switch (this) {
    EffectIntensity.normal  => 'Normal',
    EffectIntensity.strong  => 'Strong',
    EffectIntensity.extreme => 'Extreme',
  };
}

class AudioEffectsState {
  final bool is8DEnabled;
  final EffectIntensity intensity8D;
  final bool isBassBoostEnabled;
  final EffectIntensity intensityBass;
  final bool isSurroundEnabled;
  final EffectIntensity intensitySurround;
  final bool isVocalBoostEnabled;
  final EffectIntensity intensityVocal;
  final bool isReverbEnabled;

  const AudioEffectsState({
    this.is8DEnabled = false,
    this.intensity8D = EffectIntensity.strong,
    this.isBassBoostEnabled = false,
    this.intensityBass = EffectIntensity.strong,
    this.isSurroundEnabled = false,
    this.intensitySurround = EffectIntensity.strong,
    this.isVocalBoostEnabled = false,
    this.intensityVocal = EffectIntensity.strong,
    this.isReverbEnabled = false,
  });

  AudioEffectsState copyWith({
    bool? is8DEnabled,
    EffectIntensity? intensity8D,
    bool? isBassBoostEnabled,
    EffectIntensity? intensityBass,
    bool? isSurroundEnabled,
    EffectIntensity? intensitySurround,
    bool? isVocalBoostEnabled,
    EffectIntensity? intensityVocal,
    bool? isReverbEnabled,
  }) {
    return AudioEffectsState(
      is8DEnabled: is8DEnabled ?? this.is8DEnabled,
      intensity8D: intensity8D ?? this.intensity8D,
      isBassBoostEnabled: isBassBoostEnabled ?? this.isBassBoostEnabled,
      intensityBass: intensityBass ?? this.intensityBass,
      isSurroundEnabled: isSurroundEnabled ?? this.isSurroundEnabled,
      intensitySurround: intensitySurround ?? this.intensitySurround,
      isVocalBoostEnabled: isVocalBoostEnabled ?? this.isVocalBoostEnabled,
      intensityVocal: intensityVocal ?? this.intensityVocal,
      isReverbEnabled: isReverbEnabled ?? this.isReverbEnabled,
    );
  }
}

class AudioEffectsNotifier extends StateNotifier<AudioEffectsState> {
  static const MethodChannel _channel = MethodChannel('com.raagaflow.audio_effects');

  /// Callback set by the audio handler to apply L/R volume-based 8D panning.
  void Function(double pan, double depth)? onPanUpdate;

  AudioEffectsNotifier() : super(const AudioEffectsState()) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'on8DPanUpdate') {
      final double pan   = (call.arguments['pan']   as num?)?.toDouble() ?? 0.0;
      final double depth = (call.arguments['depth'] as num?)?.toDouble() ?? 0.5;
      onPanUpdate?.call(pan, depth);
    }
  }

  // ─── Session Management ──────────────────────────────────────────────────

  Future<void> setAudioSessionId(int sessionId) async {
    try {
      await _channel.invokeMethod('setAudioSessionId', {'sessionId': sessionId});
      _reapplyAllEffects();
    } catch (_) {}
  }

  void _reapplyAllEffects() {
    if (state.isBassBoostEnabled) {
      _channel.invokeMethod('setBassBoost', {
        'enabled': true,
        'intensity': state.intensityBass.bassStrength,
      }).catchError((_) => null);
    }
    if (state.isSurroundEnabled) {
      _channel.invokeMethod('setVirtualizer', {
        'enabled': true,
        'intensity': state.intensitySurround.surroundStrength,
      }).catchError((_) => null);
    }
    if (state.isVocalBoostEnabled) {
      _channel.invokeMethod('setVocalBoost', {
        'enabled': true,
        'intensity': state.intensityVocal.vocalStrength,
      }).catchError((_) => null);
    }
    if (state.isReverbEnabled) {
      _channel.invokeMethod('setReverb', {'enabled': true}).catchError((_) => null);
    }
    if (state.is8DEnabled) {
      _channel.invokeMethod('set8D', {
        'enabled': true,
        'intensity': state.intensity8D.eightDStrength,
      }).catchError((_) => null);
    }
  }

  // ─── 8D Audio ────────────────────────────────────────────────────────────

  Future<void> toggle8D() async {
    final enabled = !state.is8DEnabled;
    state = state.copyWith(is8DEnabled: enabled);
    try {
      await _channel.invokeMethod('set8D', {
        'enabled': enabled,
        'intensity': state.intensity8D.eightDStrength,
      });
    } catch (_) {}
  }

  Future<void> set8DIntensity(EffectIntensity intensity) async {
    state = state.copyWith(intensity8D: intensity);
    if (state.is8DEnabled) {
      try {
        await _channel.invokeMethod('set8D', {
          'enabled': true,
          'intensity': intensity.eightDStrength,
        });
      } catch (_) {}
    }
  }

  // ─── Bass Boost ──────────────────────────────────────────────────────────

  Future<void> toggleBassBoost() async {
    final enabled = !state.isBassBoostEnabled;
    state = state.copyWith(isBassBoostEnabled: enabled);
    try {
      await _channel.invokeMethod('setBassBoost', {
        'enabled': enabled,
        'intensity': state.intensityBass.bassStrength,
      });
    } catch (_) {}
  }

  Future<void> setBassIntensity(EffectIntensity intensity) async {
    state = state.copyWith(intensityBass: intensity);
    if (state.isBassBoostEnabled) {
      try {
        await _channel.invokeMethod('setBassBoost', {
          'enabled': true,
          'intensity': intensity.bassStrength,
        });
      } catch (_) {}
    }
  }

  // ─── Surround Sound ──────────────────────────────────────────────────────

  Future<void> toggleSurround() async {
    final enabled = !state.isSurroundEnabled;
    state = state.copyWith(isSurroundEnabled: enabled);
    try {
      await _channel.invokeMethod('setVirtualizer', {
        'enabled': enabled,
        'intensity': state.intensitySurround.surroundStrength,
      });
    } catch (_) {}
  }

  Future<void> setSurroundIntensity(EffectIntensity intensity) async {
    state = state.copyWith(intensitySurround: intensity);
    if (state.isSurroundEnabled) {
      try {
        await _channel.invokeMethod('setVirtualizer', {
          'enabled': true,
          'intensity': intensity.surroundStrength,
        });
      } catch (_) {}
    }
  }

  // ─── Vocal Boost ─────────────────────────────────────────────────────────

  Future<void> toggleVocalBoost() async {
    final enabled = !state.isVocalBoostEnabled;
    state = state.copyWith(isVocalBoostEnabled: enabled);
    try {
      await _channel.invokeMethod('setVocalBoost', {
        'enabled': enabled,
        'intensity': state.intensityVocal.vocalStrength,
      });
    } catch (_) {}
  }

  Future<void> setVocalIntensity(EffectIntensity intensity) async {
    state = state.copyWith(intensityVocal: intensity);
    if (state.isVocalBoostEnabled) {
      try {
        await _channel.invokeMethod('setVocalBoost', {
          'enabled': true,
          'intensity': intensity.vocalStrength,
        });
      } catch (_) {}
    }
  }

  // ─── Concert Hall Reverb ─────────────────────────────────────────────────

  Future<void> toggleReverb() async {
    final enabled = !state.isReverbEnabled;
    state = state.copyWith(isReverbEnabled: enabled);
    try {
      await _channel.invokeMethod('setReverb', {'enabled': enabled});
    } catch (_) {}
  }
}

final audioEffectsProvider = StateNotifierProvider<AudioEffectsNotifier, AudioEffectsState>((ref) {
  return AudioEffectsNotifier();
});
