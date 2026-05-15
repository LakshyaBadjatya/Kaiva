import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/kaiva_database.dart' show ListeningStat;
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';

final weeklyStatsProvider = FutureProvider<List<ListeningStat>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.statsDao.getWeeklyStats();
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Stats', style: KaivaTextStyles.headlineLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push('/wrapped'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: KaivaColors.accentGlow,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                      color: KaivaColors.accentPrimary, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 15, color: KaivaColors.accentPrimary),
                    const SizedBox(width: 6),
                    Text('Wrapped',
                        style: KaivaTextStyles.labelMedium.copyWith(
                            color: KaivaColors.accentPrimary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: KaivaColors.accentPrimary),
        ),
        error: (_, __) => const Center(
          child: Text('Could not load stats.', style: KaivaTextStyles.bodyMedium),
        ),
        data: (stats) => stats.isEmpty
            ? _EmptyStats()
            : _StatsBody(stats: stats),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final List<ListeningStat> stats;
  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalSeconds = stats.fold<int>(0, (s, r) => s + r.secondsPlayed);
    final totalMinutes = totalSeconds ~/ 60;

    // Aggregate by artist
    final byArtist = <String, int>{};
    for (final s in stats) {
      byArtist[s.artistId] = (byArtist[s.artistId] ?? 0) + s.secondsPlayed;
    }
    final topArtists = byArtist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Aggregate by song
    final bySong = <String, int>{};
    for (final s in stats) {
      bySong[s.songId] = (bySong[s.songId] ?? 0) + s.secondsPlayed;
    }
    final topSongs = bySong.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Daily listening (last 7 days)
    final daily = <String, int>{};
    for (final s in stats) {
      final day = '${s.date.month}/${s.date.day}';
      daily[day] = (daily[day] ?? 0) + s.secondsPlayed;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Total time card ─────────────────────────────────
        _StatCard(
          child: Column(
            children: [
              Text(
                _formatMinutes(totalMinutes),
                style: KaivaTextStyles.displayLarge.copyWith(
                  color: KaivaColors.accentPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Listening time this week',
                style: KaivaTextStyles.bodyMedium,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),

        const SizedBox(height: 16),

        // ── Daily bar chart ──────────────────────────────────
        if (daily.isNotEmpty) ...[
          const Text('Daily Breakdown', style: KaivaTextStyles.sectionHeader),
          const SizedBox(height: 8),
          _StatCard(child: _DailyChart(daily: daily))
              .animate(delay: 100.ms).fadeIn(duration: 250.ms),
          const SizedBox(height: 16),
        ],

        // ── Top songs ────────────────────────────────────────
        if (topSongs.isNotEmpty) ...[
          const Text('Top Songs', style: KaivaTextStyles.sectionHeader),
          const SizedBox(height: 8),
          ...topSongs.take(5).indexed.map(
            (entry) => _RankRow(
              rank: entry.$1 + 1,
              id: entry.$2.key,
              seconds: entry.$2.value,
              isArtist: false,
            ).animate(delay: Duration(milliseconds: 50 * entry.$1)).fadeIn(duration: 200.ms),
          ),
          const SizedBox(height: 16),
        ],

        // ── Top artists ──────────────────────────────────────
        if (topArtists.isNotEmpty) ...[
          const Text('Top Artists', style: KaivaTextStyles.sectionHeader),
          const SizedBox(height: 8),
          ...topArtists.take(5).indexed.map(
            (entry) => _RankRow(
              rank: entry.$1 + 1,
              id: entry.$2.key,
              seconds: entry.$2.value,
              isArtist: true,
            ).animate(delay: Duration(milliseconds: 50 * entry.$1 + 250)).fadeIn(duration: 200.ms),
          ),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  String _formatMinutes(int m) {
    if (m >= 60) return '${m ~/ 60}h ${m % 60}m';
    return '${m}m';
  }
}

class _DailyChart extends StatelessWidget {
  final Map<String, int> daily;
  const _DailyChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    final max = daily.values.fold<int>(1, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: daily.entries.map((e) {
          final frac = e.value / max;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: (60 * frac).clamp(4, 60),
                decoration: BoxDecoration(
                  color: KaivaColors.accentPrimary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 4),
              Text(e.key, style: KaivaTextStyles.labelSmall),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String id;
  final int seconds;
  final bool isArtist;

  const _RankRow({
    required this.rank,
    required this.id,
    required this.seconds,
    required this.isArtist,
  });

  @override
  Widget build(BuildContext context) {
    final mins = seconds ~/ 60;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: KaivaTextStyles.labelMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isArtist ? Icons.person_outline : Icons.music_note_outlined,
            size: 18,
            color: KaivaColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              id,
              style: KaivaTextStyles.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${mins}m',
            style: KaivaTextStyles.durationLabel,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Widget child;
  const _StatCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KaivaColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KaivaColors.borderSubtle, width: 0.5),
      ),
      child: child,
    );
  }
}

class _EmptyStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 52, color: KaivaColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No listening data yet.\nStart playing music to see your stats.',
            style: KaivaTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
