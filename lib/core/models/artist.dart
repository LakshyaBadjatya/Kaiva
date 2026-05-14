import 'song.dart';
import 'album.dart';

class Artist {
  final String id;
  final String name;
  final String? imageUrl;
  final int? followerCount;
  final String? bio;
  final List<Song> topSongs;
  final List<Album> albums;
  final List<Artist> similarArtists;

  const Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.followerCount,
    this.bio,
    this.topSongs = const [],
    this.albums = const [],
    this.similarArtists = const [],
  });

  String get highResImageUrl =>
      (imageUrl ?? '').replaceAll('150x150', '500x500');

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
    id: json['id'] as String,
    name: json['name'] as String? ?? json['title'] as String? ?? '',
    imageUrl: (json['image'] as List<dynamic>?)?.lastOrNull?['url'] as String?,
    followerCount: int.tryParse(json['followerCount']?.toString() ?? ''),
    bio: json['bio'] as String?,
    topSongs: (json['topSongs'] as List<dynamic>? ?? [])
        .map((s) => Song.fromJson(s as Map<String, dynamic>))
        .toList(),
    albums: (json['topAlbums'] as List<dynamic>? ?? [])
        .map((a) => Album.fromJson(a as Map<String, dynamic>))
        .toList(),
    similarArtists: (json['similarArtists'] as List<dynamic>? ?? [])
        .map((a) => Artist.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}
