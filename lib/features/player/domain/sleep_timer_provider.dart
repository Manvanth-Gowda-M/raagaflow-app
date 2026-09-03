import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'player_provider.dart';

class SleepTimerState {
  final bool isActive;
  final Duration totalDuration;
  final Duration remaining;
  final bool endOfTrack;
  final bool isFadingOut;

  const SleepTimerState({
    this.isActive = false,
    this.totalDuration = Duration.zero,
    this.remaining = Duration.zero,
    this.endOfTrack = false,
    this.isFadingOut = false,
  });

  SleepTimerState copyWith({
    bool? isActive,
    Duration? totalDuration,
    Duration? remaining,
    bool? endOfTrack,
    bool? isFadingOut,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      totalDuration: totalDuration ?? this.totalDuration,
      remaining: remaining ?? this.remaining,
      endOfTrack: endOfTrack ?? this.endOfTrack,
      isFadingOut: isFadingOut ?? this.isFadingOut,
    );
  }

  String get formattedRemaining {
    if (!isActive) return '';
    if (endOfTrack) return 'End of song';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref _ref;
  Timer? _ticker;

  SleepTimerNotifier(this._ref) : super(const SleepTimerState());

  void setTimer(Duration duration, {bool fadeOut = true}) {
    cancelTimer();

    state = SleepTimerState(
      isActive: true,
      totalDuration: duration,
      remaining: duration,
      endOfTrack: false,
      isFadingOut: false,
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemaining = state.remaining - const Duration(seconds: 1);

      if (newRemaining <= Duration.zero) {
        _triggerStop();
        return;
      }

      // Smooth volume fade-out in the last 20 seconds
      if (fadeOut && newRemaining.inSeconds <= 20) {
        final volume = (newRemaining.inSeconds / 20.0).clamp(0.05, 1.0);
        _ref.read(audioHandlerProvider).setVolume(volume);
        state = state.copyWith(remaining: newRemaining, isFadingOut: true);
      } else {
        state = state.copyWith(remaining: newRemaining);
      }
    });
  }

  void setEndOfTrack() {
    cancelTimer();
    state = const SleepTimerState(
      isActive: true,
      endOfTrack: true,
    );
  }

  void onTrackEnded() {
    if (state.isActive && state.endOfTrack) {
      _triggerStop();
    }
  }

  void _triggerStop() {
    cancelTimer();
    final handler = _ref.read(audioHandlerProvider);
    handler.pause();
    // Restore normal volume level
    handler.setVolume(1.0);
  }

  void cancelTimer() {
    _ticker?.cancel();
    _ticker = null;
    if (state.isActive) {
      _ref.read(audioHandlerProvider).setVolume(1.0);
    }
    state = const SleepTimerState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  return SleepTimerNotifier(ref);
});
