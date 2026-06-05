import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../../../shared/models/track_model.dart';
import '../../../shared/services/audio_handler.dart';
import '../../library/domain/library_provider.dart';
import 'audio_effects_provider.dart';

// Provided via override in main.dart
final audioHandlerProvider = Provider<RaagaAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden');
});

class PlayerState {
  final TrackModel? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final List<TrackModel> queue;
  final int queueIndex;
  final String? lastError;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.isBuffering = false,
    this.queue = const [],
    this.queueIndex = 0,
    this.lastError,
  });

  factory PlayerState.initial() => const PlayerState();

  PlayerState copyWith({
    TrackModel? currentTrack,
    bool? isPlaying,
    bool? isBuffering,
    List<TrackModel>? queue,
    int? queueIndex,
    String? lastError,
    bool clearError = false,
  }) =>
      PlayerState(
        currentTrack: currentTrack ?? this.currentTrack,
        isPlaying: isPlaying ?? this.isPlaying,
        isBuffering: isBuffering ?? this.isBuffering,
        queue: queue ?? this.queue,
        queueIndex: queueIndex ?? this.queueIndex,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref _ref;

  PlayerNotifier(this._ref) : super(PlayerState.initial()) {
    // Wire up the audio handler callbacks for auto-next and notification controls
    final handler = _ref.read(audioHandlerProvider);
    handler.onTrackComplete = () => skipToNext();
    handler.onSkipNext = () => skipToNext();
    handler.onSkipPrev = () => skipToPrev();

    // Dynamically sync status from audio handler playbackState
    handler.playbackState.listen((pbState) {
      final isPlaying = pbState.playing;
      final isBuffering = pbState.processingState == AudioProcessingState.buffering ||
                          pbState.processingState == AudioProcessingState.loading;
      state = state.copyWith(
        isPlaying: isPlaying,
        isBuffering: isBuffering,
      );
    });

    // Dynamically sync active song details from audio handler mediaItem (auto-play next, headset skip)
    handler.mediaItem.listen((item) {
      if (item != null) {
        final matchedTrack = state.queue.firstWhere(
          (t) => t.id == item.id,
          orElse: () => TrackModel(
            id: item.id,
            title: item.title,
            artist: item.artist ?? '',
            imageUrl: item.artUri?.toString() ?? '',
            source: 'saavn',
          ),
        );

        int idx = state.queue.indexWhere((t) => t.id == item.id);
        if (idx < 0) idx = 0;

        state = state.copyWith(
          currentTrack: matchedTrack,
          queueIndex: idx,
        );
      }
    });

    // Listen to Android Audio Session ID for Native DSP Effects
    handler.androidAudioSessionIdStream.listen((sessionId) {
      if (sessionId != null) {
        _ref.read(audioEffectsProvider.notifier).setAudioSessionId(sessionId);
      }
    });

    // Wire 8D pan callback → audio handler for real L/R stereo volume splitting
    _ref.read(audioEffectsProvider.notifier).onPanUpdate = (pan, depth) {
      handler.apply8DPan(pan, depth);
    };
  }

  Future<void> play(TrackModel track, {List<TrackModel>? queue}) async {
    int idx = 0;
    final q = queue ?? [track];
    if (queue != null) {
      idx = queue.indexOf(track);
      if (idx < 0) idx = 0;
    }

    // Eagerly update UI so the player appears immediately
    state = state.copyWith(
      currentTrack: track,
      isPlaying: true,
      isBuffering: true, // Eagerly set buffering until actual stream loads
      queue: q,
      queueIndex: idx,
      clearError: true,
    );

    // Save to actual playback history box reactively
    _ref.read(libraryProvider.notifier).addToHistory(track);

    try {
      final handler = _ref.read(audioHandlerProvider);
      await handler.playTrack(track);
    } catch (e, stack) {
      debugPrint('=== PLAYBACK ERROR ===');
      debugPrint('$e');
      debugPrint('$stack');
      // Revert play state on failure and surface a user-visible error
      state = state.copyWith(
        isPlaying: false,
        isBuffering: false,
        lastError: 'Could not play "${track.title}". Check your connection.',
      );
    }
  }

  Future<void> togglePlayPause() async {
    final handler = _ref.read(audioHandlerProvider);
    if (state.isPlaying) {
      await handler.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      await handler.play();
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> skipToNext() async {
    if (state.queue.isEmpty) return;
    final nextIdx = (state.queueIndex + 1) % state.queue.length;
    await play(state.queue[nextIdx], queue: state.queue);
  }

  Future<void> skipToPrev() async {
    if (state.queue.isEmpty) return;
    final prevIdx =
        (state.queueIndex - 1 + state.queue.length) % state.queue.length;
    await play(state.queue[prevIdx], queue: state.queue);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref);
});
