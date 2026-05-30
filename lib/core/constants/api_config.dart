/// Centralized API configuration.
/// ✅ Change these URLs to swap backends — no other code changes needed.
class ApiConfig {
  // Primary music source (JioSaavn internal API)
  static const String saavnBaseUrl = 'https://www.jiosaavn.com/api.php';

  // Secondary music sources
  static const String jamendoBaseUrl = 'https://api.jamendo.com/v3.0';
  static const String pixabayBaseUrl = 'https://pixabay.com/api/';
}
