import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/search_result.dart';
import '../../core/models/song.dart';
import '../../core/models/album.dart';
import '../../core/models/artist.dart';
import '../../core/models/playlist.dart';
import '../../core/utils/settings_keys.dart';

// ── Search query state ────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Recent searches (persisted to Hive) ──────────────────────
final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>(
        (ref) => RecentSearchesNotifier());

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  static const _maxRecent = 10;

  RecentSearchesNotifier()
      : super(
          List<String>.from(
            Hive.box('kaiva_settings')
                .get(SettingsKeys.recentSearches, defaultValue: <String>[]),
          ),
        );

  void add(String query) {
    if (query.trim().isEmpty) return;
    final updated = [
      query,
      ...state.where((s) => s != query),
    ].take(_maxRecent).toList();
    state = updated;
    Hive.box('kaiva_settings').put(SettingsKeys.recentSearches, updated);
  }

  void remove(String query) {
    final updated = state.where((s) => s != query).toList();
    state = updated;
    Hive.box('kaiva_settings').put(SettingsKeys.recentSearches, updated);
  }

  void clear() {
    state = [];
    Hive.box('kaiva_settings').put(SettingsKeys.recentSearches, <String>[]);
  }
}

// ── Debounced search results ──────────────────────────────────
final searchResultsProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<SearchResult?>>(
        (ref) => SearchNotifier(ref));

class SearchNotifier extends StateNotifier<AsyncValue<SearchResult?>> {
  final Ref _ref;
  Timer? _debounce;

  SearchNotifier(this._ref) : super(const AsyncValue.data(null));

  void search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetch(query));
  }

  Future<void> _fetch(String query) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance().get(
        ApiEndpoints.searchSongs,
        params: {'query': query, 'page': 1, 'limit': 10},
      );
      final data = (response.data as Map<String, dynamic>?)?['data']
              as Map<String, dynamic>? ??
          {};
      final results = (data['results'] as List<dynamic>?) ?? [];
      final songs = results.map((e) {
        try { return Song.fromJson(e as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<Song>().toList();
      state = AsyncValue.data(SearchResult(songs: songs));
      _ref.read(recentSearchesProvider.notifier).add(query);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ── Paginated search per category ────────────────────────────
class _PagedState<T> {
  final List<T> items;
  final bool hasMore;
  final bool isLoading;
  final int currentPage;

  const _PagedState({
    this.items = const [],
    this.hasMore = true,
    this.isLoading = false,
    this.currentPage = 1,
  });

  _PagedState<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? isLoading,
    int? currentPage,
  }) =>
      _PagedState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        isLoading: isLoading ?? this.isLoading,
        currentPage: currentPage ?? this.currentPage,
      );
}

// Songs pagination
final pagedSongsProvider =
    StateNotifierProvider.family<PagedSongsNotifier, _PagedState<Song>, String>(
        (ref, query) => PagedSongsNotifier(query));

class PagedSongsNotifier extends StateNotifier<_PagedState<Song>> {
  final String query;
  static const _pageSize = 20;

  PagedSongsNotifier(this.query) : super(const _PagedState()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiClient.instance().get(
        ApiEndpoints.searchSongs,
        params: {'query': query, 'page': state.currentPage, 'limit': _pageSize},
      );
      final data = (response.data as Map<String, dynamic>?)?['data']
              as Map<String, dynamic>? ??
          {};
      final results = (data['results'] as List<dynamic>?) ?? [];
      final songs = results
          .map((e) {
            try {
              return Song.fromJson(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Song>()
          .toList();
      state = state.copyWith(
        items: [...state.items, ...songs],
        hasMore: songs.length == _pageSize,
        isLoading: false,
        currentPage: state.currentPage + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }
}

// Albums pagination
final pagedAlbumsProvider = StateNotifierProvider.family<PagedAlbumsNotifier,
    _PagedState<Album>, String>((ref, query) => PagedAlbumsNotifier(query));

class PagedAlbumsNotifier extends StateNotifier<_PagedState<Album>> {
  final String query;
  static const _pageSize = 20;

  PagedAlbumsNotifier(this.query) : super(const _PagedState()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiClient.instance().get(
        ApiEndpoints.searchAlbums,
        params: {'query': query, 'page': state.currentPage, 'limit': _pageSize},
      );
      final data = (response.data as Map<String, dynamic>?)?['data']
              as Map<String, dynamic>? ??
          {};
      final results = (data['results'] as List<dynamic>?) ?? [];
      final albums = results
          .map((e) {
            try {
              return Album.fromJson(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Album>()
          .toList();
      state = state.copyWith(
        items: [...state.items, ...albums],
        hasMore: albums.length == _pageSize,
        isLoading: false,
        currentPage: state.currentPage + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }
}

// Artists pagination
final pagedArtistsProvider = StateNotifierProvider.family<PagedArtistsNotifier,
    _PagedState<Artist>, String>((ref, query) => PagedArtistsNotifier(query));

class PagedArtistsNotifier extends StateNotifier<_PagedState<Artist>> {
  final String query;
  static const _pageSize = 20;

  PagedArtistsNotifier(this.query) : super(const _PagedState()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiClient.instance().get(
        ApiEndpoints.searchArtists,
        params: {'query': query, 'page': state.currentPage, 'limit': _pageSize},
      );
      final data = (response.data as Map<String, dynamic>?)?['data']
              as Map<String, dynamic>? ??
          {};
      final results = (data['results'] as List<dynamic>?) ?? [];
      final artists = results
          .map((e) {
            try {
              return Artist.fromJson(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Artist>()
          .toList();
      state = state.copyWith(
        items: [...state.items, ...artists],
        hasMore: artists.length == _pageSize,
        isLoading: false,
        currentPage: state.currentPage + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }
}

// Playlists pagination
final pagedPlaylistsProvider =
    StateNotifierProvider.family<PagedPlaylistsNotifier, _PagedState<Playlist>,
        String>((ref, query) => PagedPlaylistsNotifier(query));

class PagedPlaylistsNotifier extends StateNotifier<_PagedState<Playlist>> {
  final String query;
  static const _pageSize = 20;

  PagedPlaylistsNotifier(this.query) : super(const _PagedState()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiClient.instance().get(
        ApiEndpoints.searchPlaylists,
        params: {'query': query, 'page': state.currentPage, 'limit': _pageSize},
      );
      final data = (response.data as Map<String, dynamic>?)?['data']
              as Map<String, dynamic>? ??
          {};
      final results = (data['results'] as List<dynamic>?) ?? [];
      final playlists = results
          .map((e) {
            try {
              return Playlist.fromJson(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Playlist>()
          .toList();
      state = state.copyWith(
        items: [...state.items, ...playlists],
        hasMore: playlists.length == _pageSize,
        isLoading: false,
        currentPage: state.currentPage + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }
}
