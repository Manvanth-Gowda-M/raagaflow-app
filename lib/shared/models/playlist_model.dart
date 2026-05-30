import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';
import 'track_model.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class PlaylistModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final List<TrackModel> tracks;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final String? coverImageUrl;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.tracks,
    required this.createdAt,
    this.coverImageUrl,
  });

  PlaylistModel copyWith({
    String? id,
    String? name,
    List<TrackModel>? tracks,
    DateTime? createdAt,
    String? coverImageUrl,
  }) =>
      PlaylistModel(
        id: id ?? this.id,
        name: name ?? this.name,
        tracks: tracks ?? this.tracks,
        createdAt: createdAt ?? this.createdAt,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      );

  @override
  List<Object?> get props => [id];
}
