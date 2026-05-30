import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/track_model.dart';
import '../models/playlist_model.dart';

class HiveService {
  static const String favoritesBox = 'favorites';
  static const String historyBox = 'history';
  static const String playlistsBox = 'playlists';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TrackModelAdapter());
    Hive.registerAdapter(PlaylistModelAdapter());
    await Hive.openBox<TrackModel>(favoritesBox);
    await Hive.openBox<TrackModel>(historyBox);
    await Hive.openBox<PlaylistModel>(playlistsBox);
    await Hive.openBox<dynamic>(settingsBox);
  }

  static Box<TrackModel> get favorites => Hive.box(favoritesBox);
  static Box<TrackModel> get history => Hive.box(historyBox);
  static Box<PlaylistModel> get playlists => Hive.box(playlistsBox);
  static Box<dynamic> get settings => Hive.box(settingsBox);
}
