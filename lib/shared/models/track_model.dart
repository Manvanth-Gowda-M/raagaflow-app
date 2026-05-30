import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

part 'track_model.g.dart';

@HiveType(typeId: 0)
class TrackModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String artist;
  @HiveField(3)
  final String imageUrl;
  @HiveField(4)
  final String source; // 'youtube' | 'jamendo' | 'pixabay'
  @HiveField(5)
  final String? streamUrl;
  @HiveField(6)
  final String? youtubeId;
  @HiveField(7)
  final int? durationSeconds;
  @HiveField(8)
  final String? album;
  @HiveField(9)
  final String? language;
  @HiveField(10)
  final String? license;

  const TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.source,
    this.streamUrl,
    this.youtubeId,
    this.durationSeconds,
    this.album,
    this.language,
    this.license,
  });

  factory TrackModel.fromYouTube(dynamic video) => TrackModel(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        imageUrl: video.thumbnails.highResUrl,
        source: 'youtube',
        youtubeId: video.id.value,
        durationSeconds: video.duration?.inSeconds,
      );

  /// Created by [SaavnMusicProvider] — streamUrl is already decrypted & ready to play.
  factory TrackModel.fromSaavn({
    required String id,
    required String title,
    required String artist,
    required String imageUrl,
    required String streamUrl,
    int? durationSeconds,
    String? album,
    String? language,
  }) =>
      TrackModel(
        id: id,
        title: title,
        artist: artist,
        imageUrl: imageUrl,
        source: 'saavn',
        streamUrl: streamUrl,
        durationSeconds: durationSeconds,
        album: album,
        language: language,
      );

  factory TrackModel.fromJamendo(Map<String, dynamic> json) => TrackModel(
        id: 'jamendo_${json['id']}',
        title: json['name'] ?? 'Unknown',
        artist: json['artist_name'] ?? 'Unknown Artist',
        imageUrl: json['album_image'] ?? '',
        source: 'jamendo',
        streamUrl: json['audio'],
        durationSeconds: int.tryParse(json['duration']?.toString() ?? '0'),
        album: json['album_name'],
        license: json['license_ccurl'],
      );

  factory TrackModel.fromPixabay(Map<String, dynamic> json) => TrackModel(
        id: 'pixabay_${json['id']}',
        title: json['tags'] ?? 'Pixabay Music',
        artist: json['user'] ?? 'Pixabay Artist',
        imageUrl: json['webformatURL'] ?? '',
        source: 'pixabay',
        streamUrl: json['url'],
        durationSeconds: json['duration'],
      );

  TrackModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? imageUrl,
    String? source,
    String? streamUrl,
    String? youtubeId,
    int? durationSeconds,
    String? album,
    String? language,
    String? license,
  }) =>
      TrackModel(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        imageUrl: imageUrl ?? this.imageUrl,
        source: source ?? this.source,
        streamUrl: streamUrl ?? this.streamUrl,
        youtubeId: youtubeId ?? this.youtubeId,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        album: album ?? this.album,
        language: language ?? this.language,
        license: license ?? this.license,
      );

  @override
  List<Object?> get props => [id];
}
