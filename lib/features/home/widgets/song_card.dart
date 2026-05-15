import 'package:flutter/material.dart';
import '../../../core/models/song.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../../../shared/widgets/kaiva_tile.dart';

// Editorial Noir trending card — 240px square, Playfair title, DM Sans artist
class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const SongCard({super.key, required this.song, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: KaivaTile(
        artworkUrl: song.artworkUrl,
        title: song.title,
        subtitle: song.artist,
        titleStyle: KaivaTextStyles.titleLarge,
        subtitleStyle: KaivaTextStyles.bodyMedium,
        borderRadius: KaivaRadius.lg,
        onTap: onTap,
        artOverlay: const Positioned(
          bottom: 12,
          right: 12,
          child: _PlayFAB(size: 48),
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
    return KaivaTile(
      artworkUrl: artworkUrl,
      title: title,
      subtitle: subtitle.isEmpty ? null : subtitle,
      titleStyle: KaivaTextStyles.headlineMedium,
      onTap: onTap,
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
    return KaivaTile(
      artworkUrl: artworkUrl,
      title: name,
      titleStyle: KaivaTextStyles.titleMedium,
      onTap: onTap,
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
    return SizedBox(
      width: 88,
      child: KaivaTile(
        artworkUrl: imageUrl,
        title: name,
        titleStyle: KaivaTextStyles.labelLarge,
        circularArt: true,
        textAlign: TextAlign.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        onTap: onTap,
      ),
    );
  }
}
