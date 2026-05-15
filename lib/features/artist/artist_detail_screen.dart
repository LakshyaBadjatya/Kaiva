import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/artist.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/player/player_provider.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/song_tile.dart';

final artistDetailProvider =
    FutureProvider.family<Artist, String>((ref, id) async {
  if (id.isEmpty) {
    throw StateError('Artist id is empty');
  }
  final response = await ApiClient.instance().get(ApiEndpoints.artist(id));
  final body = response.data;
  Map<String, dynamic>? data;
  if (body is Map<String, dynamic>) {
    final raw = body['data'];
    if (raw is Map<String, dynamic>) {
      data = raw;
    } else if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      data = raw.first as Map<String, dynamic>;
    }
  }
  if (data == null || data.isEmpty || (data['id']?.toString().isEmpty ?? true)) {
    throw StateError('Artist not found ($id)');
  }
  return Artist.fromJson(data);
});

class ArtistDetailScreen extends ConsumerWidget {
  final String artistId;

  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistDetailProvider(artistId));

    return artistAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: ListView.builder(
          itemCount: 12,
          itemBuilder: (_, __) => const ShimmerSongTile(),
        ),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined,
                    size: 56, color: KaivaColors.textMuted),
                const SizedBox(height: 12),
                const Text('Could not load artist.',
                    style: KaivaTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  err.toString(),
                  style: KaivaTextStyles.labelSmall
                      .copyWith(color: KaivaColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(artistDetailProvider(artistId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (artist) => _ArtistScaffold(artist: artist),
    );
  }
}

// Editorial Noir Artist Profile (Stitch 06)
class _ArtistScaffold extends ConsumerWidget {
  final Artist artist;
  const _ArtistScaffold({required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final songs = artist.topSongs;
    final topSongs = songs.take(5).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          // ── Hero ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 460,
            pinned: true,
            stretch: true,
            backgroundColor: KaivaColors.backgroundPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _HeaderCircle(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _HeaderCircle(
                  icon: Icons.favorite_outline_rounded,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                child: _HeaderCircle(
                  icon: Icons.more_vert_rounded,
                  onTap: () {},
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
                  final isCollapsed = constraints.biggest.height < 100;
                  return AnimatedOpacity(
                    opacity: isCollapsed ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      artist.name,
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
                  if (artist.highResImageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: artist.highResImageUrl,
                      fit: BoxFit.cover,
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
                    ),
                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x66000000),
                          Color(0xFF0A0A0A),
                        ],
                        stops: [0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // Hero text at bottom
                  Positioned(
                    left: KaivaSpacing.marginMobile,
                    right: KaivaSpacing.marginMobile,
                    bottom: KaivaSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ARTIST',
                          style: KaivaTextStyles.labelSmall.copyWith(
                            color: KaivaColors.accentPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: KaivaSpacing.sm),
                        Text(
                          artist.name,
                          style: KaivaTextStyles.displayMedium.copyWith(
                            color: Colors.white,
                            height: 1.05,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (artist.followerCount != null) ...[
                          const SizedBox(height: KaivaSpacing.sm),
                          Text(
                            '${_formatCount(artist.followerCount!)} Monthly Listeners',
                            style: KaivaTextStyles.bodyMedium.copyWith(
                              color: KaivaColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Play + Shuffle row ─────────────────────────────
          if (songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KaivaSpacing.marginMobile, KaivaSpacing.sm, KaivaSpacing.marginMobile, KaivaSpacing.md,
                ),
                child: Row(
                  children: [
                    _PlayFab(
                      onTap: () => ref.read(audioHandlerProvider).playQueue(songs, 0),
                    ),
                    const SizedBox(width: KaivaSpacing.sm),
                    _ShufflePill(
                      onTap: () {
                        final start = songs.length > 1
                            ? DateTime.now().millisecondsSinceEpoch % songs.length
                            : 0;
                        ref.read(audioHandlerProvider).playQueue(songs, start);
                      },
                    ),
                  ],
                ),
              ),
            ),

          // ── Top Songs ──────────────────────────────────────
          if (topSongs.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  KaivaSpacing.marginMobile, KaivaSpacing.md,
                  KaivaSpacing.marginMobile, KaivaSpacing.sm,
                ),
                child: Text('Top Songs', style: KaivaTextStyles.headlineMedium),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final song = topSongs[i];
                  return SongTile(
                    song: song,
                    isPlaying: currentSong?.id == song.id,
                    trackNumber: i + 1,
                    showArt: true,
                    onTap: () => ref.read(audioHandlerProvider).playQueue(songs, i),
                  );
                },
                childCount: topSongs.length,
              ),
            ),
            if (songs.length > 5)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KaivaSpacing.marginMobile, KaivaSpacing.sm, KaivaSpacing.marginMobile, 0,
                  ),
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KaivaColors.textSecondary,
                      side: const BorderSide(color: KaivaColors.borderSubtle, width: 1),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      'See All',
                      style: KaivaTextStyles.labelLarge.copyWith(
                        color: KaivaColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],

          // ── Albums ─────────────────────────────────────────
          if (artist.albums.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  KaivaSpacing.marginMobile, KaivaSpacing.xl,
                  KaivaSpacing.marginMobile, KaivaSpacing.sm,
                ),
                child: Text('Albums', style: KaivaTextStyles.headlineMedium),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: KaivaSpacing.marginMobile),
                  itemCount: artist.albums.length,
                  separatorBuilder: (_, __) => const SizedBox(width: KaivaSpacing.sm),
                  itemBuilder: (context, i) {
                    final album = artist.albums[i];
                    return _ArtistAlbumCard(
                      title: album.name,
                      subtitle: album.year != null
                          ? '${album.year} • Album'
                          : 'Album',
                      artworkUrl: album.highResArtworkUrl,
                      onTap: () => context.push('/album/${album.id}'),
                    );
                  },
                ),
              ),
            ),
          ],

          // ── Fans Also Like ─────────────────────────────────
          if (artist.similarArtists.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  KaivaSpacing.marginMobile, KaivaSpacing.xl,
                  KaivaSpacing.marginMobile, KaivaSpacing.sm,
                ),
                child: Text('Fans Also Like', style: KaivaTextStyles.headlineMedium),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: KaivaSpacing.marginMobile),
                  itemCount: artist.similarArtists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: KaivaSpacing.md),
                  itemBuilder: (context, i) {
                    final a = artist.similarArtists[i];
                    return _SimilarArtistTile(
                      name: a.name,
                      imageUrl: a.highResImageUrl,
                      onTap: () => context.push('/artist/${a.id}'),
                    );
                  },
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return '$count';
  }
}

class _HeaderCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(
        side: BorderSide(color: KaivaColors.borderSubtle, width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: KaivaColors.textPrimary,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}

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
            BoxShadow(color: Color(0x4DEF9F27), blurRadius: 24, spreadRadius: 1),
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

class _ShufflePill extends StatelessWidget {
  final VoidCallback onTap;
  const _ShufflePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: KaivaColors.textPrimary,
        side: const BorderSide(color: KaivaColors.borderDefault, width: 1),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      icon: const Icon(Icons.shuffle_rounded, size: 18, color: KaivaColors.textPrimary),
      label: Text(
        'Shuffle',
        style: KaivaTextStyles.labelLarge.copyWith(color: KaivaColors.textPrimary),
      ),
    );
  }
}

class _ArtistAlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String artworkUrl;
  final VoidCallback onTap;
  const _ArtistAlbumCard({
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(KaivaRadius.md),
              child: CachedNetworkImage(
                imageUrl: artworkUrl,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 160,
                  height: 160,
                  color: KaivaColors.surfaceContainerHigh,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 160,
                  height: 160,
                  color: KaivaColors.surfaceContainerHigh,
                  child: const Icon(Icons.album_outlined, color: KaivaColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: KaivaSpacing.sm),
            Text(
              title,
              style: KaivaTextStyles.titleLarge.copyWith(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: KaivaTextStyles.labelSmall.copyWith(
                color: KaivaColors.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SimilarArtistTile extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;
  const _SimilarArtistTile({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KaivaColors.borderSubtle, width: 1),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 88,
                    height: 88,
                    color: KaivaColors.surfaceContainerHigh,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 88,
                    height: 88,
                    color: KaivaColors.surfaceContainerHigh,
                    child: const Icon(Icons.person_outline, color: KaivaColors.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(height: KaivaSpacing.base),
            Text(
              name,
              style: KaivaTextStyles.labelLarge.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
