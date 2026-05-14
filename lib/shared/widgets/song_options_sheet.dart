import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/kaiva_database.dart' show SongsCompanion;
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../core/utils/settings_keys.dart';
import '../../features/downloads/download_manager.dart';
import '../../features/library/library_provider.dart';
import '../../features/player/player_provider.dart';
import 'album_art.dart';

class SongOptionsSheet extends ConsumerStatefulWidget {
  final Song song;

  const SongOptionsSheet({super.key, required this.song});

  @override
  ConsumerState<SongOptionsSheet> createState() => _SongOptionsSheetState();
}

class _SongOptionsSheetState extends ConsumerState<SongOptionsSheet> {
  late bool _isLiked;
  bool _likeAnimating = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.song.isLiked;
    _loadLikedState();
  }

  Future<void> _loadLikedState() async {
    final db = ref.read(databaseProvider);
    final liked = await db.likedSongsDao.isLiked(widget.song.id);
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLiked = !_isLiked;
      _likeAnimating = true;
    });
    final db = ref.read(databaseProvider);
    await db.likedSongsDao.toggleLike(widget.song.id);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _likeAnimating = false);
    });
  }

  void _addToQueue() {
    ref.read(audioHandlerProvider).addToQueue(widget.song);
    Navigator.of(context).pop();
    _showSnack('Added to queue');
  }

  void _playNext() {
    ref.read(audioHandlerProvider).addNext(widget.song);
    Navigator.of(context).pop();
    _showSnack('Playing next');
  }

  void _download() {
    ref.read(downloadManagerProvider).downloadSong(widget.song);
    Navigator.of(context).pop();
    _showSnack('Download started');
  }

  void _removeDownload() {
    ref.read(downloadManagerProvider).deleteDownload(widget.song);
    Navigator.of(context).pop();
    _showSnack('Download removed');
  }

  void _share() {
    Share.share(
      'Listen to "${widget.song.title}" by ${widget.song.artist} on Kaiva',
      subject: widget.song.title,
    );
  }

  void _hideSong() {
    final box = Hive.box('kaiva_settings');
    final hidden = List<String>.from(
      box.get(SettingsKeys.hiddenSongs, defaultValue: <String>[]),
    );
    if (!hidden.contains(widget.song.id)) {
      hidden.add(widget.song.id);
      box.put(SettingsKeys.hiddenSongs, hidden);
    }
    Navigator.of(context).pop();
    _showSnack('Song hidden from recommendations for 30 days');
  }

  void _showSongInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: KaivaColors.backgroundSecondary,
        title: const Text('Song Info', style: KaivaTextStyles.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Title', widget.song.title),
            _InfoRow('Artist', widget.song.artist),
            _InfoRow('Album', widget.song.album),
            _InfoRow('Duration', widget.song.formattedDuration),
            _InfoRow('Quality', '${widget.song.qualityKbps} kbps'),
            _InfoRow('Language', widget.song.language),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close',
                style: TextStyle(color: KaivaColors.accentPrimary)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: KaivaTextStyles.bodyMedium),
        behavior: SnackBarBehavior.floating,
        backgroundColor: KaivaColors.backgroundElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDownloaded = ref.watch(downloadedSongsProvider).valueOrNull
            ?.any((s) => s.id == widget.song.id) ??
        widget.song.isDownloaded;

    return Container(
      decoration: const BoxDecoration(
        color: KaivaColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: KaivaColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Song header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                AlbumArt(url: widget.song.artworkUrl, size: 52, borderRadius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.title,
                        style: KaivaTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.song.artist,
                        style: KaivaTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: KaivaColors.borderSubtle, height: 1),
          // Options (staggered fade-in)
          ..._buildOptions(isDownloaded).indexed.map(
            (entry) => entry.$2
                .animate(delay: Duration(milliseconds: 30 * entry.$1))
                .fadeIn(duration: 150.ms),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(bool isDownloaded) => [
    _Option(
      icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      label: _isLiked ? 'Unlike' : 'Like',
      iconColor: _isLiked ? Colors.redAccent : null,
      onTap: _toggleLike,
      trailing: _likeAnimating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
            )
          : null,
    ),
    _Option(
      icon: Icons.skip_next_outlined,
      label: 'Play Next',
      onTap: _playNext,
    ),
    _Option(
      icon: Icons.queue_music_outlined,
      label: 'Add to Queue',
      onTap: _addToQueue,
    ),
    _Option(
      icon: Icons.playlist_add_rounded,
      label: 'Add to Playlist',
      onTap: () {
        Navigator.of(context).pop();
        _showPlaylistPicker();
      },
    ),
    _Option(
      icon: isDownloaded
          ? Icons.delete_outline_rounded
          : Icons.download_outlined,
      label: isDownloaded ? 'Remove Download' : 'Download',
      onTap: isDownloaded ? _removeDownload : _download,
    ),
    _Option(
      icon: Icons.lyrics_outlined,
      label: 'View Lyrics',
      onTap: () {
        Navigator.of(context).pop();
        context.push('/player');
      },
    ),
    _Option(
      icon: Icons.person_outline_rounded,
      label: 'Go to Artist',
      onTap: () {
        Navigator.of(context).pop();
        if (widget.song.artistId.isNotEmpty) {
          context.push('/artist/${widget.song.artistId}');
        }
      },
    ),
    _Option(
      icon: Icons.album_outlined,
      label: 'Go to Album',
      onTap: () {
        Navigator.of(context).pop();
        if (widget.song.albumId.isNotEmpty) {
          context.push('/album/${widget.song.albumId}');
        }
      },
    ),
    _Option(
      icon: Icons.share_outlined,
      label: 'Share Song',
      onTap: _share,
    ),
    _Option(
      icon: Icons.block_outlined,
      label: 'Hide Song',
      onTap: _hideSong,
    ),
    _Option(
      icon: Icons.info_outline_rounded,
      label: 'Song Info',
      onTap: _showSongInfo,
    ),
  ];

  void _showPlaylistPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PlaylistPickerSheet(song: widget.song),
    );
  }
}

// ── Playlist picker sheet ─────────────────────────────────────
class _PlaylistPickerSheet extends ConsumerWidget {
  final Song song;
  const _PlaylistPickerSheet({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(localPlaylistsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: KaivaColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add to Playlist', style: KaivaTextStyles.headlineMedium),
          const SizedBox(height: 12),
          playlistsAsync.when(
            data: (pls) => pls.isEmpty
                ? const Text(
                    'No playlists yet. Create one in Library.',
                    style: KaivaTextStyles.bodyMedium,
                  )
                : Column(
                    children: pls
                        .map((pl) => ListTile(
                              leading: const Icon(
                                Icons.queue_music_outlined,
                                color: KaivaColors.textMuted,
                              ),
                              title: Text(pl.name, style: KaivaTextStyles.bodyMedium),
                              onTap: () async {
                                final db = ref.read(databaseProvider);
                                final count = await db.playlistsDao
                                    .watchPlaylistSongs(pl.id)
                                    .first
                                    .then((songs) => songs.length);
                                await db.songsDao.upsertSong(
                                  _songCompanion(song),
                                );
                                await db.playlistsDao.addSongToPlaylist(
                                  pl.id,
                                  song.id,
                                  count,
                                );
                                if (context.mounted) Navigator.of(context).pop();
                              },
                            ))
                        .toList(),
                  ),
            loading: () =>
                const CircularProgressIndicator(color: KaivaColors.accentPrimary),
            error: (_, __) => const Text('Could not load playlists.'),
          ),
        ],
      ),
    );
  }
}

// ── Option row ────────────────────────────────────────────────
class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;

  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? KaivaColors.textSecondary, size: 22),
      title: Text(label, style: KaivaTextStyles.bodyMedium),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }
}

// ── Info row (for song info dialog) ──────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: KaivaTextStyles.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: KaivaTextStyles.bodyMedium.copyWith(
                color: KaivaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

SongsCompanion _songCompanion(Song song) => SongsCompanion(
  id: Value(song.id),
  title: Value(song.title),
  artist: Value(song.artist),
  album: Value(song.album),
  albumId: Value(song.albumId.isEmpty ? null : song.albumId),
  artistId: Value(song.artistId),
  artworkUrl: Value(song.artworkUrl),
  duration: Value(song.durationSeconds),
  language: Value(song.language),
  streamUrl: Value(song.bestStreamUrl),
  hasLyrics: Value(song.hasLyrics),
  isExplicit: Value(song.isExplicit),
  year: Value(song.year),
  qualityKbps: Value(song.qualityKbps),
  cachedAt: Value(DateTime.now()),
);
