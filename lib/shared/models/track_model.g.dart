// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrackModelAdapter extends TypeAdapter<TrackModel> {
  @override
  final typeId = 0;

  @override
  TrackModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackModel(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      imageUrl: fields[3] as String,
      source: fields[4] as String,
      streamUrl: fields[5] as String?,
      youtubeId: fields[6] as String?,
      durationSeconds: (fields[7] as num?)?.toInt(),
      album: fields[8] as String?,
      language: fields[9] as String?,
      license: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TrackModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.streamUrl)
      ..writeByte(6)
      ..write(obj.youtubeId)
      ..writeByte(7)
      ..write(obj.durationSeconds)
      ..writeByte(8)
      ..write(obj.album)
      ..writeByte(9)
      ..write(obj.language)
      ..writeByte(10)
      ..write(obj.license);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
