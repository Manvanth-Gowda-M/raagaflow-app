import '../models/track_model.dart';

/// Abstract interface for music data providers.
/// All backends (JioSaavn, Jamendo, Spotify, etc.) must implement this.
/// Swap providers by changing the concrete class — the app never breaks.
abstract class MusicProvider {
  /// Human-readable name used as the `source` field in [TrackModel].
  String get sourceName;

  /// Search for tracks matching [query].
  Future<List<TrackModel>> search(String query, {int limit = 20});

  /// Get trending tracks in a specific [language] (e.g., 'hindi', 'tamil').
  Future<List<TrackModel>> getTrending(String language, {int limit = 20});
}
