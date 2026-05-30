import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'features/player/data/stream_resolver.dart';
import 'features/player/domain/player_provider.dart';
import 'shared/services/audio_handler.dart';
import 'shared/services/hive_service.dart';
import 'shared/services/web_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive local DB
  await HiveService.init();

  // Request notification permissions at startup dynamically
  if (kIsWeb) {
    await WebNotificationService.requestPermission();
  } else {
    try {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isLimited) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('Error requesting notification permission on native: $e');
    }
  }

  // Init audio service
  // On web: AudioService background tasks are not supported — use direct handler
  // On native: Use AudioService.init for background playback & lock-screen controls
  RaagaAudioHandler audioHandler;
  if (kIsWeb) {
    // Web: create handler directly (no background service needed)
    debugPrint('Web: Using direct audio handler (no background service)');
    audioHandler = RaagaAudioHandler(AudioPlayer(), StreamResolver());
  } else {
    try {
      audioHandler = await AudioService.init(
        builder: () => RaagaAudioHandler(AudioPlayer(), StreamResolver()),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.raagaflow.music.channel',
          androidNotificationChannelName: 'RaagaFlow Music',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: true,
        ),
      );
    } catch (e) {
      debugPrint('AudioService.init failed, using direct handler: $e');
      // Fallback: create handler without background service
      audioHandler = RaagaAudioHandler(AudioPlayer(), StreamResolver());
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const RaagaFlowApp(),
    ),
  );
}
