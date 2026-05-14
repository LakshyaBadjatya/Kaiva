import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/song.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';

class QuickAccessGrid extends StatelessWidget {
  final List<Song> songs;
  final void Function(Song, int) onTap;

  const QuickAccessGrid({
    super.key,
    required this.songs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show up to 6 items in a 2-column grid (3 rows max)
    final items = songs.take(6).toList();
    final rowCount = (items.length / 2).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: List.generate(rowCount, (row) {
          final left = row * 2;
          final right = left + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _QuickAccessCard(
                    song: items[left],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(items[left], left);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (right < items.length)
                  Expanded(
                    child: _QuickAccessCard(
                      song: items[right],
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(items[right], right);
                      },
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _QuickAccessCard extends StatefulWidget {
  final Song song;
  final VoidCallback onTap;

  const _QuickAccessCard({required this.song, required this.onTap});

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<_QuickAccessCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: KaivaColors.backgroundElevated,
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Thumbnail
              SizedBox(
                width: 56,
                height: 56,
                child: CachedNetworkImage(
                  imageUrl: widget.song.artworkUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: KaivaColors.backgroundTertiary,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: KaivaColors.backgroundTertiary,
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: KaivaColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Title
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    widget.song.title,
                    style: KaivaTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
