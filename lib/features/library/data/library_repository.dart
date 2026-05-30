import '../../../core/constants/app_constants.dart';
import '../../../shared/models/playlist_model.dart';
import '../../../shared/models/track_model.dart';
import '../../../shared/services/hive_service.dart';

class LibraryRepository {
  void toggleFavorite(TrackModel track) {
    final box = HiveService.favorites;
    if (box.containsKey(track.id)) {
      box.delete(track.id);
    } else {
      box.put(track.id, track);
    }
  }

  bool isFavorite(String trackId) =>
      HiveService.favorites.containsKey(trackId);

  List<TrackModel> getFavorites() =>
      HiveService.favorites.values.toList().reversed.toList();

  void addToHistory(TrackModel track) {
    final box = HiveService.history;
    box.delete(track.id);
    box.put(track.id, track);
    if (box.length > AppConstants.maxHistory) {
      box.deleteAt(0);
    }
  }

  List<TrackModel> getHistory() =>
      HiveService.history.values.toList().reversed.toList();

  void createPlaylist(String name) {
    final playlist = PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      tracks: const [],
      createdAt: DateTime.now(),
    );
    HiveService.playlists.put(playlist.id, playlist);
  }

  List<PlaylistModel> getPlaylists() =>
      HiveService.playlists.values.toList();

  void addTrackToPlaylist(String playlistId, TrackModel track) {
    final playlist = HiveService.playlists.get(playlistId);
    if (playlist == null) return;
    final updated = playlist.copyWith(
      tracks: [...playlist.tracks, track],
      coverImageUrl: playlist.coverImageUrl ?? track.imageUrl,
    );
    HiveService.playlists.put(playlistId, updated);
  }

  void removeTrackFromPlaylist(String playlistId, String trackId) {
    final playlist = HiveService.playlists.get(playlistId);
    if (playlist == null) return;
    final updated = playlist.copyWith(
      tracks: playlist.tracks.where((t) => t.id != trackId).toList(),
    );
    HiveService.playlists.put(playlistId, updated);
  }

  void deletePlaylist(String playlistId) =>
      HiveService.playlists.delete(playlistId);
}
