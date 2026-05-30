/// A stub implementation of WebNotificationService that acts as a no-op on native platforms.
class WebNotificationService {
  /// Prompt the browser user for notification permissions dynamically (no-op on native).
  static Future<void> requestPermission() async {
    // No-op on native platforms
  }

  /// Trigger or dynamically update the browser's desktop notification popup (no-op on native).
  static void showTrackNotification({
    required String title,
    required String artist,
    required String imageUrl,
  }) {
    // No-op on native platforms
  }
}
