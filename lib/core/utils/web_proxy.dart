import 'package:flutter/foundation.dart';

/// On web, browsers block cross-origin requests that lack CORS headers.
/// This utility wraps any URL through corsproxy.io so it can be fetched
/// from the browser. On native (Android/iOS) it returns the original URL.
class WebProxy {
  /// Public CORS proxies tried in order of reliability.
  static const _proxies = [
    'https://corsproxy.io/?',
    'https://api.allorigins.win/raw?url=',
  ];

  /// Active proxy index (starts at 0, rotates on failure).
  static int _proxyIndex = 0;

  /// Returns a proxy-wrapped URL on web, or the original URL on native.
  static String wrap(String url) {
    if (!kIsWeb) return url;
    return '${_proxies[_proxyIndex]}${Uri.encodeComponent(url)}';
  }

  /// Rotate to next proxy (call if current proxy fails).
  static void rotateProxy() {
    _proxyIndex = (_proxyIndex + 1) % _proxies.length;
  }

  /// Reset to first proxy.
  static void resetProxy() {
    _proxyIndex = 0;
  }
}
