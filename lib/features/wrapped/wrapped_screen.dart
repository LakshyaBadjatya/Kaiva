import 'dart:math';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import 'wrapped_data.dart';

/// Kaiva Wrapped — a scrollable, animated year-in-music recap.
/// Layout blends the three Stitch mockups: screen3 hero, v2 song/list,
/// screen3 artist glow, v1 charts, shared poster finale.
class WrappedScreen extends ConsumerWidget {
  const WrappedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wrappedProvider);

    return Scaffold(
      backgroundColor: KaivaColors.backgroundPrimary,
      body: async.when(
        loading: () => const _WrappedLoading(),
        error: (e, _) => _WrappedError(
          onRetry: () => ref.invalidate(wrappedProvider),
        ),
        data: (data) =>
            data.isEmpty ? const _WrappedEmpty() : _WrappedStory(data: data),
      ),
    );
  }
}

// ── States ────────────────────────────────────────────────────

class _WrappedLoading extends StatelessWidget {
  const _WrappedLoading();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
            color: KaivaColors.accentPrimary, strokeWidth: 3),
      );
}

class _WrappedError extends StatelessWidget {
  final VoidCallback onRetry;
  const _WrappedError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: KaivaColors.textMuted),
            const SizedBox(height: 16),
            Text('Could not build your Wrapped',
                style: KaivaTextStyles.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                  backgroundColor: KaivaColors.accentPrimary),
              child: const Text('Retry',
                  style: TextStyle(color: KaivaColors.textOnAccent)),
            ),
          ],
        ),
      );
}

class _WrappedEmpty extends StatelessWidget {
  const _WrappedEmpty();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 56, color: KaivaColors.accentPrimary),
              const SizedBox(height: 20),
              Text('Your Wrapped is brewing',
                  style: KaivaTextStyles.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Listen a little more this year and your recap will appear here.',
                textAlign: TextAlign.center,
                style: KaivaTextStyles.bodyMedium
                    .copyWith(color: KaivaColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}

// ── Story ─────────────────────────────────────────────────────

class _WrappedStory extends StatefulWidget {
  final WrappedData data;
  const _WrappedStory({required this.data});

  @override
  State<_WrappedStory> createState() => _WrappedStoryState();
}

class _WrappedStoryState extends State<_WrappedStory> {
  final _posterKey = GlobalKey();
  bool _sharing = false;

  Future<void> _sharePoster() async {
    setState(() => _sharing = true);
    try {
      final boundary = _posterKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kaiva_wrapped_${widget.data.year}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Kaiva Wrapped ${widget.data.year} 🎧',
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(year: d.year, minutes: d.totalMinutes),
            if (d.topSong != null) _TopSongSection(song: d.topSong!),
            if (d.topSongs.length > 1)
              _TopSongsList(songs: d.topSongs),
            if (d.topArtist != null)
              _TopArtistSection(artist: d.topArtist!),
            if (d.topArtists.length > 1)
              _TopArtistsRow(artists: d.topArtists),
            _PersonalitySection(
                title: d.personality, blurb: d.personalityBlurb),
            if (d.genres.isNotEmpty) _GenreSection(genres: d.genres),
            _MonthsSection(minutes: d.minutesByMonth),
            _SharePoster(
              posterKey: _posterKey,
              data: d,
              sharing: _sharing,
              onShare: _sharePoster,
            ),
            const SizedBox(height: 40),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.close_rounded,
                color: KaivaColors.textPrimary, size: 28),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ],
    );
  }
}

// ── Sections ──────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Section({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(28, 56, 28, 56),
  });
  @override
  Widget build(BuildContext context) =>
      Padding(padding: padding, child: child);
}

class _Hero extends StatelessWidget {
  final int year;
  final int minutes;
  const _Hero({required this.year, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return _Section(
      padding: const EdgeInsets.fromLTRB(28, 120, 28, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glow orb behind the headline.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -30,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      KaivaColors.accentPrimary.withValues(alpha: 0.35),
                      KaivaColors.accentPrimary.withValues(alpha: 0.0),
                    ]),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.9, end: 1.15, duration: 2600.ms),
              ),
              Text(
                'Your\n$year\nWrapped',
                style: KaivaTextStyles.displayMedium.copyWith(
                  fontSize: 52,
                  height: 1.05,
                  color: KaivaColors.textPrimary,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOutCubic),
            ],
          ),
          const SizedBox(height: 40),
          _CountUp(
            value: minutes,
            style: KaivaTextStyles.displayMedium.copyWith(
              fontSize: 44,
              color: KaivaColors.accentBright,
            ),
            suffix: '',
          ).animate(delay: 400.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 4),
          Text('minutes listened',
                  style: KaivaTextStyles.bodyLarge
                      .copyWith(color: KaivaColors.textSecondary))
              .animate(delay: 600.ms)
              .fadeIn(),
        ],
      ),
    );
  }
}

class _TopSongSection extends StatelessWidget {
  final WrappedSong song;
  const _TopSongSection({required this.song});

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR #1 SONG',
              style: KaivaTextStyles.labelSmall.copyWith(
                color: KaivaColors.accentPrimary,
                letterSpacing: 3,
              )),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: song.artworkUrl,
              height: 240,
              width: 240,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  height: 240,
                  width: 240,
                  color: KaivaColors.backgroundTertiary),
              errorWidget: (_, __, ___) => Container(
                  height: 240,
                  width: 240,
                  color: KaivaColors.backgroundTertiary,
                  child: const Icon(Icons.music_note,
                      color: KaivaColors.textMuted, size: 64)),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scaleXY(begin: 0.85, curve: Curves.easeOutBack),
          const SizedBox(height: 20),
          Text(song.title,
              style: KaivaTextStyles.displayMedium.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text(song.artist,
              style: KaivaTextStyles.bodyLarge
                  .copyWith(color: KaivaColors.textSecondary)),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: KaivaColors.accentGlow,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: KaivaColors.accentPrimary, width: 0.5),
            ),
            child: Text('${song.playCount} plays',
                style: KaivaTextStyles.labelMedium
                    .copyWith(color: KaivaColors.accentPrimary)),
          ),
        ],
      ),
    );
  }
}

class _TopSongsList extends StatelessWidget {
  final List<WrappedSong> songs;
  const _TopSongsList({required this.songs});

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOP SONGS',
              style: KaivaTextStyles.labelSmall.copyWith(
                color: KaivaColors.textMuted,
                letterSpacing: 3,
              )),
          const SizedBox(height: 20),
          ...List.generate(songs.length, (i) {
            final s = songs[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text('${i + 1}',
                        style: KaivaTextStyles.displayMedium.copyWith(
                          fontSize: 26,
                          color: KaivaColors.accentBright,
                        )),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: s.artworkUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 44,
                          height: 44,
                          color: KaivaColors.backgroundTertiary),
                      errorWidget: (_, __, ___) => Container(
                          width: 44,
                          height: 44,
                          color: KaivaColors.backgroundTertiary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KaivaTextStyles.titleMedium),
                        Text(s.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KaivaTextStyles.bodySmall
                                .copyWith(color: KaivaColors.textMuted)),
                      ],
                    ),
                  ),
                  Text('${s.playCount}',
                      style: KaivaTextStyles.bodyMedium
                          .copyWith(color: KaivaColors.textSecondary)),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: (80 * i).ms, duration: 350.ms)
                .slideX(begin: 0.15, curve: Curves.easeOut);
          }),
        ],
      ),
    );
  }
}

class _TopArtistSection extends StatelessWidget {
  final WrappedArtist artist;
  const _TopArtistSection({required this.artist});

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        children: [
          Text('YOUR TOP ARTIST',
              style: KaivaTextStyles.labelSmall.copyWith(
                color: KaivaColors.accentPrimary,
                letterSpacing: 3,
              )),
          const SizedBox(height: 28),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    KaivaColors.accentPrimary.withValues(alpha: 0.4),
                    KaivaColors.accentPrimary.withValues(alpha: 0.0),
                  ]),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.95, end: 1.1, duration: 2200.ms),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: KaivaColors.accentPrimary,
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: artist.artworkUrl,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 150,
                        height: 150,
                        color: KaivaColors.backgroundTertiary),
                    errorWidget: (_, __, ___) => Container(
                        width: 150,
                        height: 150,
                        color: KaivaColors.backgroundTertiary,
                        child: const Icon(Icons.person_rounded,
                            color: KaivaColors.textMuted, size: 56)),
                  ),
                ),
              ).animate().scaleXY(
                  begin: 0.8,
                  duration: 500.ms,
                  curve: Curves.easeOutBack),
            ],
          ),
          const SizedBox(height: 24),
          Text(artist.name,
              style: KaivaTextStyles.displayMedium.copyWith(fontSize: 30),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('${artist.minutes} minutes together',
              style: KaivaTextStyles.bodyLarge
                  .copyWith(color: KaivaColors.textSecondary)),
        ],
      ),
    );
  }
}

class _TopArtistsRow extends StatelessWidget {
  final List<WrappedArtist> artists;
  const _TopArtistsRow({required this.artists});

  @override
  Widget build(BuildContext context) {
    return _Section(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text('TOP ARTISTS',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  letterSpacing: 3,
                  color: KaivaColors.textMuted,
                  fontWeight: FontWeight.w600,
                )),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              itemCount: artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (_, i) {
                final a = artists[i];
                return Column(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: a.artworkUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            width: 76,
                            height: 76,
                            color: KaivaColors.backgroundTertiary),
                        errorWidget: (_, __, ___) => Container(
                            width: 76,
                            height: 76,
                            color: KaivaColors.backgroundTertiary,
                            child: const Icon(Icons.person_rounded,
                                color: KaivaColors.textMuted)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: KaivaTextStyles.bodySmall),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalitySection extends StatelessWidget {
  final String title;
  final String blurb;
  const _PersonalitySection({required this.title, required this.blurb});

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KaivaColors.accentPrimary.withValues(alpha: 0.25),
              KaivaColors.secondaryAccent.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(color: KaivaColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("YOU'RE A",
                style: KaivaTextStyles.labelSmall.copyWith(
                  color: KaivaColors.textSecondary,
                  letterSpacing: 3,
                )),
            const SizedBox(height: 10),
            Text(title,
                style: KaivaTextStyles.displayMedium.copyWith(fontSize: 38)),
            const SizedBox(height: 10),
            Text(blurb,
                style: KaivaTextStyles.bodyLarge
                    .copyWith(color: KaivaColors.textSecondary)),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.15, curve: Curves.easeOutCubic),
    );
  }
}

class _GenreSection extends StatelessWidget {
  final List<WrappedGenre> genres;
  const _GenreSection({required this.genres});

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR SOUND',
              style: KaivaTextStyles.labelSmall.copyWith(
                color: KaivaColors.textMuted,
                letterSpacing: 3,
              )),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, t, __) => CustomPaint(
                  painter: _DonutPainter(genres, t),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(genres.length, (i) {
            final g = genres[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _donutColor(i),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(g.label,
                          style: KaivaTextStyles.bodyMedium)),
                  Text('${(g.fraction * 100).round()}%',
                      style: KaivaTextStyles.bodyMedium
                          .copyWith(color: KaivaColors.textSecondary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

Color _donutColor(int i) {
  const palette = [
    KaivaColors.accentPrimary,
    KaivaColors.accentBright,
    KaivaColors.secondaryAccent,
    KaivaColors.accentDeep,
    KaivaColors.textSecondary,
  ];
  return palette[i % palette.length];
}

class _DonutPainter extends CustomPainter {
  final List<WrappedGenre> genres;
  final double t;
  _DonutPainter(this.genres, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    double start = -pi / 2;
    for (int i = 0; i < genres.length; i++) {
      final sweep = 2 * pi * genres[i].fraction * t;
      final paint = Paint()
        ..color = _donutColor(i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.t != t;
}

class _MonthsSection extends StatelessWidget {
  final List<int> minutes;
  const _MonthsSection({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final maxV = (minutes.fold<int>(0, max)).clamp(1, 1 << 30);
    const labels = [
      'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
    ];
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MINUTES BY MONTH',
              style: KaivaTextStyles.labelSmall.copyWith(
                color: KaivaColors.textMuted,
                letterSpacing: 3,
              )),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (i) {
                final frac = minutes[i] / maxV;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: frac),
                          duration: Duration(milliseconds: 500 + i * 60),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Container(
                            height: 120 * v + 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  KaivaColors.accentBright,
                                  KaivaColors.accentPrimary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(labels[i],
                            style: KaivaTextStyles.labelSmall
                                .copyWith(color: KaivaColors.textMuted)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharePoster extends StatelessWidget {
  final GlobalKey posterKey;
  final WrappedData data;
  final bool sharing;
  final VoidCallback onShare;

  const _SharePoster({
    required this.posterKey,
    required this.data,
    required this.sharing,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        children: [
          RepaintBoundary(
            key: posterKey,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1305),
                    KaivaColors.backgroundPrimary,
                  ],
                ),
                border:
                    Border.all(color: KaivaColors.accentPrimary, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: KaivaColors.accentPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text('KAIVA WRAPPED ${data.year}',
                          style: KaivaTextStyles.labelSmall.copyWith(
                            color: KaivaColors.accentPrimary,
                            letterSpacing: 2,
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _posterStat('${data.totalMinutes}', 'minutes'),
                  const SizedBox(height: 14),
                  if (data.topSong != null)
                    _posterStat(data.topSong!.title, 'top song',
                        small: true),
                  const SizedBox(height: 14),
                  if (data.topArtist != null)
                    _posterStat(data.topArtist!.name, 'top artist',
                        small: true),
                  const SizedBox(height: 14),
                  _posterStat(data.personality, 'your vibe', small: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: sharing ? null : onShare,
              style: FilledButton.styleFrom(
                backgroundColor: KaivaColors.accentPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              icon: sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: KaivaColors.textOnAccent))
                  : const Icon(Icons.ios_share_rounded,
                      color: KaivaColors.textOnAccent),
              label: const Text('Share your Wrapped',
                  style: TextStyle(
                      color: KaivaColors.textOnAccent,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterStat(String value, String label, {bool small = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KaivaTextStyles.displayMedium.copyWith(
              fontSize: small ? 22 : 40,
              color: KaivaColors.accentBright,
            )),
        Text(label.toUpperCase(),
            style: KaivaTextStyles.labelSmall.copyWith(
              color: KaivaColors.textMuted,
              letterSpacing: 2,
            )),
      ],
    );
  }
}

// Count-up number used in the hero.
class _CountUp extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String suffix;
  const _CountUp(
      {required this.value, required this.style, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) =>
          Text('${v.round()}$suffix', style: style),
    );
  }
}
