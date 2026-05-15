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

  factory Artist.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    String? imageUrl;
    if (image is List && image.isNotEmpty) {
      final last = image.last;
      if (last is Map) imageUrl = last['url'] as String?;
    } else if (image is String) {
      imageUrl = image;
    }

    Song? _safeSong(dynamic s) {
      if (s is! Map<String, dynamic>) return null;
      try { return Song.fromJson(s); } catch (_) { return null; }
    }

    Album? _safeAlbum(dynamic a) {
      if (a is! Map<String, dynamic>) return null;
      try { return Album.fromJson(a); } catch (_) { return null; }
    }

    Artist? _safeArtist(dynamic a) {
      if (a is! Map<String, dynamic>) return null;
      try { return Artist.fromJson(a); } catch (_) { return null; }
    }

    return Artist(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      imageUrl: imageUrl,
      followerCount: int.tryParse(json['followerCount']?.toString() ?? ''),
      bio: json['bio'] as String?,
      topSongs: (json['topSongs'] as List<dynamic>? ?? [])
          .map(_safeSong)
          .whereType<Song>()
          .toList(),
      albums: (json['topAlbums'] as List<dynamic>? ?? [])
          .map(_safeAlbum)
          .whereType<Album>()
          .toList(),
      similarArtists: (json['similarArtists'] as List<dynamic>? ?? [])
          .map(_safeArtist)
          .whereType<Artist>()
          .toList(),
    );
  }
}
