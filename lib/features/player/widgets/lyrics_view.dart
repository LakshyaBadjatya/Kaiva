import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/lyrics.dart';
import '../../../core/theme/kaiva_colors.dart';
import '../../../core/theme/kaiva_text_styles.dart';
import '../player_provider.dart';

class LyricsView extends ConsumerStatefulWidget {
  final String songId;
  const LyricsView({super.key, required this.songId});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  Lyrics? _lyrics;
  bool _loading = true;
  String? _error;
  int _currentLineIndex = 0;
  bool _userScrolling = false;
  Timer? _scrollResumeTimer;

  final ItemScrollController _scrollCtrl = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void dispose() {
    _scrollResumeTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    try {
      final response =
          await ApiClient.instance().get(ApiEndpoints.lyrics(widget.songId));
      final body = response.data as Map<String, dynamic>?;
      // API may return { data: { lyrics: "..." } } or { lyrics: "..." } directly
      final inner = body?['data'] as Map<String, dynamic>?
          ?? (body?.containsKey('lyrics') == true ? body : null);
      if (inner != null && inner['lyrics'] != null) {
        setState(() {
          _lyrics = Lyrics.fromJson(widget.songId, inner);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'unavailable';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'unavailable';
        _loading = false;
      });
    }
  }

  void _onPositionChanged(Duration position) {
    final lyrics = _lyrics;
    if (lyrics == null || !lyrics.isTimed || _userScrolling) return;

    int idx = 0;
    for (int i = 0; i < lyrics.lines.length; i++) {
      final ts = lyrics.lines[i].timestamp;
      if (ts != null && ts <= position) idx = i;
    }

    if (idx != _currentLineIndex) {
      setState(() => _currentLineIndex = idx);
      if (_scrollCtrl.isAttached) {
        _scrollCtrl.scrollTo(
          index: idx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.4,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to playback position for synced scrolling
    ref.listen(positionProvider, (_, next) {
      if (next.hasValue) _onPositionChanged(next.value!);
    });

    if (_loading) return _buildShimmer();
    if (_error != null || _lyrics == null) return _buildUnavailable();

    final lyrics = _lyrics!;
    if (!lyrics.isTimed && lyrics.rawText != null) {
      return _buildPlainText(lyrics.rawText!);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollStartNotification) {
          _userScrolling = true;
          _scrollResumeTimer?.cancel();
        } else if (n is ScrollEndNotification) {
          _scrollResumeTimer = Timer(const Duration(seconds: 5), () {
            setState(() => _userScrolling = false);
          });
        }
        return false;
      },
      child: ScrollablePositionedList.builder(
        itemCount: lyrics.lines.length,
        itemScrollController: _scrollCtrl,
        itemPositionsListener: _positionsListener,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        itemBuilder: (context, i) {
          final line = lyrics.lines[i];
          final isCurrent = i == _currentLineIndex;
          final isPast = i < _currentLineIndex;

          return GestureDetector(
            onTap: line.timestamp != null
                ? () => ref.read(audioHandlerProvider).seek(line.timestamp!)
                : null,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: isCurrent
                  ? KaivaTextStyles.songTitle.copyWith(
                      fontSize: 18,
                      color: KaivaColors.accentPrimary,
                    )
                  : KaivaTextStyles.bodyLarge.copyWith(
                      fontSize: 15,
                      color: isPast
                          ? KaivaColors.textMuted.withValues(alpha: 0.7)
                          : KaivaColors.textSecondary.withValues(alpha: 0.85),
                      height: 1.8,
                    ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(line.text, textAlign: TextAlign.center),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlainText(String text) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Text(
          text,
          style: KaivaTextStyles.bodyLarge.copyWith(
            color: KaivaColors.textSecondary,
            height: 1.8,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget _buildUnavailable() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lyrics_outlined, color: KaivaColors.textMuted, size: 48),
            SizedBox(height: 12),
            Text(
              'Lyrics not available for this song',
              style: TextStyle(color: KaivaColors.textMuted),
            ),
          ],
        ),
      );

  Widget _buildShimmer() => const Center(
        child: CircularProgressIndicator(color: KaivaColors.accentPrimary),
      );
}
