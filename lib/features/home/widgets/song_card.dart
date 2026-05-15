import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/song.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../../../shared/widgets/album_art.dart';

// Editorial Noir trending card — 240px square, Playfair title, DM Sans artist
class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const SongCard({super.key, required this.song, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AlbumArt(url: song.artworkUrl, size: 240, borderRadius: KaivaRadius.lg),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _PlayFAB(size: 48),
                ),
              ],
            ),
            const SizedBox(height: KaivaSpacing.sm),
            Text(
              song.title,
              style: KaivaTextStyles.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              song.artist,
              style: KaivaTextStyles.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayFAB extends StatelessWidget {
  final double size;
  const _PlayFAB({this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: KaivaColors.accentPrimary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: KaivaColors.textOnAccent,
        size: size * 0.6,
      ),
    );
  }
}

// Made-For-You / new release tile — square art, Playfair title, DM Sans subtitle
class AlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String artworkUrl;
  final VoidCallback? onTap;

  const AlbumCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AlbumArt(url: artworkUrl, size: 0, borderRadius: KaivaRadius.md),
          ),
          const SizedBox(height: KaivaSpacing.sm),
          Text(
            title,
            style: KaivaTextStyles.headlineMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: KaivaTextStyles.labelLarge.copyWith(
              color: KaivaColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final String name;
  final String artworkUrl;
  final VoidCallback? onTap;

  const PlaylistCard({
    super.key,
    required this.name,
    required this.artworkUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(KaivaRadius.md),
                  child: artworkUrl.isEmpty
                      ? Container(
                          width: size,
                          height: size,
                          color: KaivaColors.surfaceContainerHigh,
                          child: Icon(
                            Icons.queue_music_rounded,
                            color: KaivaColors.textMuted,
                            size: size * 0.4,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: artworkUrl,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: KaivaColors.surfaceContainerHigh),
                          errorWidget: (_, __, ___) => Container(
                            color: KaivaColors.surfaceContainerHigh,
                            child: const Icon(
                              Icons.queue_music_rounded,
                              color: KaivaColors.textMuted,
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: KaivaSpacing.sm),
          Text(
            name,
            style: KaivaTextStyles.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ArtistCircle extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;

  const ArtistCircle({super.key, required this.name, this.imageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: KaivaColors.borderSubtle, width: 1),
                ),
              ),
              child: ClipOval(
                child: AlbumArt(url: imageUrl ?? '', size: 80, borderRadius: 40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: KaivaTextStyles.labelLarge,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
