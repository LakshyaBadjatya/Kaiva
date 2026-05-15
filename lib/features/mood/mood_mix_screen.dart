import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../core/utils/song_loader.dart';
import '../player/player_provider.dart';
import 'mood_engine.dart';
import 'mood_provider.dart';

class MoodMixScreen extends ConsumerWidget {
  const MoodMixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixAsync = ref.watch(moodMixProvider);

    return Scaffold(
      backgroundColor: KaivaColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Mood Mix', style: KaivaTextStyles.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: KaivaColors.textSecondary),
            tooltip: 'Re-detect mood',
            onPressed: () => ref.invalidate(moodMixProvider),
          ),
        ],
      ),
      body: mixAsync.when(
        loading: () => const _MoodLoading(),
        error: (e, _) => _MoodError(
          onRetry: () => ref.invalidate(moodMixProvider),
        ),
        data: (mix) => _MoodContent(mix: mix),
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────
class _MoodLoading extends StatelessWidget {
  const _MoodLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  AlwaysStoppedAnimation(KaivaColors.accentPrimary),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 0.9, end: 1.1, duration: 900.ms)
              .then()
              .scaleXY(begin: 1.1, end: 0.9, duration: 900.ms),
          const SizedBox(height: 24),
          Text('Reading the room…',
              style: KaivaTextStyles.bodyMedium
                  .copyWith(color: KaivaColors.textSecondary)),
          const SizedBox(height: 6),
          Text('Picking songs for this moment',
              style: KaivaTextStyles.bodySmall
                  .copyWith(color: KaivaColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────
class _MoodError extends StatelessWidget {
  final VoidCallback onRetry;
  const _MoodError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 48, color: KaivaColors.textMuted),
          const SizedBox(height: 16),
          Text('Could not build a mix',
              style: KaivaTextStyles.bodyMedium),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
                backgroundColor: KaivaColors.accentPrimary),
            child: const Text('Try again',
                style: TextStyle(color: KaivaColors.textOnAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Content ───────────────────────────────────────────────────
class _MoodContent extends ConsumerWidget {
  final MoodMix mix;
  const _MoodContent({required this.mix});

  Future<void> _play(WidgetRef ref, int index) async {
    final handler = ref.read(audioHandlerProvider);
    final reordered = <Song>[
      mix.songs[index],
      ...mix.songs.sublist(0, index),
      ...mix.songs.sublist(index + 1),
    ];
    final fresh = await fetchFreshQueue(reordered);
    await handler.playQueue(fresh, 0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mix.songs.isEmpty) {
      return Center(
        child: Text('No songs found for this mood.',
            style: KaivaTextStyles.bodyMedium
                .copyWith(color: KaivaColors.textMuted)),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: KaivaColors.accentGlow,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: KaivaColors.accentPrimary, width: 0.5),
                      ),
                      child: Text(
                        mix.aiPowered ? 'AI PICKED' : 'FOR THIS MOMENT',
                        style: KaivaTextStyles.labelSmall
                            .copyWith(color: KaivaColors.accentPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(mix.mood, style: KaivaTextStyles.displayMedium)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                Text(
                  mix.description,
                  style: KaivaTextStyles.bodyMedium
                      .copyWith(color: KaivaColors.textSecondary),
                ).animate(delay: 120.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _play(ref, 0),
                        style: FilledButton.styleFrom(
                          backgroundColor: KaivaColors.accentPrimary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded,
                            color: KaivaColors.textOnAccent),
                        label: const Text('Play',
                            style: TextStyle(
                                color: KaivaColors.textOnAccent,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final shuffled =
                              List<Song>.from(mix.songs)..shuffle();
                          ref.read(audioHandlerProvider).playQueue(
                              shuffled, 0);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: KaivaColors.borderDefault),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.shuffle_rounded,
                            color: KaivaColors.textPrimary),
                        label: const Text('Shuffle',
                            style: TextStyle(
                                color: KaivaColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final song = mix.songs[i];
              return ListTile(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _play(ref, i);
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: song.artworkUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 48,
                      height: 48,
                      color: KaivaColors.backgroundTertiary,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: KaivaColors.backgroundTertiary,
                      child: const Icon(Icons.music_note,
                          color: KaivaColors.textMuted, size: 20),
                    ),
                  ),
                ),
                title: Text(song.title,
                    style: KaivaTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist,
                    style: KaivaTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              )
                  .animate()
                  .fadeIn(delay: (20 * i).ms, duration: 220.ms)
                  .slideY(begin: 0.15, curve: Curves.easeOut);
            },
            childCount: mix.songs.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }
}
