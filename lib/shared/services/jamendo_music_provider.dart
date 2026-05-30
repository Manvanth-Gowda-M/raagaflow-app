import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_config.dart';
import '../../core/constants/api_keys.dart';
import '../models/track_model.dart';
import 'music_provider.dart';

/// Concrete [MusicProvider] for Jamendo — provides royalty-free, licensed music.
/// Acts as the safety-net fallback when JioSaavn is down.
class JamendoMusicProvider implements MusicProvider {
  late final Dio _dio;

  JamendoMusicProvider() {
    _dio = Dio();
  }

  @override
  String get sourceName => 'jamendo';

  @override
  Future<List<TrackModel>> search(String query, {int limit = 20}) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.jamendoBaseUrl}/tracks',
        queryParameters: {
          'client_id': ApiKeys.jamendoClientId,
          'format': 'json',
          'limit': limit,
          'search': query,
          'audioformat': 'mp32',
          'include': 'musicinfo',
        },
      );
      final results = response.data['results'] as List? ?? [];
      return results.map((e) => TrackModel.fromJamendo(e)).toList();
    } catch (e) {
      debugPrint('JamendoMusicProvider search error: $e');
      return [];
    }
  }

  @override
  Future<List<TrackModel>> getTrending(String language, {int limit = 20}) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.jamendoBaseUrl}/tracks',
        queryParameters: {
          'client_id': ApiKeys.jamendoClientId,
          'format': 'json',
          'limit': limit,
          'order': 'popularity_total',
          'audioformat': 'mp32',
          'include': 'musicinfo',
        },
      );
      final results = response.data['results'] as List? ?? [];
      return results.map((e) => TrackModel.fromJamendo(e)).toList();
    } catch (e) {
      debugPrint('JamendoMusicProvider trending error: $e');
      return [];
    }
  }
}
