import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/track_model.dart';
import '../models/playlist_model.dart';
import '../models/download_model.dart';

class HiveService {
  static const String favoritesBox = 'favorites';
  static const String historyBox = 'history';
  static const String playlistsBox = 'playlists';
  static const String settingsBox = 'settings';
  static const String downloadsBox = 'downloads';
  static const String queueBox = 'download_queue';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TrackModelAdapter());
    Hive.registerAdapter(PlaylistModelAdapter());
    Hive.registerAdapter(DownloadStatusAdapter());
    Hive.registerAdapter(DownloadedSongAdapter());
    Hive.registerAdapter(DownloadQueueItemAdapter());

    await Hive.openBox<TrackModel>(favoritesBox);
    await Hive.openBox<TrackModel>(historyBox);
    await Hive.openBox<PlaylistModel>(playlistsBox);
    await Hive.openBox<dynamic>(settingsBox);
    await Hive.openBox<DownloadedSong>(downloadsBox);
    await Hive.openBox<DownloadQueueItem>(queueBox);
  }

  static Box<TrackModel> get favorites => Hive.box(favoritesBox);
  static Box<TrackModel> get history => Hive.box(historyBox);
  static Box<PlaylistModel> get playlists => Hive.box(playlistsBox);
  static Box<dynamic> get settings => Hive.box(settingsBox);
  static Box<DownloadedSong> get downloads => Hive.box(downloadsBox);
  static Box<DownloadQueueItem> get queue => Hive.box(queueBox);
}
