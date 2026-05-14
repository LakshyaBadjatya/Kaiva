import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/kaiva_colors.dart';

class AlbumArt extends StatelessWidget {
  final String url;
  final double size;
  final double borderRadius;
  final String? heroTag;
  final BoxFit fit;

  const AlbumArt({
    super.key,
    required this.url,
    required this.size,
    this.borderRadius = 8,
    this.heroTag,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: url.isEmpty
            ? _placeholder()
            : CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: fit,
                placeholder: (_, __) => _shimmer(),
                errorWidget: (_, __, ___) => _placeholder(),
              ),
      ),
    );

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }
    return image;
  }

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: KaivaColors.backgroundTertiary,
        highlightColor: KaivaColors.backgroundElevated,
        child: Container(
          width: size,
          height: size,
          color: KaivaColors.backgroundTertiary,
        ),
      );

  Widget _placeholder() => Container(
        width: size,
        height: size,
        color: KaivaColors.backgroundTertiary,
        child: Icon(
          Icons.music_note,
          color: KaivaColors.textMuted,
          size: size * 0.4,
        ),
      );
}
