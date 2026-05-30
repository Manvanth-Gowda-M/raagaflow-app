import '../../../core/constants/mood_map.dart';
import '../../../shared/models/track_model.dart';
import '../../../shared/services/music_provider.dart';

class MoodRepository {
  final MusicProvider _musicProvider;

  MoodRepository(this._musicProvider);

  List<String> resolveKeywords(
      String moodInput, List<String> selectedLanguages) {
    final normalizedMood = moodInput.toLowerCase().trim();
    final moodKey = englishToMoodKey[normalizedMood] ?? normalizedMood;
    final keywords = <String>[];

    for (final lang in selectedLanguages) {
      final langMap = moodMap[lang] ?? moodMap['hindi']!;
      final langKeywords = langMap[moodKey] ?? langMap['chill'] ?? [];
      keywords.addAll(langKeywords.take(2));
    }

    if (keywords.isEmpty) keywords.add('$moodInput songs');
    return keywords;
  }

  Future<List<TrackModel>> getMoodPlaylist(
      String mood, List<String> languages) async {
    final keywords = resolveKeywords(mood, languages);
    final results = await Future.wait(
      keywords.take(3).map((kw) =>
          _musicProvider.search(kw).catchError((_) => <TrackModel>[])),
    );
    final all = results.expand((r) => r).toList();
    // Deduplicate by id
    final seen = <String>{};
    return all.where((t) => seen.add(t.id)).toList();
  }
}
