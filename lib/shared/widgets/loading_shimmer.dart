import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/kaiva_colors.dart';

// ── Shared shimmer colors ─────────────────────────────────────
const _shimmerBase = KaivaColors.backgroundTertiary;
const _shimmerHighlight = KaivaColors.backgroundElevated;

// Single card shimmer (no Shimmer ancestor here — must be inside ShimmerScope)
class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Horizontal shimmer list — ONE Shimmer wraps all cards ─────
class ShimmerHorizontalList extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;

  const ShimmerHorizontalList({
    super.key,
    this.cardWidth = 140,
    this.cardHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      child: SizedBox(
        height: cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: _shimmerBase,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Song tile shimmer — ONE Shimmer wraps the row ────────────
class ShimmerSongTile extends StatelessWidget {
  const ShimmerSongTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _shimmerBase,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14,
                      width: double.infinity,
                      color: _shimmerBase),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 120, color: _shimmerBase),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
