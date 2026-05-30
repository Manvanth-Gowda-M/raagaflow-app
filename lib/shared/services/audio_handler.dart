import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../features/player/data/stream_resolver.dart';
import '../models/track_model.dart';

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
      final url = await _resolver.resolve(track);
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          // Web browsers cannot set custom headers on audio elements (CORS).
          // Headers are only sent on native platforms (Android/iOS).
          headers: kIsWeb
              ? null
              : {
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
                },
        ),
      );
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
  bool get playing => _player.playing;

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
}
