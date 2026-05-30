// A multiplatform-safe bridge that conditionally exports the correct WebNotificationService implementation:
// - `web_notification_web.dart` on Web targets (where `dart.library.js` is available)
// - `web_notification_stub.dart` on Native targets (Android/iOS/Desktop)
export 'web_notification_stub.dart'
    if (dart.library.js) 'web_notification_web.dart';
