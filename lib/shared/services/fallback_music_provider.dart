import 'package:flutter/foundation.dart';

import '../models/track_model.dart';
import 'music_provider.dart';

/// A [MusicProvider] that chains multiple providers in order.
/// If the first provider fails or returns empty results,
/// it automatically falls through to the next one.
///
/// **This ensures the app NEVER breaks** even if one API goes down.
class FallbackMusicProvider implements MusicProvider {
  final List<MusicProvider> _providers;

  FallbackMusicProvider(this._providers)
      : assert(_providers.isNotEmpty, 'At least one provider is required');

  @override
  String get sourceName => _providers.first.sourceName;

  @override
  Future<List<TrackModel>> search(String query, {int limit = 20}) async {
    for (final provider in _providers) {
      try {
        debugPrint('FallbackMusicProvider: Trying ${provider.sourceName}...');
        final results = await provider.search(query, limit: limit);
        if (results.isNotEmpty) {
          debugPrint('FallbackMusicProvider: ${provider.sourceName} returned ${results.length} results');
          return results;
        }
        debugPrint('FallbackMusicProvider: ${provider.sourceName} returned 0 results, trying next...');
      } catch (e) {
        debugPrint('FallbackMusicProvider: ${provider.sourceName} failed: $e — trying next...');
      }
    }
    debugPrint('FallbackMusicProvider: All providers failed for search "$query"');
    return [];
  }

  @override
  Future<List<TrackModel>> getTrending(String language, {int limit = 20}) async {
    for (final provider in _providers) {
      try {
        debugPrint('FallbackMusicProvider: Trying ${provider.sourceName} for trending...');
        final results = await provider.getTrending(language, limit: limit);
        if (results.isNotEmpty) {
          debugPrint('FallbackMusicProvider: ${provider.sourceName} returned ${results.length} trending tracks');
          return results;
        }
      } catch (e) {
        debugPrint('FallbackMusicProvider: ${provider.sourceName} trending failed: $e');
      }
    }
    return [];
  }
}
