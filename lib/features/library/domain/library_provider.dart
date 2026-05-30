import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/library_repository.dart';
import '../../../shared/models/playlist_model.dart';
import '../../../shared/models/track_model.dart';

final libraryRepositoryProvider = Provider((ref) => LibraryRepository());

class LibraryState {
  final List<TrackModel> favorites;
  final List<TrackModel> history;
  final List<PlaylistModel> playlists;

  const LibraryState({
    this.favorites = const [],
    this.history = const [],
    this.playlists = const [],
  });

  LibraryState copyWith({
    List<TrackModel>? favorites,
    List<TrackModel>? history,
    List<PlaylistModel>? playlists,
  }) =>
      LibraryState(
        favorites: favorites ?? this.favorites,
        history: history ?? this.history,
        playlists: playlists ?? this.playlists,
      );
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final LibraryRepository _repo;

  LibraryNotifier(this._repo) : super(const LibraryState()) {
    _load();
  }

  void _load() {
    state = LibraryState(
      favorites: _repo.getFavorites(),
      history: _repo.getHistory(),
      playlists: _repo.getPlaylists(),
    );
  }

  void toggleFavorite(TrackModel track) {
    _repo.toggleFavorite(track);
    state = state.copyWith(favorites: _repo.getFavorites());
  }

  bool isFavorite(String trackId) => _repo.isFavorite(trackId);

  void addToHistory(TrackModel track) {
    _repo.addToHistory(track);
    state = state.copyWith(history: _repo.getHistory());
  }

  void createPlaylist(String name) {
    _repo.createPlaylist(name);
    state = state.copyWith(playlists: _repo.getPlaylists());
  }

  void addTrackToPlaylist(String playlistId, TrackModel track) {
    _repo.addTrackToPlaylist(playlistId, track);
    state = state.copyWith(playlists: _repo.getPlaylists());
  }

  void removeTrackFromPlaylist(String playlistId, String trackId) {
    _repo.removeTrackFromPlaylist(playlistId, trackId);
    state = state.copyWith(playlists: _repo.getPlaylists());
  }

  void deletePlaylist(String playlistId) {
    _repo.deletePlaylist(playlistId);
    state = state.copyWith(playlists: _repo.getPlaylists());
  }
}

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(ref.read(libraryRepositoryProvider));
});
