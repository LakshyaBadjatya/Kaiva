import 'song.dart';

class LocalPlaylist {
  final String id;
  final String name;
  final String? description;
  final String? coverPath;
  final String? coverUrl;
  final int songCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Song> songs;

  const LocalPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.coverPath,
    this.coverUrl,
    required this.songCount,
    required this.createdAt,
    required this.updatedAt,
    this.songs = const [],
  });

  String? get coverSource => coverPath ?? coverUrl;
}
