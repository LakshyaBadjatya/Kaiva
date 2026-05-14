import 'song.dart';

class Album {
  final String id;
  final String name;
  final String artworkUrl;
  final String? artistId;
  final String? artistName;
  final int? year;
  final String? language;
  final int songCount;
  final List<Song> songs;

  const Album({
    required this.id,
    required this.name,
    required this.artworkUrl,
    this.artistId,
    this.artistName,
    this.year,
    this.language,
    this.songCount = 0,
    this.songs = const [],
  });

  String get highResArtworkUrl => artworkUrl.replaceAll('150x150', '500x500');

  factory Album.fromJson(Map<String, dynamic> json) {
    final artistsJson = json['artists'] as Map<String, dynamic>?;
    final primary = (artistsJson?['primary'] as List<dynamic>?)?.firstOrNull as Map<String, dynamic>?;

    final songsData = json['songs'] as List<dynamic>?;

    return Album(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      artworkUrl: (json['image'] as List<dynamic>?)?.lastOrNull?['url'] as String? ?? '',
      artistId: primary?['id'] as String?,
      artistName: primary?['name'] as String?,
      year: int.tryParse(json['year']?.toString() ?? ''),
      language: json['language'] as String?,
      songCount: int.tryParse(json['songCount']?.toString() ?? '0') ?? 0,
      songs: songsData?.map((s) => Song.fromJson(s as Map<String, dynamic>)).toList() ?? [],
    );
  }
}
