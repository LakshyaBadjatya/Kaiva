import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/playlist.dart';
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/library/library_provider.dart';
import '../../features/player/player_provider.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/song_tile.dart';

// Remote playlist provider
final remotePlaylistProvider =
    FutureProvider.family<Playlist, String>((ref, id) async {
  final response =
      await ApiClient.instance().get(ApiEndpoints.playlist(id));
  final data =
      (response.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?
          ?? {};
  return Playlist.fromJson(data);
});

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  final bool isLocal;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLocal) return _LocalPlaylistView(playlistId: playlistId);
    return _RemotePlaylistView(playlistId: playlistId);
  }
}

// ── Remote playlist ───────────────────────────────────────────
class _RemotePlaylistView extends ConsumerWidget {
  final String playlistId;
  const _RemotePlaylistView({required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(remotePlaylistProvider(playlistId));

    return playlistAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: ListView.builder(
          itemCount: 12,
          itemBuilder: (_, __) => const ShimmerSongTile(),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'Could not load playlist.',
            style: KaivaTextStyles.bodyMedium,
          ),
        ),
      ),
      data: (playlist) => _PlaylistScaffold(
        name: playlist.name,
        artworkUrl: playlist.highResArtworkUrl,
        description: playlist.description,
        songCount: playlist.songCount,
        songs: playlist.songs,
      ),
    );
  }
}

// ── Local playlist ────────────────────────────────────────────
class _LocalPlaylistView extends ConsumerWidget {
  final String playlistId;
  const _LocalPlaylistView({required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(localPlaylistSongsProvider(playlistId));
    final playlistsAsync = ref.watch(localPlaylistsProvider);

    final name = playlistsAsync.valueOrNull
            ?.firstWhere(
              (p) => p.id == playlistId,
              orElse: () => throw StateError('not found'),
            )
            .name ??
        'My Playlist';

    return songsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: ListView.builder(
          itemCount: 10,
          itemBuilder: (_, __) => const ShimmerSongTile(),
        ),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: const Center(child: Text('Could not load songs.')),
      ),
      data: (songs) => _PlaylistScaffold(
        name: name,
        songs: songs,
        isLocal: true,
      ),
    );
  }
}

// ── Shared scaffold ───────────────────────────────────────────
class _PlaylistScaffold extends ConsumerWidget {
  final String name;
  final String? artworkUrl;
  final String? description;
  final int songCount;
  final List<Song> songs;
  final bool isLocal;

  const _PlaylistScaffold({
    required this.name,
    this.artworkUrl,
    this.description,
    this.songCount = 0,
    required this.songs,
    this.isLocal = false,
  });

  // Estimate total duration from songs (assume 3:30 average if duration unknown)
  String _formatDuration() {
    final totalSeconds = songs.fold<int>(
      0,
      (sum, s) => sum + (s.durationSeconds > 0 ? s.durationSeconds : 210),
    );
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          // Editorial Noir hero — full-width cover + gradient + Playfair title overlay
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            stretch: true,
            backgroundColor: KaivaColors.backgroundPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.black.withValues(alpha: 0.4),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: KaivaColors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    color: KaivaColors.textPrimary,
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              titlePadding: const EdgeInsets.fromLTRB(
                KaivaSpacing.marginMobile, 0, KaivaSpacing.marginMobile, KaivaSpacing.md,
              ),
              centerTitle: false,
              expandedTitleScale: 1.0,
              title: LayoutBuilder(
                builder: (context, constraints) {
                  // Title visible only when collapsed
                  final isCollapsed = constraints.biggest.height < 100;
                  return AnimatedOpacity(
                    opacity: isCollapsed ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      name,
                      style: KaivaTextStyles.headlineMedium.copyWith(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover art (luminosity blend handled by overlay)
                  if (artworkUrl != null && artworkUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: artworkUrl!,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.35),
                      colorBlendMode: BlendMode.darken,
                      placeholder: (_, __) =>
                          Container(color: KaivaColors.surfaceContainerHigh),
                      errorWidget: (_, __, ___) =>
                          Container(color: KaivaColors.surfaceContainerHigh),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [KaivaColors.accentDim, KaivaColors.backgroundPrimary],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.queue_music_rounded,
                          size: 72,
                          color: KaivaColors.textMuted,
                        ),
                      ),
                    ),
                  // Bottom-to-top gradient — fades into background black
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x99000000),
                          Color(0xFF0A0A0A),
                        ],
                        stops: [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // Hero content at bottom of hero
                  Positioned(
                    left: KaivaSpacing.marginMobile,
                    right: KaivaSpacing.marginMobile,
                    bottom: KaivaSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLocal ? 'YOUR PLAYLIST' : 'CURATED PLAYLIST',
                          style: KaivaTextStyles.labelSmall.copyWith(
                            color: KaivaColors.accentPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: KaivaSpacing.sm),
                        Text(
                          name,
                          style: KaivaTextStyles.displayMedium.copyWith(
                            color: Colors.white,
                            height: 1.05,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description != null && description!.isNotEmpty) ...[
                          const SizedBox(height: KaivaSpacing.sm),
                          Text(
                            description!,
                            style: KaivaTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: KaivaSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: KaivaColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(),
                              style: KaivaTextStyles.labelMedium.copyWith(
                                color: KaivaColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: KaivaTextStyles.labelMedium.copyWith(
                                color: KaivaColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${songs.length} ${songs.length == 1 ? "Track" : "Tracks"}',
                              style: KaivaTextStyles.labelMedium.copyWith(
                                color: KaivaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action bar — play FAB + shuffle / favorite / download
          if (songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KaivaSpacing.marginMobile, 0, KaivaSpacing.marginMobile, KaivaSpacing.md,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _PlayFab(
                              onTap: () => ref
                                  .read(audioHandlerProvider)
                                  .playQueue(songs, 0),
                            ),
                            const SizedBox(width: KaivaSpacing.sm),
                            _GhostCircle(
                              icon: Icons.shuffle_rounded,
                              onTap: () {
                                // play a random song from the queue
                                final start = songs.length > 1
                                    ? (songs.length *
                                            (DateTime.now().millisecondsSinceEpoch %
                                                1000) /
                                            1000)
                                        .floor()
                                    : 0;
                                ref
                                    .read(audioHandlerProvider)
                                    .playQueue(songs, start);
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _GhostCircle(
                              icon: Icons.favorite_outline_rounded,
                              onTap: () {},
                            ),
                            const SizedBox(width: KaivaSpacing.base),
                            _GhostCircle(
                              icon: Icons.download_outlined,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: KaivaSpacing.md),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: KaivaColors.borderSubtle,
                    ),
                  ],
                ),
              ),
            ),

          if (songs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No songs in this playlist.',
                  style: KaivaTextStyles.bodyMedium,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == songs.length) return const SizedBox(height: 120);
                  final song = songs[i];
                  return SongTile(
                    song: song,
                    isPlaying: currentSong?.id == song.id,
                    trackNumber: i + 1,
                    showArt: true,
                    onTap: () =>
                        ref.read(audioHandlerProvider).playQueue(songs, i),
                  );
                },
                childCount: songs.length + 1,
              ),
            ),
        ],
      ),
    );
  }
}

// Editorial Noir primary play button (56px sand circle, no shadow)
class _PlayFab extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: KaivaColors.accentPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x4DEF9F27),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: KaivaColors.textOnAccent,
          size: 32,
        ),
      ),
    );
  }
}

// Ghost circle button: 40px transparent, white@20% border
class _GhostCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GhostCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: KaivaColors.borderDefault, width: 1),
        ),
        child: Icon(icon, color: KaivaColors.textPrimary, size: 20),
      ),
    );
  }
}
