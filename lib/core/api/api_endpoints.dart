class ApiEndpoints {
  ApiEndpoints._();

  static const String defaultBaseUrl   = 'https://jiosaavn-api-sigma-two.vercel.app';

  // ── Search ─────────────────────────────────────────────────
  static const String searchSongs      = '/api/search/songs';
  static const String searchAlbums     = '/api/search/albums';
  static const String searchArtists    = '/api/search/artists';
  static const String searchPlaylists  = '/api/search/playlists';
  static const String searchAll        = '/api/search';

  // ── Song ───────────────────────────────────────────────────
  static String song(String id)             => '/api/songs/$id';
  static String songSuggestions(String id)  => '/api/songs/$id/suggestions';
  static String lyrics(String id)           => '/api/songs/$id/lyrics';

  // ── Album ──────────────────────────────────────────────────
  static String album(String id)            => '/api/albums?id=$id';

  // ── Artist ─────────────────────────────────────────────────
  static String artist(String id)           => '/api/artists/$id';
  static String artistSongs(String id)      => '/api/artists/$id/songs';
  static String artistAlbums(String id)     => '/api/artists/$id/albums';

  // ── Playlist ───────────────────────────────────────────────
  static String playlist(String id)         => '/api/playlists/$id';

  // ── Charts / Trending ──────────────────────────────────────
  static const String trending             = '/api/modules';
  static const String charts              = '/api/charts';
}
