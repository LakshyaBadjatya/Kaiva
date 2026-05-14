import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/kaiva_database.dart' hide Song;
import '../../../core/models/song.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';

// ── Models ────────────────────────────────────────────────────

class _SpotifyPlaylist {
  final String id;
  final String name;
  final String? imageUrl;
  final int trackCount;

  const _SpotifyPlaylist({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.trackCount,
  });
}

class _SpotifyTrack {
  final String name;
  final String artist;

  const _SpotifyTrack({required this.name, required this.artist});
}

// ── Import result ─────────────────────────────────────────────

class _ImportResult {
  final String playlistName;
  final int matched;
  final int total;

  const _ImportResult({
    required this.playlistName,
    required this.matched,
    required this.total,
  });
}

// ── Screen ────────────────────────────────────────────────────

class SpotifyImportScreen extends ConsumerStatefulWidget {
  const SpotifyImportScreen({super.key});

  @override
  ConsumerState<SpotifyImportScreen> createState() => _SpotifyImportScreenState();
}

class _SpotifyImportScreenState extends ConsumerState<SpotifyImportScreen> {
  final _usernameCtrl = TextEditingController();

  // Step 0 = enter username, 1 = select playlists, 2 = importing, 3 = done
  int _step = 0;
  bool _loading = false;
  String? _error;

  List<_SpotifyPlaylist> _playlists = [];
  final Set<String> _selected = {};

  List<_ImportResult> _results = [];

  final _spotifyDio = Dio(BaseOptions(
    baseUrl: 'https://api.spotify.com/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // Client credentials token (public playlists only — no user login needed)
  String? _accessToken;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  // ── Spotify public API helpers ────────────────────────────────

  Future<void> _authenticate() async {
    // Spotify client credentials flow using the public demo credentials.
    // These only allow reading public playlists — no user data is accessed.
    const clientId     = 'YOUR_SPOTIFY_CLIENT_ID';
    const clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';

    final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
    final resp = await Dio().post(
      'https://accounts.spotify.com/api/token',
      data: 'grant_type=client_credentials',
      options: Options(
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
    );
    _accessToken = resp.data['access_token'] as String?;
    if (_accessToken != null) {
      _spotifyDio.options.headers['Authorization'] = 'Bearer $_accessToken';
    }
  }

  Future<List<_SpotifyPlaylist>> _fetchPlaylists(String userId) async {
    if (_accessToken == null) await _authenticate();
    final resp = await _spotifyDio.get(
      '/users/$userId/playlists',
      queryParameters: {'limit': 50},
    );
    final items = (resp.data['items'] as List<dynamic>?) ?? [];
    return items.map((item) {
      final images = (item['images'] as List<dynamic>?) ?? [];
      return _SpotifyPlaylist(
        id:         item['id'] as String,
        name:       item['name'] as String? ?? 'Playlist',
        imageUrl:   images.isNotEmpty ? images.first['url'] as String? : null,
        trackCount: (item['tracks']?['total'] as int?) ?? 0,
      );
    }).toList();
  }

  Future<List<_SpotifyTrack>> _fetchTracks(String playlistId) async {
    final tracks = <_SpotifyTrack>[];
    String? nextUrl = '/playlists/$playlistId/tracks?limit=50&fields=next,items(track(name,artists))';

    while (nextUrl != null) {
      final resp = await _spotifyDio.get(nextUrl);
      final items = (resp.data['items'] as List<dynamic>?) ?? [];
      for (final item in items) {
        final track = item['track'] as Map<String, dynamic>?;
        if (track == null) continue;
        final name = track['name'] as String? ?? '';
        final artists = (track['artists'] as List<dynamic>?) ?? [];
        final artist = artists.isNotEmpty
            ? artists.first['name'] as String? ?? ''
            : '';
        if (name.isNotEmpty) tracks.add(_SpotifyTrack(name: name, artist: artist));
      }
      nextUrl = resp.data['next'] as String?;
      if (nextUrl != null) {
        // next is a full URL — strip base
        nextUrl = nextUrl.replaceFirst('https://api.spotify.com/v1', '');
      }
    }
    return tracks;
  }

  // ── JioSaavn search ───────────────────────────────────────────

  Future<Song?> _searchSong(String title, String artist) async {
    try {
      final api = ApiClient.instance();
      final resp = await api.get(
        ApiEndpoints.searchSongs,
        params: {'query': '$title $artist', 'limit': '3'},
      );
      final data = (resp.data as Map<String, dynamic>?)?['data'];
      final results = ((data as Map<String, dynamic>?)?['results'] as List<dynamic>?) ?? [];
      if (results.isEmpty) return null;
      return Song.fromJson(results.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Steps ─────────────────────────────────────────────────────

  Future<void> _loadPlaylists() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Enter your Spotify username.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final playlists = await _fetchPlaylists(username);
      if (playlists.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No public playlists found for "$username".';
        });
        return;
      }
      setState(() {
        _playlists = playlists;
        _loading = false;
        _step = 1;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load playlists. Make sure your Spotify profile is public.';
      });
    }
  }

  Future<void> _importSelected() async {
    if (_selected.isEmpty) return;
    setState(() { _step = 2; _loading = true; _results = []; });

    final db = ref.read(databaseProvider);
    final results = <_ImportResult>[];

    for (final playlistId in _selected) {
      final playlist = _playlists.firstWhere((p) => p.id == playlistId);
      try {
        final tracks = await _fetchTracks(playlistId);
        final localId = const Uuid().v4();

        await db.playlistsDao.createPlaylist(LocalPlaylistsCompanion(
          id:          Value(localId),
          name:        Value(playlist.name),
          description: const Value('Imported from Spotify'),
          coverUrl:    Value(playlist.imageUrl),
          songCount:   const Value(0),
          createdAt:   Value(DateTime.now()),
          updatedAt:   Value(DateTime.now()),
        ));

        int matched = 0;
        for (int i = 0; i < tracks.length; i++) {
          final t = tracks[i];
          final song = await _searchSong(t.name, t.artist);
          if (song == null) continue;
          // Upsert song into songs table
          await db.songsDao.upsertSong(SongsCompanion(
            id:         Value(song.id),
            title:      Value(song.title),
            artist:     Value(song.artist),
            artistId:   Value(song.artistId),
            album:      Value(song.album),
            albumId:    Value(song.albumId),
            artworkUrl: Value(song.artworkUrl),
            duration:   Value(song.durationSeconds),
            language:   Value(song.language),
            streamUrl:  Value(song.bestStreamUrl.isNotEmpty ? song.bestStreamUrl : null),
            hasLyrics:  Value(song.hasLyrics),
            isExplicit: Value(song.isExplicit),
            year:       Value(song.year),
          ));
          await db.playlistsDao.addSongToPlaylist(localId, song.id, i);
          matched++;
        }

        results.add(_ImportResult(
          playlistName: playlist.name,
          matched: matched,
          total: tracks.length,
        ));
      } catch (_) {
        results.add(_ImportResult(
          playlistName: playlist.name,
          matched: 0,
          total: 0,
        ));
      }
    }

    setState(() {
      _results = results;
      _loading = false;
      _step = 3;
    });
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Spotify', style: KaivaTextStyles.headlineLarge),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          0 => _buildUsernameStep(),
          1 => _buildSelectStep(),
          2 => _buildImportingStep(),
          3 => _buildDoneStep(),
          _  => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildUsernameStep() {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your Spotify username to import your public playlists.',
            style: KaivaTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your playlists must be set to public in Spotify settings.',
            style: KaivaTextStyles.bodySmall.copyWith(color: KaivaColors.textMuted),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _usernameCtrl,
            style: KaivaTextStyles.bodyMedium,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _loadPlaylists(),
            decoration: InputDecoration(
              labelText: 'Spotify Username',
              labelStyle: KaivaTextStyles.bodySmall,
              hintText: 'e.g. 31xxxabcxxx',
              hintStyle: KaivaTextStyles.bodySmall.copyWith(color: KaivaColors.textDisabled),
              filled: true,
              fillColor: KaivaColors.backgroundTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KaivaColors.accentPrimary, width: 1.5),
              ),
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  color: KaivaColors.textMuted, size: 20),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: KaivaColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _loading ? null : _loadPlaylists,
              style: FilledButton.styleFrom(
                backgroundColor: KaivaColors.accentPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: KaivaColors.textOnAccent))
                  : const Text('Find Playlists',
                      style: TextStyle(color: KaivaColors.textOnAccent, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectStep() {
    return Column(
      key: const ValueKey(1),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_playlists.length} public playlists found',
                  style: KaivaTextStyles.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  if (_selected.length == _playlists.length) {
                    _selected.clear();
                  } else {
                    _selected.addAll(_playlists.map((p) => p.id));
                  }
                }),
                child: Text(
                  _selected.length == _playlists.length ? 'Deselect all' : 'Select all',
                  style: const TextStyle(color: KaivaColors.accentPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _playlists.length,
            itemBuilder: (context, i) {
              final p = _playlists[i];
              final isSelected = _selected.contains(p.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (v) => setState(() {
                  if (v == true) _selected.add(p.id);
                  else _selected.remove(p.id);
                }),
                activeColor: KaivaColors.accentPrimary,
                title: Text(p.name, style: KaivaTextStyles.bodyMedium),
                subtitle: Text(
                  '${p.trackCount} tracks',
                  style: KaivaTextStyles.bodySmall,
                ),
                secondary: p.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(p.imageUrl!,
                            width: 44, height: 44, fit: BoxFit.cover),
                      )
                    : Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: KaivaColors.backgroundTertiary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.queue_music_rounded,
                            color: KaivaColors.textMuted, size: 22),
                      ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _selected.isEmpty ? null : _importSelected,
              style: FilledButton.styleFrom(
                backgroundColor: KaivaColors.accentPrimary,
                disabledBackgroundColor: KaivaColors.backgroundTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _selected.isEmpty
                    ? 'Select playlists to import'
                    : 'Import ${_selected.length} playlist${_selected.length == 1 ? '' : 's'}',
                style: const TextStyle(color: KaivaColors.textOnAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportingStep() {
    return const Center(
      key: ValueKey(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: KaivaColors.accentPrimary),
          SizedBox(height: 24),
          Text('Matching songs on JioSaavn…', style: KaivaTextStyles.bodyMedium),
          SizedBox(height: 8),
          Text(
            'This may take a minute depending on playlist size.',
            style: KaivaTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    final totalMatched = _results.fold(0, (sum, r) => sum + r.matched);
    final totalTracks  = _results.fold(0, (sum, r) => sum + r.total);

    return Padding(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: KaivaColors.success, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Import complete!',
                  style: KaivaTextStyles.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Matched $totalMatched of $totalTracks tracks across ${_results.length} playlist${_results.length == 1 ? '' : 's'}.',
            style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: KaivaColors.borderSubtle, height: 1),
              itemBuilder: (context, i) {
                final r = _results[i];
                final pct = r.total > 0
                    ? (r.matched / r.total * 100).round()
                    : 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.playlistName, style: KaivaTextStyles.bodyMedium),
                  subtitle: Text(
                    '${r.matched} / ${r.total} matched ($pct%)',
                    style: KaivaTextStyles.bodySmall,
                  ),
                  trailing: Icon(
                    pct >= 80
                        ? Icons.check_circle_outline_rounded
                        : Icons.warning_amber_rounded,
                    color: pct >= 80
                        ? KaivaColors.success
                        : KaivaColors.warning,
                    size: 20,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => setState(() {
                _step = 0;
                _selected.clear();
                _playlists.clear();
                _results.clear();
                _usernameCtrl.clear();
              }),
              style: FilledButton.styleFrom(
                backgroundColor: KaivaColors.accentPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Import More',
                  style: TextStyle(color: KaivaColors.textOnAccent, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
