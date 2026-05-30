import 'package:flutter/foundation.dart';

/// On web, browsers block cross-origin requests that lack CORS headers.
/// This utility wraps any URL through corsproxy.io so it can be fetched
/// from the browser. On native (Android/iOS) it returns the original URL.
class WebProxy {
  /// Returns a proxy-wrapped URL on web, or the original URL on native.
  static String wrap(String url) {
    if (!kIsWeb) return url;
    
    // Detect if we are running in local development
    final isLocal = kDebugMode || 
        Uri.base.host == 'localhost' || 
        Uri.base.host == '127.0.0.1';
        
    if (isLocal) {
      // Use a reliable public CORS proxy for local development
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
    } else {
      // Use our ultra-fast self-hosted Vercel CORS proxy in production to bypass all ISP blocks
      return '/api/cors?url=${Uri.encodeComponent(url)}';
    }
  }
}
