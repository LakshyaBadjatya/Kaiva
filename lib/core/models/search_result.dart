import 'song.dart';
import 'album.dart';
import 'artist.dart';
import 'playlist.dart';

class SearchResult {
  final List<Song>     songs;
  final List<Album>    albums;
  final List<Artist>   artists;
  final List<Playlist> playlists;

  const SearchResult({
    this.songs     = const [],
    this.albums    = const [],
    this.artists   = const [],
    this.playlists = const [],
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    songs:     _parseSongs(json['songs']),
    albums:    _parseAlbums(json['albums']),
    artists:   _parseArtists(json['artists']),
    playlists: _parsePlaylists(json['playlists']),
  );

  static List<Song> _parseSongs(dynamic data) {
    final results = (data?['results'] as List<dynamic>?) ?? [];
    return results.map((s) {
      try { return Song.fromJson(s as Map<String, dynamic>); } catch (_) { return null; }
    }).whereType<Song>().toList();
  }

  static List<Album> _parseAlbums(dynamic data) {
    final results = (data?['results'] as List<dynamic>?) ?? [];
    return results.map((a) {
      try { return Album.fromJson(a as Map<String, dynamic>); } catch (_) { return null; }
    }).whereType<Album>().toList();
  }

  static List<Artist> _parseArtists(dynamic data) {
    final results = (data?['results'] as List<dynamic>?) ?? [];
    return results.map((a) {
      try { return Artist.fromJson(a as Map<String, dynamic>); } catch (_) { return null; }
    }).whereType<Artist>().toList();
  }

  static List<Playlist> _parsePlaylists(dynamic data) {
    final results = (data?['results'] as List<dynamic>?) ?? [];
    return results.map((p) {
      try { return Playlist.fromJson(p as Map<String, dynamic>); } catch (_) { return null; }
    }).whereType<Playlist>().toList();
  }
}
