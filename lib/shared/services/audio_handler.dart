import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../features/player/data/stream_resolver.dart';
import '../models/track_model.dart';
import '../models/download_model.dart';
import 'hive_service.dart';

class RaagaAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  final StreamResolver _resolver;

  /// Callbacks wired by PlayerNotifier to handle queue navigation.
  VoidCallback? onTrackComplete;
  VoidCallback? onSkipNext;
  VoidCallback? onSkipPrev;

  RaagaAudioHandler(this._player, this._resolver) {
    _initSession();
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        debugPrint('RaagaAudioHandler: Track completed, auto-next...');
        Future.microtask(() {
          onTrackComplete?.call();
        });
      }
    });
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playTrack(TrackModel track) async {
    // Premium, high-resolution aesthetic fallback artwork (Seoul city lights / night reflections)
    String artworkUrl = track.imageUrl;
    if (artworkUrl.isEmpty || 
        artworkUrl.contains('placeholder') || 
        artworkUrl.contains('default') || 
        artworkUrl.contains('asset')) {
      artworkUrl = 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?auto=format&fit=crop&w=800&q=85';
    }

    mediaItem.add(MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      artUri: Uri.tryParse(artworkUrl),
      duration: track.durationSeconds != null
          ? Duration(seconds: track.durationSeconds!)
          : null,
    ));

    try {
      // ─── 1. Check if track is downloaded locally ───
      final downloaded = HiveService.downloads.values.cast<DownloadedSong?>().firstWhere(
        (d) => d?.songId == track.id,
        orElse: () => null,
      );

      if (downloaded != null && !kIsWeb) {
        final localFile = File(downloaded.localPath);
        if (await localFile.exists()) {
          debugPrint('RaagaAudioHandler: Playing offline local file: ${downloaded.localPath}');
          await _player.setAudioSource(AudioSource.file(downloaded.localPath));
          await _player.play();
          return;
        }
      }

      // ─── 2. Otherwise resolve stream over network ───
      final url = await _resolver.resolve(track);
      if (url.startsWith('http://') || url.startsWith('https://')) {
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            headers: kIsWeb
                ? null
                : {
                    'User-Agent':
                        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
                  },
          ),
        );
      } else {
        await _player.setAudioSource(AudioSource.file(url));
      }
      await _player.play();
    } catch (e, stack) {
      debugPrint('Playback error in RaagaAudioHandler: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    debugPrint('RaagaAudioHandler: skipToNext called');
    onSkipNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('RaagaAudioHandler: skipToPrevious called');
    onSkipPrev?.call();
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<int?> get androidAudioSessionIdStream => _player.androidAudioSessionIdStream;
  bool get playing => _player.playing;

  /// Set player volume (e.g. for smooth sleep timer fade-out)
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('RaagaAudioHandler setVolume error: $e');
    }
  }

  /// Set playback speed (e.g. 0.8x, 1.0x, 1.25x, 1.5x)
  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed.clamp(0.5, 2.0));
    } catch (e) {
      debugPrint('RaagaAudioHandler setSpeed error: $e');
    }
  }

  /// Eagerly pre-cache next track stream URL for instant skipping
  Future<void> precacheTrack(TrackModel track) async {
    try {
      _resolver.resolve(track).catchError((_) => '');
    } catch (_) {}
  }

  /// Apply subtle 8D depth cue via just_audio volume.
  /// The real rotation comes from Android EQ/Virtualizer (native side).
  /// Here we just apply a very gentle loudness depth cue — "behind" = slightly quieter.
  /// Range: 0.88–1.0 (never mutes, never sounds like pumping).
  void apply8DPan(double pan, double depth) {
    try {
      // depth: 1.0 = "in front" (loudest), 0.0 = "behind" (slightly quieter)
      // Only 12% variation in volume — subtle depth cue, not an obvious pump.
      final volumeLevel = (0.88 + depth * 0.12).clamp(0.88, 1.0);
      _player.setVolume(volumeLevel);
    } catch (_) {}
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  /// Called when the user swipes the app away from the Recents screen.
  /// Default audio_service behavior would call stop() — we override to
  /// do NOTHING so music keeps playing in the background.
  @override
  Future<void> onTaskRemoved() async {
    // Intentionally blank — music continues after swipe-from-recents.
    debugPrint('RaagaAudioHandler: Task removed — keeping playback alive.');
  }

  /// Called when user explicitly swipes away the media notification.
  /// Only then do we actually stop and release resources.
  @override
  Future<void> onNotificationDeleted() async {
    debugPrint('RaagaAudioHandler: Notification dismissed — stopping.');
    await _player.stop();
    await super.onNotificationDeleted();
  }
}
