import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marquee/marquee.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../core/models/song.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/kaiva_database.dart' show SongsCompanion;
import '../../core/firebase/sync_service.dart';
import 'package:drift/drift.dart' show Value;
import 'player_provider.dart';
import 'widgets/seek_bar.dart';
import 'widgets/player_controls.dart';
import 'widgets/lyrics_view.dart';
import 'widgets/queue_sheet.dart';
import 'widgets/sleep_timer_sheet.dart';
import '../../shared/widgets/waveform_animation.dart';
import '../../shared/widgets/song_options_sheet.dart';
import 'widgets/fullscreen_art_view.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgColorCtrl;

  Color _bgColor = const Color(0xFF0B0D12);
  Color _prevBgColor = const Color(0xFF0B0D12);
  String? _lastSongId;
  int _pageIndex = 0;
  double _dragDeltaX = 0;
  double _dragDeltaY = 0;

  @override
  void initState() {
    super.initState();
    _bgColorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _bgColorCtrl.dispose();
    super.dispose();
  }

  void _onSongChanged(Song song) async {
    if (song.id == _lastSongId) return;
    _lastSongId = song.id;

    final colorAsync = ref.read(dominantColorProvider(song.highResArtworkUrl));
    final newColor = colorAsync.valueOrNull ?? const Color(0xFF0B0D12);

    setState(() {
      _prevBgColor = _bgColor;
      _bgColor = Color.lerp(newColor, const Color(0xFF0B0D12), 0.6)!;
    });
    _bgColorCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    // Only watch the song here — NOT isPlaying / position
    final song = ref.watch(currentSongProvider).valueOrNull;

    if (song != null) _onSongChanged(song);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _bgColorCtrl,
        builder: (context, child) {
          final color =
              Color.lerp(_prevBgColor, _bgColor, _bgColorCtrl.value)!;
          return Container(
            // Editorial Noir radial gradient: amber-tinted glow from top center
            // down to true black background
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1),
                radius: 1.4,
                colors: [
                  Color.lerp(
                    color.withValues(alpha: 0.7),
                    KaivaColors.accentDim.withValues(alpha: 0.35),
                    0.5,
                  )!,
                  KaivaColors.backgroundPrimary,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
            child: child,
          );
        },
        // child is rebuilt only on song changes, not position ticks
        child: SafeArea(
          child: song == null
              ? const Center(
                  child: Text('Nothing playing',
                      style: TextStyle(color: KaivaColors.textMuted)))
              : _buildContent(song),
        ),
      ),
    );
  }

  Widget _buildContent(Song song) {
    final handler = ref.read(audioHandlerProvider);
    return GestureDetector(
      onHorizontalDragUpdate: (d) => _dragDeltaX += d.delta.dx,
      onHorizontalDragEnd: (d) {
        if (_dragDeltaX < -60) {
          HapticFeedback.lightImpact();
          handler.skipToNext();
        } else if (_dragDeltaX > 60) {
          HapticFeedback.lightImpact();
          handler.skipToPrevious();
        }
        _dragDeltaX = 0;
      },
      onVerticalDragUpdate: (d) => _dragDeltaY += d.delta.dy,
      onVerticalDragEnd: (d) {
        if (_dragDeltaY > 80) {
          HapticFeedback.mediumImpact();
          handler.stop();
          context.pop();
        }
        _dragDeltaY = 0;
      },
      child: Column(
      children: [
        _buildTopBar(song),
        const SizedBox(height: 16),
        _AlbumArtWidget(
          song: song,
          onTap: () => Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.transparent,
              pageBuilder: (_, __, ___) => FullscreenArtView(song: song),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(
                opacity: anim,
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSongInfo(song),
        const SizedBox(height: 16),
        const SeekBar(),
        const SizedBox(height: 8),
        const PlayerControls(),
        const SizedBox(height: 16),
        _buildBottomTabs(song),
      ],
      ),
    );
  }

  Widget _buildTopBar(Song song) {
    final timerActive = ref.watch(sleepTimerActiveProvider);
    final timerRemaining = ref.watch(sleepTimerRemainingProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            color: KaivaColors.textSecondary,
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('NOW PLAYING', style: KaivaTextStyles.sectionHeader),
                Text(
                  song.album,
                  style: KaivaTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (timerActive)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bedtime_outlined,
                      size: 14, color: KaivaColors.accentPrimary),
                  const SizedBox(width: 2),
                  Text(
                    _formatTimerRemaining(timerRemaining),
                    style: KaivaTextStyles.labelSmall
                        .copyWith(color: KaivaColors.accentPrimary),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 24),
            color: KaivaColors.textSecondary,
            onPressed: () => _showSongOptions(context, song),
          ),
        ],
      ),
    );
  }

  String _formatTimerRemaining(Duration d) {
    if (d.inSeconds < 0) return 'EoT';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildSongInfo(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 34,
                  child: song.title.length > 24
                      ? Marquee(
                          text: song.title,
                          style: KaivaTextStyles.songTitle.copyWith(
                            color: KaivaColors.accentBright,
                          ),
                          blankSpace: 40,
                          velocity: 30,
                          pauseAfterRound: const Duration(seconds: 2),
                        )
                      : Text(
                          song.title,
                          style: KaivaTextStyles.songTitle.copyWith(
                            color: KaivaColors.accentBright,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    if (song.artistId.isNotEmpty) {
                      context.push('/artist/${song.artistId}');
                    }
                  },
                  child: Text(
                    song.artist,
                    style: KaivaTextStyles.artistName.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: KaivaColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const _PlayerWaveform(),
          const SizedBox(width: 8),
          _LikeButton(song: song),
        ],
      ),
    );
  }

  Widget _buildBottomTabs(Song song) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tab('Lyrics', 0),
              const SizedBox(width: 24),
              _tab('Queue', 1),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _pageIndex == 0
                  ? LyricsView(key: ValueKey(song.id), songId: song.id)
                  : const QueueSheet(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = _pageIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _pageIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? KaivaColors.accentGlow : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected
                ? KaivaColors.accentPrimary
                : KaivaColors.borderSubtle,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: KaivaTextStyles.labelLarge.copyWith(
            color:
                selected ? KaivaColors.accentPrimary : KaivaColors.textMuted,
          ),
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: KaivaColors.backgroundSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: KaivaColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded,
                  color: KaivaColors.textSecondary),
              title: const Text('Add to playlist',
                  style: KaivaTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SongOptionsSheet(song: song),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded,
                  color: KaivaColors.textSecondary),
              title: const Text('Add to queue',
                  style: KaivaTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                ref.read(audioHandlerProvider).addToQueue(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.skip_next_rounded,
                  color: KaivaColors.textSecondary),
              title:
                  const Text('Play next', style: KaivaTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                ref.read(audioHandlerProvider).addNext(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded,
                  color: KaivaColors.textSecondary),
              title:
                  const Text('Go to artist', style: KaivaTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                if (song.artistId.isNotEmpty) {
                  context.push('/artist/${song.artistId}');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.album_rounded,
                  color: KaivaColors.textSecondary),
              title:
                  const Text('Go to album', style: KaivaTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                if (song.albumId.isNotEmpty) {
                  context.push('/album/${song.albumId}');
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Album art — isolated widget with RepaintBoundary ──────────
// Watches isPlayingProvider independently so rotation changes
// never cause the parent PlayerScreen to rebuild.
class _AlbumArtWidget extends ConsumerWidget {
  final Song song;
  final VoidCallback? onTap;

  const _AlbumArtWidget({required this.song, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isPlaying ? 1.0 : 0.92,
          duration: const Duration(milliseconds: 300),
          child: Hero(
            tag: 'album_art_${song.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: song.highResArtworkUrl,
                width: 280,
                height: 280,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 280,
                  height: 280,
                  color: KaivaColors.backgroundTertiary,
                  child: const Icon(Icons.music_note,
                      color: KaivaColors.textMuted, size: 80),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 280,
                  height: 280,
                  color: KaivaColors.backgroundTertiary,
                  child: const Icon(Icons.music_note,
                      color: KaivaColors.textMuted, size: 80),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Player waveform ───────────────────────────────────────────
class _PlayerWaveform extends ConsumerWidget {
  const _PlayerWaveform();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    return WaveformAnimation(
      isPlaying: isPlaying,
      width: 28,
      height: 22,
      barCount: 4,
    );
  }
}

// ── Like button ───────────────────────────────────────────────
class _LikeButton extends ConsumerWidget {
  final Song song;
  const _LikeButton({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return StreamBuilder<bool>(
      stream: db.likedSongsDao.watchIsLiked(song.id),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;
        return IconButton(
          icon: Icon(
            isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isLiked
                ? KaivaColors.accentPrimary
                : KaivaColors.textSecondary,
          ),
          iconSize: 26,
          onPressed: () async {
            HapticFeedback.lightImpact();
            // Always ensure song row exists before toggling like
            await db.songsDao.upsertSong(SongsCompanion(
              id: Value(song.id),
              title: Value(song.title),
              artist: Value(song.artist),
              artistId: Value(song.artistId),
              album: Value(song.album),
              albumId: Value(song.albumId),
              artworkUrl: Value(song.artworkUrl),
              duration: Value(song.durationSeconds),
              language: Value(song.language),
              streamUrl: Value(song.bestStreamUrl),
              hasLyrics: Value(song.hasLyrics),
              isExplicit: Value(song.isExplicit),
              year: Value(song.year),
            ));
            await db.likedSongsDao.toggleLike(song.id);
            if (!isLiked) {
              ref.read(syncServiceProvider).pushLikedSong(song.id);
            } else {
              ref.read(syncServiceProvider).removeLikedSong(song.id);
            }
          },
        );
      },
    );
  }
}
