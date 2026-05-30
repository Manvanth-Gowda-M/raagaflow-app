// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, unnecessary_brace_in_string_interps

import 'package:flutter/foundation.dart';
import 'dart:js' as js;

/// A web-specific implementation of WebNotificationService that calls standard browser APIs using 'dart:js'.
class WebNotificationService {
  /// Prompt the browser user for notification permissions dynamically.
  static Future<void> requestPermission() async {
    try {
      js.context.callMethod('eval', [
        """
        if ('Notification' in window) {
          if (Notification.permission !== 'granted' && Notification.permission !== 'denied') {
            Notification.requestPermission().then(permission => {
              console.log('Web notification permission:', permission);
            });
          }
        }
        """
      ]);
    } catch (e) {
      debugPrint('WebNotificationService.requestPermission error: $e');
    }
  }

  /// Trigger or dynamically update the browser's desktop notification popup.
  static void showTrackNotification({
    required String title,
    required String artist,
    required String imageUrl,
  }) {
    try {
      // Escape strings to prevent JavaScript syntax breakage
      final safeTitle = title.replaceAll("'", "\\'").replaceAll('"', '\\"');
      final safeArtist = artist.replaceAll("'", "\\'").replaceAll('"', '\\"');
      final safeUrl = imageUrl.replaceAll("'", "\\'").replaceAll('"', '\\"');

      js.context.callMethod('eval', [
        """
        if ('Notification' in window && Notification.permission === 'granted') {
          // Instantly close the active notification to prevent multiple banners stacking
          if (window.activeTrackNotification) {
            window.activeTrackNotification.close();
          }
          
          window.activeTrackNotification = new Notification("Now Playing 🎵", {
            body: "$safeTitle by $safeArtist",
            icon: "$safeUrl",
            tag: "raagaflow-now-playing",
            silent: true
          });
        }
        """
      ]);
    } catch (e) {
      debugPrint('WebNotificationService.showTrackNotification error: $e');
    }
  }
}
