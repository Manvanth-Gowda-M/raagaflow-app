import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/search_repository.dart';
import '../../../shared/models/track_model.dart';
import '../../../shared/services/music_provider.dart';
import '../../../shared/services/saavn_music_provider.dart';
import '../../../shared/services/jamendo_music_provider.dart';
import '../../../shared/services/fallback_music_provider.dart';

/// The active music provider with automatic fallback.
/// JioSaavn (primary) → Jamendo (backup).
/// If JioSaavn goes down, Jamendo kicks in automatically.
final musicProviderProvider = Provider<MusicProvider>((ref) {
  return FallbackMusicProvider([
    SaavnMusicProvider(),    // Primary: Bollywood, Hindi, Tamil, etc.
    JamendoMusicProvider(),  // Fallback: royalty-free licensed music
  ]);
});

final searchRepositoryProvider = Provider((ref) {
  return SearchRepository(ref.read(musicProviderProvider));
});

class SearchState {
  final List<TrackModel> results;
  final bool isLoading;
  final String? error;
  final String query;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  SearchState copyWith({
    List<TrackModel>? results,
    bool? isLoading,
    String? error,
    String? query,
  }) =>
      SearchState(
        results: results ?? this.results,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        query: query ?? this.query,
      );
}

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repo;

  SearchNotifier(this._repo) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(isLoading: true, query: query, error: null);
    try {
      final results = await _repo.searchAll(query);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const SearchState();
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(searchRepositoryProvider));
});
