import 'package:dio/dio.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/api_keys.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/track_model.dart';
import '../../../shared/services/music_provider.dart';

class SearchRepository {
  final MusicProvider _musicProvider;
  late final Dio _dio;

  SearchRepository(this._musicProvider) {
    _dio = Dio();
  }

  /// Primary search — delegates to the active [MusicProvider].
  Future<List<TrackModel>> searchPrimary(String query) async {
    try {
      return await _musicProvider.search(query);
    } catch (e) {
      throw AppException('Search failed: $e');
    }
  }

  /// Get trending tracks via the active [MusicProvider].
  Future<List<TrackModel>> getTrending(String language) async {
    return _musicProvider.getTrending(language);
  }

  Future<List<TrackModel>> searchJamendo(String query) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.jamendoBaseUrl}/tracks',
        queryParameters: {
          'client_id': ApiKeys.jamendoClientId,
          'format': 'json',
          'limit': 20,
          'search': query,
          'audioformat': 'mp32',
          'include': 'musicinfo',
        },
      );
      final results = response.data['results'] as List? ?? [];
      return results.map((e) => TrackModel.fromJamendo(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Search all sources in parallel and merge results.
  /// Primary provider results come FIRST.
  Future<List<TrackModel>> searchAll(String query) async {
    final results = await Future.wait([
      searchPrimary(query).catchError((_) => <TrackModel>[]),
      searchJamendo(query).catchError((_) => <TrackModel>[]),
    ]);
    return results.expand((r) => r).toList();
  }
}
