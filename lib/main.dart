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

  if (kIsWeb) {
    await WebNotificationService.requestPermission();
  } else {
    // Request notification permission
    try {
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }

    // Battery optimization exemption — needed for OnePlus/OxygenOS so
    // the OS doesn't kill the background playback service.
    try {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('Battery opt not available: $e');
    }
  }

  // Init audio service
  RaagaAudioHandler audioHandler;
  if (kIsWeb) {
    debugPrint('Web: Using direct audio handler (no background service)');
    audioHandler = RaagaAudioHandler(AudioPlayer(), StreamResolver());
  } else {
    try {
      audioHandler = await AudioService.init(
        builder: () => RaagaAudioHandler(AudioPlayer(), StreamResolver()),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.raagaflow.music.channel',
          androidNotificationChannelName: 'RaagaFlow Music',
          // false = user can dismiss the notification (normal behaviour, was working)
          androidNotificationOngoing: false,
          // false = foreground service stays alive when paused → keeps background play
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidShowNotificationBadge: true,
          notificationColor: Color(0xFFE57373),
          preloadArtwork: true,
        ),
      );
    } catch (e) {
      debugPrint('AudioService.init failed, using direct handler: $e');
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
