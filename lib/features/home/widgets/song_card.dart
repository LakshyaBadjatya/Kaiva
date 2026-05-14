import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/song.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../../../shared/widgets/album_art.dart';

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
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlbumArt(url: song.artworkUrl, size: 140, borderRadius: 10),
            const SizedBox(height: 6),
            Text(
              song.title,
              style: KaivaTextStyles.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: KaivaTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlbumArt(url: artworkUrl, size: 140, borderRadius: 10),
            const SizedBox(height: 6),
            Text(title, style: KaivaTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(subtitle, style: KaivaTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final String name;
  final String artworkUrl;
  final VoidCallback? onTap;

  const PlaylistCard({super.key, required this.name, required this.artworkUrl, this.onTap});

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
                  borderRadius: BorderRadius.circular(10),
                  child: artworkUrl.isEmpty
                      ? Container(
                          width: size,
                          height: size,
                          color: KaivaColors.backgroundTertiary,
                          child: Icon(Icons.music_note, color: KaivaColors.textMuted, size: size * 0.4),
                        )
                      : CachedNetworkImage(
                          imageUrl: artworkUrl,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: KaivaColors.backgroundTertiary),
                          errorWidget: (_, __, ___) => Container(
                            color: KaivaColors.backgroundTertiary,
                            child: const Icon(Icons.music_note, color: KaivaColors.textMuted),
                          ),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: KaivaTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
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
        width: 80,
        child: Column(
          children: [
            ClipOval(
              child: AlbumArt(url: imageUrl ?? '', size: 72, borderRadius: 36),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: KaivaTextStyles.bodySmall,
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
