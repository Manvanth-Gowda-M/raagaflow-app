import '../../../shared/models/track_model.dart';
import '../../../shared/services/music_provider.dart';

class HomeRepository {
  final MusicProvider _musicProvider;

  HomeRepository(this._musicProvider);

  Future<List<TrackModel>> getTrending(String language) =>
      _musicProvider.getTrending(language);

  Future<List<TrackModel>> getNewReleases(String language) {
    final now = DateTime.now();
    final year = now.year;
    final slot = now.millisecondsSinceEpoch ~/ (30 * 60 * 1000);
    final variants = [
      'new $language songs $year',
      'latest $language hits',
      'fresh $language music',
      'top $language songs $year',
    ];
    final query = variants[slot % variants.length];
    return _musicProvider.search(query, limit: 20, page: 1);
  }

  /// Famous all-time hits for a language — uses reliable, high-result queries.
  Future<List<TrackModel>> getFamous(String language) {
    // Language-specific famous artist/film queries that always return results on Saavn
    final queries = {
      'kannada':   'superhit kannada songs',
      'hindi':     'bollywood superhits all time',
      'tamil':     'tamil superhit songs',
      'telugu':    'telugu superhit songs',
      'malayalam': 'malayalam superhit songs',
      'punjabi':   'punjabi superhit songs',
      'bengali':   'bengali superhit songs',
      'marathi':   'marathi superhit songs',
      'gujarati':  'gujarati superhit songs',
      'bhojpuri':  'bhojpuri superhit songs',
      'english':   'english top hits',
    };
    final query = queries[language] ?? 'superhit $language songs';
    return _musicProvider.search(query, limit: 20, page: 1);
  }

  /// Official movie soundtrack songs for the selected language.
  Future<List<TrackModel>> getMovieSongs(String language) {
    final queries = {
      'kannada':   'kannada blockbuster songs',
      'hindi':     'bollywood blockbuster songs 2024',
      'tamil':     'anirudh ravichander songs',
      'telugu':    'ss thaman telugu songs',
      'malayalam': 'malayalam film songs 2024',
      'punjabi':   'punjabi dhol songs hits',
      'bengali':   'bengali film songs hits',
      'marathi':   'marathi film songs 2024',
      'gujarati':  'gujarati garba songs',
      'bhojpuri':  'bhojpuri hit songs',
      'english':   'hollywood movie soundtracks',
    };
    final query = queries[language] ?? '$language film songs 2024';
    return _musicProvider.search(query, limit: 20, page: 1);
  }

  /// Official chart-topping non-film pop/album songs per language.
  Future<List<TrackModel>> getOfficialSongs(String language) {
    // Use popular artist names / known album titles — Saavn indexes these reliably.
    final queries = {
      'kannada':   'vijay prakash kannada songs',
      'hindi':     'arijit singh hindi songs',
      'tamil':     'ar rahman tamil hits',
      'telugu':    'sid sriram telugu songs',
      'malayalam': 'kj yesudas malayalam songs',
      'punjabi':   'diljit dosanjh songs',
      'bengali':   'arijit singh bengali songs',
      'marathi':   'ajay atul marathi songs',
      'gujarati':  'gujarati love songs',
      'bhojpuri':  'pawan singh bhojpuri songs',
      'english':   'ed sheeran songs',
    };
    final query = queries[language] ?? 'top $language songs';
    return _musicProvider.search(query, limit: 20, page: 1);
  }

  Future<List<TrackModel>> getGlobalTrending() {
    return _musicProvider.search('trending hit songs 2024', limit: 20, page: 1);
  }
}
