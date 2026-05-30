import '../../../shared/models/track_model.dart';
import '../../../shared/services/music_provider.dart';

class HomeRepository {
  final MusicProvider _musicProvider;

  HomeRepository(this._musicProvider);

  Future<List<TrackModel>> getTrending(String language) =>
      _musicProvider.getTrending(language);

  Future<List<TrackModel>> getNewReleases(String language) =>
      _musicProvider.search('latest songs $language 2026');
}
