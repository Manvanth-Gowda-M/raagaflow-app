import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/home_repository.dart';
import '../../search/domain/search_provider.dart';
import '../../../shared/models/track_model.dart';

import '../../../shared/services/hive_service.dart';

final homeRepositoryProvider = Provider((ref) {
  return HomeRepository(ref.read(musicProviderProvider));
});

class SelectedLanguageNotifier extends Notifier<String> {
  static const _langKey = 'selected_language';

  @override
  String build() {
    final box = HiveService.settings;
    return box.get(_langKey, defaultValue: 'hindi') as String;
  }

  void setLanguage(String lang) {
    state = lang;
    HiveService.settings.put(_langKey, lang);
  }
}

final selectedLanguageProvider = NotifierProvider<SelectedLanguageNotifier, String>(() {
  return SelectedLanguageNotifier();
});

final trendingProvider =
    FutureProvider.family<List<TrackModel>, String>((ref, language) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getTrending(language);
});

final newReleasesProvider =
    FutureProvider.family<List<TrackModel>, String>((ref, language) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getNewReleases(language);
});

final famousProvider =
    FutureProvider.family<List<TrackModel>, String>((ref, language) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getFamous(language);
});

final globalTrendingProvider =
    FutureProvider<List<TrackModel>>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getGlobalTrending();
});

final movieSongsProvider =
    FutureProvider.family<List<TrackModel>, String>((ref, language) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getMovieSongs(language);
});

final officialSongsProvider =
    FutureProvider.family<List<TrackModel>, String>((ref, language) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getOfficialSongs(language);
});

final combinedNewReleasesProvider = FutureProvider<List<TrackModel>>((ref) async {
  final languages = await ref.watch(selectedLanguagesProvider.future);
  final repo = ref.read(homeRepositoryProvider);

  final List<List<TrackModel>> lists = [];
  for (final lang in languages) {
    try {
      final tracks = await repo.getNewReleases(lang);
      if (tracks.isNotEmpty) {
        lists.add(tracks);
      }
    } catch (e) {
      // Ignore exceptions for individual language fetches
    }
  }

  if (lists.isEmpty) return [];

  // Interleave tracks dynamically to create a balanced feed across all their selected languages
  final List<TrackModel> combined = [];
  int maxLen = 0;
  for (final list in lists) {
    if (list.length > maxLen) maxLen = list.length;
  }

  for (int i = 0; i < maxLen; i++) {
    for (final list in lists) {
      if (i < list.length) {
        combined.add(list[i]);
      }
    }
  }

  return combined;
});

// ─── Multi-Language Selection (Profile + Home Sections) ───────────────────────

class SelectedLanguagesNotifier extends AsyncNotifier<List<String>> {
  static const _key = 'selected_languages';

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    return (saved == null || saved.isEmpty) ? ['hindi'] : saved;
  }

  Future<void> setLanguages(List<String> langs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, langs);
    state = AsyncValue.data(langs);
  }
}

final selectedLanguagesProvider =
    AsyncNotifierProvider<SelectedLanguagesNotifier, List<String>>(
  SelectedLanguagesNotifier.new,
);
