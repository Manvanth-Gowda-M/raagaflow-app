import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../../../shared/models/track_model.dart';
import '../../../shared/services/audio_handler.dart';
import '../../../shared/services/saavn_music_provider.dart';
import '../../library/domain/library_provider.dart';
import 'spatial_audio_provider.dart';
import 'audio_effects_provider.dart';
import 'sleep_timer_provider.dart';

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
  final bool isAutoplayEnabled;
  final double playbackSpeed;
  final bool isShuffle;
  final bool isRepeat;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.isBuffering = false,
    this.queue = const [],
    this.queueIndex = 0,
    this.lastError,
    this.isAutoplayEnabled = true,
    this.playbackSpeed = 1.0,
    this.isShuffle = false,
    this.isRepeat = false,
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
    bool? isAutoplayEnabled,
    double? playbackSpeed,
    bool? isShuffle,
    bool? isRepeat,
  }) =>
      PlayerState(
        currentTrack: currentTrack ?? this.currentTrack,
        isPlaying: isPlaying ?? this.isPlaying,
        isBuffering: isBuffering ?? this.isBuffering,
        queue: queue ?? this.queue,
        queueIndex: queueIndex ?? this.queueIndex,
        lastError: clearError ? null : (lastError ?? this.lastError),
        isAutoplayEnabled: isAutoplayEnabled ?? this.isAutoplayEnabled,
        playbackSpeed: playbackSpeed ?? this.playbackSpeed,
        isShuffle: isShuffle ?? this.isShuffle,
        isRepeat: isRepeat ?? this.isRepeat,
      );
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref _ref;
  final SaavnMusicProvider _saavnProvider = SaavnMusicProvider();
  bool _isLoadingAutoplay = false;

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
        _ref.read(spatialAudioProvider.notifier).setAudioSessionId(sessionId);
      }
    });

    // Wire 8D pan callback → audio handler for real L/R stereo volume splitting
    _ref.read(audioEffectsProvider.notifier).onPanUpdate = (pan, depth) {
      handler.apply8DPan(pan, depth);
    };
    _ref.read(spatialAudioProvider.notifier).onPanUpdate = (pan, depth) {
      handler.apply8DPan(pan, depth);
    };
  }

  Future<void> setAutoplay(bool enabled) async {
    state = state.copyWith(isAutoplayEnabled: enabled);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(playbackSpeed: speed);
    await _ref.read(audioHandlerProvider).setSpeed(speed);
  }

  Future<void> play(TrackModel track, {List<TrackModel>? queue}) async {
    int idx = 0;
    final q = queue != null ? List<TrackModel>.from(queue) : [track];
    if (queue != null) {
      idx = queue.indexOf(track);
      if (idx < 0) idx = 0;
    }

    // Set deterministic seed for organic spatial pattern
    _ref.read(spatialAudioProvider.notifier).setTrackSeed(track.id);

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

      // Pre-cache the next song in the queue for zero-latency instant skips
      if (idx + 1 < q.length) {
        handler.precacheTrack(q[idx + 1]);
      }
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

    // Check if sleep timer is set to stop at end of song
    final sleepState = _ref.read(sleepTimerProvider);
    if (sleepState.isActive && sleepState.endOfTrack) {
      _ref.read(sleepTimerProvider.notifier).onTrackEnded();
      return;
    }

    // Check if we reached the end of queue
    if (state.queueIndex >= state.queue.length - 1) {
      if (state.isAutoplayEnabled && !_isLoadingAutoplay) {
        _isLoadingAutoplay = true;
        try {
          final current = state.currentTrack ?? state.queue.last;
          final recs = await _saavnProvider.getRecommendations(current, limit: 8);
          final existingIds = state.queue.map((t) => t.id).toSet();
          final newTracks = recs.where((t) => !existingIds.contains(t.id)).toList();

          if (newTracks.isNotEmpty) {
            final updatedQueue = [...state.queue, ...newTracks];
            _isLoadingAutoplay = false;
            await play(updatedQueue[state.queueIndex + 1], queue: updatedQueue);
            return;
          }
        } catch (e) {
          debugPrint('Autoplay recommendation fetch failed: $e');
        } finally {
          _isLoadingAutoplay = false;
        }
      }
    }

    final nextIdx = (state.queueIndex + 1) % state.queue.length;
    await play(state.queue[nextIdx], queue: state.queue);
  }

  Future<void> skipToPrev() async {
    if (state.queue.isEmpty) return;
    final prevIdx =
        (state.queueIndex - 1 + state.queue.length) % state.queue.length;
    await play(state.queue[prevIdx], queue: state.queue);
  }

  void toggleShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
  }

  void toggleRepeat() {
    state = state.copyWith(isRepeat: !state.isRepeat);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref);
});
