// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadStatusAdapter extends TypeAdapter<DownloadStatus> {
  @override
  final typeId = 10;

  @override
  DownloadStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DownloadStatus.notDownloaded;
      case 1:
        return DownloadStatus.queued;
      case 2:
        return DownloadStatus.downloading;
      case 3:
        return DownloadStatus.paused;
      case 4:
        return DownloadStatus.completed;
      case 5:
        return DownloadStatus.failed;
      default:
        return DownloadStatus.notDownloaded;
    }
  }

  @override
  void write(BinaryWriter writer, DownloadStatus obj) {
    switch (obj) {
      case DownloadStatus.notDownloaded:
        writer.writeByte(0);
        break;
      case DownloadStatus.queued:
        writer.writeByte(1);
        break;
      case DownloadStatus.downloading:
        writer.writeByte(2);
        break;
      case DownloadStatus.paused:
        writer.writeByte(3);
        break;
      case DownloadStatus.completed:
        writer.writeByte(4);
        break;
      case DownloadStatus.failed:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadedSongAdapter extends TypeAdapter<DownloadedSong> {
  @override
  final typeId = 11;

  @override
  DownloadedSong read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadedSong(
      id: fields[0] as String,
      songId: fields[1] as String,
      title: fields[2] as String,
      artist: fields[3] as String,
      imageUrl: fields[4] as String,
      localPath: fields[5] as String,
      fileSizeBytes: (fields[6] as num).toInt(),
      durationSeconds: (fields[7] as num?)?.toInt(),
      album: fields[8] as String?,
      source: fields[9] as String,
      downloadedAt: fields[10] as DateTime,
      lastPlayedAt: fields[11] as DateTime?,
      quality: (fields[12] as String?) ?? '160kbps',
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedSong obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.songId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.artist)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.localPath)
      ..writeByte(6)
      ..write(obj.fileSizeBytes)
      ..writeByte(7)
      ..write(obj.durationSeconds)
      ..writeByte(8)
      ..write(obj.album)
      ..writeByte(9)
      ..write(obj.source)
      ..writeByte(10)
      ..write(obj.downloadedAt)
      ..writeByte(11)
      ..write(obj.lastPlayedAt)
      ..writeByte(12)
      ..write(obj.quality);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedSongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadQueueItemAdapter extends TypeAdapter<DownloadQueueItem> {
  @override
  final typeId = 12;

  @override
  DownloadQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadQueueItem(
      id: fields[0] as String,
      track: fields[1] as TrackModel,
      status: fields[2] as DownloadStatus,
      progress: (fields[3] as num).toDouble(),
      bytesDownloaded: (fields[4] as num).toInt(),
      totalBytes: (fields[5] as num).toInt(),
      quality: (fields[6] as String?) ?? '160kbps',
      errorMessage: fields[7] as String?,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadQueueItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.track)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.progress)
      ..writeByte(4)
      ..write(obj.bytesDownloaded)
      ..writeByte(5)
      ..write(obj.totalBytes)
      ..writeByte(6)
      ..write(obj.quality)
      ..writeByte(7)
      ..write(obj.errorMessage)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadQueueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
