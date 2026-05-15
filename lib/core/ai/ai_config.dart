// ─────────────────────────────────────────────────────────────
//  AI / external integration credentials
//
//  ⚠️  These keys ship inside the APK. Fine for a personal build,
//  but if Kaiva is ever published, move them behind a proxy.
//  Centralised here so they are trivial to swap or remove.
// ─────────────────────────────────────────────────────────────

class AiConfig {
  AiConfig._();

  // ── NVIDIA NIM (mood detection) ─────────────────────────────
  static const String nvidiaBaseUrl = 'https://integrate.api.nvidia.com/v1';
  static const String nvidiaApiKey =
      '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';
  static const String nvidiaModel = 'meta/llama-3.3-70b-instruct';

  static bool get hasNvidiaKey =>
      nvidiaApiKey.isNotEmpty && nvidiaApiKey.startsWith('nvapi-');

  // ── Spotify (public playlist import) ────────────────────────
  // Create an app at https://developer.spotify.com/dashboard and
  // paste the Client ID / Secret here to enable Spotify import.
  static const String spotifyClientId = '';
  static const String spotifyClientSecret = '';

  static bool get hasSpotifyCredentials =>
      spotifyClientId.isNotEmpty && spotifyClientSecret.isNotEmpty;

  // ── Song recognition (Shazam-style) ─────────────────────────
  // UI + mic capture is built. Plug an ACRCloud or AudD.io key
  // here to enable real recognition. Leave empty for stub mode.
  static const String acrCloudHost = '';
  static const String acrCloudAccessKey = '';
  static const String acrCloudAccessSecret = '';

  static bool get hasSongRecognitionKey =>
      acrCloudHost.isNotEmpty && acrCloudAccessKey.isNotEmpty;
}
