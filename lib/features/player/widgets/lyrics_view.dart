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

// ── Public widget — used by both PlayerScreen and FullscreenArtView ──
class LyricsView extends ConsumerStatefulWidget {
  final String songId;

  /// When true, uses a larger base font suited for the fullscreen landscape view.
  final bool fullscreen;

  const LyricsView({super.key, required this.songId, this.fullscreen = false});

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
      final inner = body?['data'] as Map<String, dynamic>?
          ?? (body?.containsKey('lyrics') == true ? body : null);
      if (inner != null && inner['lyrics'] != null) {
        setState(() {
          _lyrics = Lyrics.fromJson(widget.songId, inner);
          _loading = false;
        });
      } else {
        setState(() { _error = 'unavailable'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'unavailable'; _loading = false; });
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
          index: (idx - 1).clamp(0, lyrics.lines.length - 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            if (mounted) setState(() => _userScrolling = false);
          });
        }
        return false;
      },
      child: ScrollablePositionedList.builder(
        itemCount: lyrics.lines.length,
        itemScrollController: _scrollCtrl,
        itemPositionsListener: _positionsListener,
        padding: EdgeInsets.symmetric(
          horizontal: widget.fullscreen ? 8 : 24,
          vertical: widget.fullscreen ? 16 : 40,
        ),
        itemBuilder: (context, i) => _LyricLine(
          text: lyrics.lines[i].text,
          distance: i - _currentLineIndex,
          fullscreen: widget.fullscreen,
          onTap: lyrics.lines[i].timestamp != null
              ? () => ref
                  .read(audioHandlerProvider)
                  .seek(lyrics.lines[i].timestamp!)
              : null,
        ),
      ),
    );
  }

  Widget _buildPlainText(String text) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: widget.fullscreen ? 8 : 24,
          vertical: widget.fullscreen ? 16 : 40,
        ),
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

// ── Single lyric line with cascade animation ──────────────────
class _LyricLine extends StatelessWidget {
  final String text;

  /// Signed distance from the active line: 0 = current, -1 = one above, +1 = one below.
  final int distance;
  final bool fullscreen;
  final VoidCallback? onTap;

  const _LyricLine({
    required this.text,
    required this.distance,
    required this.fullscreen,
    this.onTap,
  });

  // ── Style parameters by distance ──────────────────────────────
  static const double _baseFontNormal = 18;
  static const double _baseFontFullscreen = 15;

  double get _fontSize {
    final base = fullscreen ? _baseFontFullscreen : _baseFontNormal;
    if (distance == 0) return base + (fullscreen ? 4 : 6); // current: biggest
    final d = distance.abs();
    if (d == 1) return base;
    if (d == 2) return base - 1.5;
    return base - 3;
  }

  double get _opacity {
    if (distance == 0) return 1.0;
    final d = distance.abs();
    if (d == 1) return 0.55;
    if (d == 2) return 0.35;
    return 0.20;
  }

  FontWeight get _fontWeight {
    if (distance == 0) return FontWeight.w700;
    if (distance.abs() == 1) return FontWeight.w500;
    return FontWeight.w400;
  }

  Color get _color {
    if (distance == 0) return KaivaColors.textPrimary;
    // Lines above are slightly warmer; lines below cooler
    return distance < 0 ? KaivaColors.textSecondary : KaivaColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: fullscreen ? 4 : 6),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: _fontSize,
            fontWeight: _fontWeight,
            color: _color.withValues(alpha: _opacity),
            height: 1.5,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            opacity: _opacity,
            child: Text(
              text,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
