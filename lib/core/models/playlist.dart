import 'song.dart';

// Remote JioSaavn playlist
class Playlist {
  final String id;
  final String name;
  final String? description;
  final String artworkUrl;
  final int songCount;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.artworkUrl,
    this.songCount = 0,
    this.songs = const [],
  });

  String get highResArtworkUrl => artworkUrl.replaceAll('150x150', '500x500');

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final songsData = json['songs'] as List<dynamic>?;
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      artworkUrl: (json['image'] as List<dynamic>?)?.lastOrNull?['url'] as String? ?? '',
      songCount: int.tryParse(json['songCount']?.toString() ?? '0') ?? 0,
      songs: songsData?.map((s) => Song.fromJson(s as Map<String, dynamic>)).toList() ?? [],
    );
  }
}
