import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/db_song_ext.dart';
import '../../core/models/song.dart';
import '../../core/models/album.dart';
import '../../core/models/playlist.dart';
import '../../core/models/artist.dart';
import '../../core/utils/settings_keys.dart';
import '../../providers/connectivity_provider.dart';

// ── Continue Listening ────────────────────────────────────────
final continueListeningProvider = StreamProvider<List<Song>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.recentlyPlayedDao
      .watchRecentlyPlayed(limit: 10)
      .map((rows) => rows.toModels());
});

// ── Language selection ────────────────────────────────────────
final selectedLanguageProvider =
    StateNotifierProvider<LanguageNotifier, String>((ref) => LanguageNotifier());

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier()
      : super(
          Hive.box('kaiva_settings')
              .get(SettingsKeys.selectedLanguage, defaultValue: 'hindi') as String,
        );

  void select(String lang) {
    Hive.box('kaiva_settings').put(SettingsKeys.selectedLanguage, lang);
    state = lang;
  }
}

// ── Home feed model ───────────────────────────────────────────
class HomeFeed {
  final List<Song>     trending;
  final List<Album>    newReleases;
  final List<Playlist> featuredPlaylists;
  final List<Artist>   popularArtists;

  const HomeFeed({
    this.trending        = const [],
    this.newReleases     = const [],
    this.featuredPlaylists = const [],
    this.popularArtists  = const [],
  });
}

// ── Home feed provider ────────────────────────────────────────
final homeFeedProvider =
    FutureProvider.family<HomeFeed, String>((ref, language) async {
  ref.keepAlive();
  final isOnline = ref.watch(isOnlineProvider);
  final db = ref.watch(databaseProvider);

  // No connectivity at all — go straight to local DB
  if (!isOnline) {
    final downloaded = await db.songsDao.getDownloadedSongs();
    final liked = await db.likedSongsDao.watchLikedSongs().first;
    final localSongs = {
      ...downloaded.toModels(),
      ...liked.toModels(),
    }.toList();
    return HomeFeed(trending: localSongs.take(20).toList());
  }

  final api = ApiClient.instance();

  List<Song> parseSongs(dynamic raw) {
    final list = (raw as List<dynamic>?) ?? [];
    return list.map((e) {
      try { return Song.fromJson(e as Map<String, dynamic>); }
      catch (_) { return null; }
    }).whereType<Song>().toList();
  }

  List<Album> parseAlbums(dynamic raw) {
    final list = (raw as List<dynamic>?) ?? [];
    return list.map((e) {
      try { return Album.fromJson(e as Map<String, dynamic>); }
      catch (_) { return null; }
    }).whereType<Album>().toList();
  }

  List<Playlist> parsePlaylists(dynamic raw) {
    final list = (raw as List<dynamic>?) ?? [];
    return list.map((e) {
      try { return Playlist.fromJson(e as Map<String, dynamic>); }
      catch (_) { return null; }
    }).whereType<Playlist>().toList();
  }

  List<Artist> parseArtists(dynamic raw) {
    final list = (raw as List<dynamic>?) ?? [];
    return list.map((e) {
      try { return Artist.fromJson(e as Map<String, dynamic>); }
      catch (_) { return null; }
    }).whereType<Artist>().toList();
  }

  // "All" uses a comma-joined list of major languages for the modules endpoint
  final apiLanguage = language == 'all'
      ? 'hindi,english,punjabi,tamil,telugu'
      : language;

  // Try /api/modules first; fall back to search-based trending if 404
  try {
    final response = await api.get(
      ApiEndpoints.trending, params: {'language': apiLanguage},
    );
    final data = (response.data as Map<String, dynamic>?)?['data']
        as Map<String, dynamic>? ?? {};

    final trending = parseSongs(
      data['trending']?['songs'] ?? data['charts'] ?? [],
    );
    final newReleases = parseAlbums(
      data['albums'] ?? data['new_releases'] ?? [],
    );
    final featured = parsePlaylists(
      data['playlists'] ?? data['featured_playlists'] ?? [],
    );
    final artists = parseArtists(
      data['artists'] ?? data['top_artists'] ?? [],
    );

    if (trending.isNotEmpty || newReleases.isNotEmpty) {
      return HomeFeed(
        trending: trending.take(10).toList(),
        newReleases: newReleases.take(10).toList(),
        featuredPlaylists: featured.take(6).toList(),
        popularArtists: artists.take(8).toList(),
      );
    }
  } catch (_) {
    // Fall through to search-based fallback
  }

  // Fallback: build home feed from search queries per language
  final trendingQuery = switch (language) {
    'all'      => 'top hits 2025',
    'hindi'    => 'hindi hits 2025',
    'tamil'    => 'tamil hits 2025',
    'telugu'   => 'telugu hits 2025',
    'punjabi'  => 'punjabi hits 2025',
    'bengali'  => 'bengali hits 2025',
    'marathi'  => 'marathi hits 2025',
    'kannada'  => 'kannada hits 2025',
    'malayalam'=> 'malayalam hits 2025',
    _          => '$language hits 2025',
  };

  // Wrap each request so a single timeout doesn't block the rest
  Future<dynamic> safe(Future<dynamic> f) => f.catchError((_) => null);

  final langLabel = language == 'all' ? 'indian' : language;
  final results = await Future.wait([
    safe(api.get(ApiEndpoints.searchSongs, params: {'query': trendingQuery, 'limit': '10'})),
    safe(api.get(ApiEndpoints.searchSongs, params: {'query': 'new $langLabel songs 2025', 'limit': '10'})),
    safe(api.get(ApiEndpoints.searchAlbums, params: {'query': trendingQuery, 'limit': '6'})),
    safe(api.get(ApiEndpoints.searchArtists, params: {'query': '$langLabel artists', 'limit': '8'})),
    safe(api.get(ApiEndpoints.searchPlaylists, params: {'query': '$langLabel top', 'limit': '6'})),
  ]);

  List<Song> extractSongs(dynamic resp) {
    if (resp == null) return [];
    final data = (resp.data as Map<String, dynamic>?)?['data'];
    return parseSongs((data as Map<String, dynamic>?)?['results'] ?? []);
  }
  List<Album> extractAlbums(dynamic resp) {
    if (resp == null) return [];
    final data = (resp.data as Map<String, dynamic>?)?['data'];
    return parseAlbums((data as Map<String, dynamic>?)?['results'] ?? []);
  }
  List<Artist> extractArtists(dynamic resp) {
    if (resp == null) return [];
    final data = (resp.data as Map<String, dynamic>?)?['data'];
    return parseArtists((data as Map<String, dynamic>?)?['results'] ?? []);
  }
  List<Playlist> extractPlaylists(dynamic resp) {
    if (resp == null) return [];
    final data = (resp.data as Map<String, dynamic>?)?['data'];
    return parsePlaylists((data as Map<String, dynamic>?)?['results'] ?? []);
  }

  final feed = HomeFeed(
    trending:          extractSongs(results[0]).take(10).toList(),
    newReleases:       extractAlbums(results[2]).take(10).toList(),
    featuredPlaylists: extractPlaylists(results[4]).take(6).toList(),
    popularArtists:    extractArtists(results[3]).take(8).toList(),
  );

  // API returned nothing — fall back to local DB before giving up
  if (feed.trending.isEmpty && feed.newReleases.isEmpty &&
      feed.featuredPlaylists.isEmpty && feed.popularArtists.isEmpty) {
    final downloaded = await db.songsDao.getDownloadedSongs();
    final liked = await db.likedSongsDao.watchLikedSongs().first;
    final localSongs = {
      ...downloaded.toModels(),
      ...liked.toModels(),
    }.toList();
    if (localSongs.isNotEmpty) {
      return HomeFeed(trending: localSongs.take(20).toList());
    }
    throw Exception('No content available. Make sure the proxy is running.');
  }

  return feed;
});
