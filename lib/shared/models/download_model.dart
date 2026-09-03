import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';
import 'track_model.dart';

part 'download_model.g.dart';

@HiveType(typeId: 10)
enum DownloadStatus {
  @HiveField(0)
  notDownloaded,
  @HiveField(1)
  queued,
  @HiveField(2)
  downloading,
  @HiveField(3)
  paused,
  @HiveField(4)
  completed,
  @HiveField(5)
  failed,
}

@HiveType(typeId: 11)
class DownloadedSong extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String songId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String artist;
  @HiveField(4)
  final String imageUrl;
  @HiveField(5)
  final String localPath;
  @HiveField(6)
  final int fileSizeBytes;
  @HiveField(7)
  final int? durationSeconds;
  @HiveField(8)
  final String? album;
  @HiveField(9)
  final String source;
  @HiveField(10)
  final DateTime downloadedAt;
  @HiveField(11)
  final DateTime? lastPlayedAt;
  @HiveField(12)
  final String quality;

  const DownloadedSong({
    required this.id,
    required this.songId,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.localPath,
    required this.fileSizeBytes,
    this.durationSeconds,
    this.album,
    required this.source,
    required this.downloadedAt,
    this.lastPlayedAt,
    this.quality = '160kbps',
  });

  TrackModel toTrack() {
    return TrackModel(
      id: songId,
      title: title,
      artist: artist,
      imageUrl: imageUrl,
      source: 'offline',
      streamUrl: localPath,
      durationSeconds: durationSeconds,
      album: album,
    );
  }

  DownloadedSong copyWith({
    String? id,
    String? songId,
    String? title,
    String? artist,
    String? imageUrl,
    String? localPath,
    int? fileSizeBytes,
    int? durationSeconds,
    String? album,
    String? source,
    DateTime? downloadedAt,
    DateTime? lastPlayedAt,
    String? quality,
  }) {
    return DownloadedSong(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      album: album ?? this.album,
      source: source ?? this.source,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      quality: quality ?? this.quality,
    );
  }

  @override
  List<Object?> get props => [id, songId, localPath, fileSizeBytes];
}

@HiveType(typeId: 12)
class DownloadQueueItem extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final TrackModel track;
  @HiveField(2)
  final DownloadStatus status;
  @HiveField(3)
  final double progress;
  @HiveField(4)
  final int bytesDownloaded;
  @HiveField(5)
  final int totalBytes;
  @HiveField(6)
  final String quality;
  @HiveField(7)
  final String? errorMessage;
  @HiveField(8)
  final DateTime createdAt;

  const DownloadQueueItem({
    required this.id,
    required this.track,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.quality = '160kbps',
    this.errorMessage,
    required this.createdAt,
  });

  DownloadQueueItem copyWith({
    String? id,
    TrackModel? track,
    DownloadStatus? status,
    double? progress,
    int? bytesDownloaded,
    int? totalBytes,
    String? quality,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return DownloadQueueItem(
      id: id ?? this.id,
      track: track ?? this.track,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      quality: quality ?? this.quality,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, track.id, status, progress, bytesDownloaded];
}
