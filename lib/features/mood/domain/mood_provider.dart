import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mood_repository.dart';
import '../../search/domain/search_provider.dart';
import '../../../shared/models/track_model.dart';

import '../../home/domain/home_provider.dart';

final moodRepositoryProvider = Provider((ref) {
  return MoodRepository(ref.read(musicProviderProvider));
});

class MoodState {
  final List<TrackModel> tracks;
  final bool isLoading;
  final String? error;
  final String currentMood;

  const MoodState({
    required this.tracks,
    required this.isLoading,
    required this.error,
    required this.currentMood,
  });

  const MoodState.initial()
      : tracks = const [],
        isLoading = false,
        error = null,
        currentMood = '';

  MoodState copyWith({
    List<TrackModel>? tracks,
    bool? isLoading,
    String? error,
    String? currentMood,
  }) =>
      MoodState(
        tracks: tracks ?? this.tracks,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        currentMood: currentMood ?? this.currentMood,
      );
}

class MoodNotifier extends StateNotifier<MoodState> {
  final MoodRepository _repo;
  final Ref _ref;

  MoodNotifier(this._repo, this._ref) : super(const MoodState.initial());

  Future<void> generatePlaylist(String mood) async {
    if (mood.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, currentMood: mood, error: null);
    try {
      final selectedLang = _ref.read(selectedLanguageProvider);
      final tracks = await _repo.getMoodPlaylist(mood, [selectedLang]);
      state = state.copyWith(tracks: tracks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final moodProvider =
    StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  return MoodNotifier(ref.read(moodRepositoryProvider), ref);
});
