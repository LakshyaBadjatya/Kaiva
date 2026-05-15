import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/song.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';

// Editorial Noir glass tiles: small art + label in a row, white@5% bg, blur, white@10% border
class QuickAccessGrid extends StatelessWidget {
  final List<Song> songs;
  final void Function(Song, int) onTap;

  const QuickAccessGrid({super.key, required this.songs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = songs.take(6).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KaivaSpacing.marginMobile),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 56,
          crossAxisSpacing: KaivaSpacing.sm,
          mainAxisSpacing: KaivaSpacing.sm,
        ),
        itemBuilder: (context, i) => _QuickAccessTile(
          song: items[i],
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(items[i], i);
          },
        ),
      ),
    );
  }
}

class _QuickAccessTile extends StatefulWidget {
  final Song song;
  final VoidCallback onTap;

  const _QuickAccessTile({required this.song, required this.onTap});

  @override
  State<_QuickAccessTile> createState() => _QuickAccessTileState();
}

class _QuickAccessTileState extends State<_QuickAccessTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
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
        scale: _ctrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(KaivaRadius.md),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF), // white @ 5%
                borderRadius: BorderRadius.circular(KaivaRadius.md),
                border: Border.all(color: KaivaColors.borderSubtle, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: KaivaColors.borderSubtle, width: 1),
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: widget.song.artworkUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: KaivaColors.surfaceContainerHigh),
                        errorWidget: (_, __, ___) => Container(
                          color: KaivaColors.surfaceContainerHigh,
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: KaivaColors.textMuted,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.song.title,
                        style: KaivaTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
