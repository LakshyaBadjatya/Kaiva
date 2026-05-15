import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import 'album_art.dart';

// ─────────────────────────────────────────────────────────────
//  KaivaTile — overflow-proof "art + 1-2 text lines" tile.
//
//  Design contract:
//    - When parent gives a bounded max height (e.g. inside a fixed-height
//      horizontal ListView), the artwork SHRINKS to fit the remaining space
//      after the (single-line) title and optional subtitle have been laid
//      out. Text never gets squeezed; the art adapts.
//    - When parent is unbounded vertically (e.g. inside a GridView cell
//      with childAspectRatio), the artwork takes a square based on width
//      and the text sits below.
//    - Title and subtitle are always single-line with ellipsis.
//
//  This is the canonical primitive for every "card with cover + text"
//  in the app. Use it instead of hand-rolling Column + AspectRatio +
//  fixed-height SizedBox, which is the pattern that overflows when text
//  scale or font metrics push the column past its parent.
// ─────────────────────────────────────────────────────────────

class KaivaTile extends StatelessWidget {
  final String? artworkUrl;
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool circularArt;
  final double borderRadius;
  final Widget? artOverlay;
  final VoidCallback? onTap;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;

  const KaivaTile({
    super.key,
    this.artworkUrl,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.circularArt = false,
    this.borderRadius = KaivaRadius.md,
    this.artOverlay,
    this.onTap,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  static const _gapArtToTitle = KaivaSpacing.sm;
  static const _gapTitleToSubtitle = 4.0;

  @override
  Widget build(BuildContext context) {
    final tStyle = titleStyle ?? KaivaTextStyles.titleMedium;
    final sStyle = subtitle == null
        ? null
        : (subtitleStyle ??
            KaivaTextStyles.labelLarge.copyWith(
              color: KaivaColors.textSecondary,
              fontWeight: FontWeight.w400,
            ));

    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!.call();
            },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.hasBoundedWidth ? constraints.maxWidth : 200.0;

          // ── Bounded-height path: art is a Flexible square, text takes
          //    only what it needs. Flutter resolves the math at layout
          //    time so this can never overflow regardless of font metrics
          //    or text-scaler — the art shrinks (or disappears) to fit.
          if (constraints.hasBoundedHeight &&
              constraints.maxHeight.isFinite) {
            return Column(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  child: _SquareArt(
                    maxWidth: width,
                    buildArt: _buildArt,
                  ),
                ),
                const SizedBox(height: _gapArtToTitle),
                _buildTitleFlexible(tStyle),
                if (subtitle != null && sStyle != null) ...[
                  const SizedBox(height: _gapTitleToSubtitle),
                  _buildSubtitleFlexible(sStyle),
                ],
              ],
            );
          }

          // ── Unbounded-height path: art is a square based on width ──
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildArt(width),
              const SizedBox(height: _gapArtToTitle),
              _buildTitleFlexible(tStyle),
              if (subtitle != null && sStyle != null) ...[
                const SizedBox(height: _gapTitleToSubtitle),
                _buildSubtitleFlexible(sStyle),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildArt(double size) {
    if (size <= 0) return const SizedBox.shrink();
    final art = AlbumArt(
      url: artworkUrl ?? '',
      size: size,
      borderRadius: circularArt ? size / 2 : borderRadius,
    );
    // AlbumArt already clips internally; wrap only when circular for ClipOval.
    final clipped = circularArt ? ClipOval(child: art) : art;
    if (artOverlay == null) return clipped;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: [clipped, artOverlay!]),
    );
  }

  Widget _buildTitleFlexible(TextStyle style) {
    return Text(
      title,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }

  Widget _buildSubtitleFlexible(TextStyle style) {
    return Text(
      subtitle!,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}

// Square artwork that fits inside the smaller of incoming width/height.
class _SquareArt extends StatelessWidget {
  final double maxWidth;
  final Widget Function(double) buildArt;
  const _SquareArt({required this.maxWidth, required this.buildArt});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = (c.hasBoundedHeight ? c.maxHeight : maxWidth)
            .clamp(0.0, maxWidth)
            .toDouble();
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: buildArt(size),
        );
      },
    );
  }
}
