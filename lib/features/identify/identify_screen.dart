import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../core/utils/song_loader.dart';
import '../player/player_provider.dart';
import 'song_recognition_service.dart';

enum _Phase { idle, listening, searching, matched, noMatch }

class IdentifyScreen extends ConsumerStatefulWidget {
  const IdentifyScreen({super.key});

  @override
  ConsumerState<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends ConsumerState<IdentifyScreen>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();
  final _service = SongRecognitionService();

  late final AnimationController _pulse;
  _Phase _phase = _Phase.idle;
  String _message = '';
  RecognitionResult? _result;
  Song? _matchedSong;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    if (!await _recorder.hasPermission()) {
      setState(() {
        _phase = _Phase.noMatch;
        _message = 'Microphone permission is required to identify songs.';
      });
      return;
    }

    setState(() {
      _phase = _Phase.listening;
      _result = null;
      _matchedSong = null;
    });

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/kaiva_identify.m4a';

    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
        path: path,
      );
      // Listen for ~8 seconds.
      await Future<void>.delayed(const Duration(seconds: 8));
      final recordedPath = await _recorder.stop();

      if (!mounted) return;
      setState(() => _phase = _Phase.searching);

      final result = await _service.recognize(recordedPath ?? path);
      if (!mounted) return;

      if (result.matched) {
        final song = await _findSong(result.title!, result.artist ?? '');
        if (!mounted) return;
        setState(() {
          _result = result;
          _matchedSong = song;
          _phase = _Phase.matched;
        });
      } else {
        setState(() {
          _result = result;
          _phase = _Phase.noMatch;
          _message = result.message ?? 'No match found.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.noMatch;
        _message = 'Could not record audio. Please try again.';
      });
    }
  }

  Future<void> _cancel() async {
    try {
      await _recorder.stop();
    } catch (_) {}
    if (mounted) setState(() => _phase = _Phase.idle);
  }

  Future<Song?> _findSong(String title, String artist) async {
    try {
      final api = ApiClient.instance();
      final resp = await api.get(ApiEndpoints.searchSongs,
          params: {'query': '$title $artist', 'limit': '1'});
      final data = (resp.data as Map<String, dynamic>?)?['data'];
      final results =
          ((data as Map<String, dynamic>?)?['results'] as List<dynamic>?) ??
              const [];
      if (results.isEmpty) return null;
      return Song.fromJson(results.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaivaColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Identify Song',
            style: KaivaTextStyles.headlineLarge),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: switch (_phase) {
            _Phase.idle => _idle(),
            _Phase.listening => _listening(),
            _Phase.searching => _searching(),
            _Phase.matched => _matched(),
            _Phase.noMatch => _noMatch(),
          },
        ),
      ),
    );
  }

  Widget _orb({required bool active, IconData icon = Icons.mic_rounded}) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (active) ...[
                _ring(0.6 + t * 0.6, (1 - t) * 0.5),
                _ring(0.6 + ((t + 0.33) % 1) * 0.6,
                    (1 - ((t + 0.33) % 1)) * 0.5),
                _ring(0.6 + ((t + 0.66) % 1) * 0.6,
                    (1 - ((t + 0.66) % 1)) * 0.5),
              ],
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? KaivaColors.accentPrimary
                      : KaivaColors.backgroundTertiary,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: KaivaColors.accentPrimary
                                .withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Icon(icon,
                    size: 52,
                    color: active
                        ? KaivaColors.textOnAccent
                        : KaivaColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: KaivaColors.accentPrimary
                .withValues(alpha: opacity.clamp(0.0, 1.0)),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _idle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(onTap: _start, child: _orb(active: false)),
        const SizedBox(height: 40),
        Text('Tap to identify',
            style: KaivaTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Point your phone at the music playing around you.',
          textAlign: TextAlign.center,
          style: KaivaTextStyles.bodyMedium
              .copyWith(color: KaivaColors.textSecondary),
        ),
      ],
    );
  }

  Widget _listening() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _orb(active: true),
        const SizedBox(height: 40),
        Text('Listening…', style: KaivaTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text('Hold still for a few seconds',
            style: KaivaTextStyles.bodyMedium
                .copyWith(color: KaivaColors.textSecondary)),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _cancel,
          child: Text('Cancel',
              style: KaivaTextStyles.bodyMedium
                  .copyWith(color: KaivaColors.textMuted)),
        ),
      ],
    );
  }

  Widget _searching() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _orb(active: true, icon: Icons.graphic_eq_rounded),
        const SizedBox(height: 40),
        Text('Searching…', style: KaivaTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text('Matching the sample',
            style: KaivaTextStyles.bodyMedium
                .copyWith(color: KaivaColors.textSecondary)),
      ],
    );
  }

  Widget _matched() {
    final r = _result!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 56, color: KaivaColors.success),
        const SizedBox(height: 20),
        Text(r.title ?? 'Unknown',
            textAlign: TextAlign.center,
            style: KaivaTextStyles.displayMedium.copyWith(fontSize: 24)),
        const SizedBox(height: 6),
        Text(r.artist ?? '',
            textAlign: TextAlign.center,
            style: KaivaTextStyles.bodyLarge
                .copyWith(color: KaivaColors.textSecondary)),
        const SizedBox(height: 32),
        if (_matchedSong != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final fresh = await fetchFreshQueue([_matchedSong!]);
                await ref.read(audioHandlerProvider).playQueue(fresh, 0);
                if (mounted) context.pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: KaivaColors.accentPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.play_arrow_rounded,
                  color: KaivaColors.textOnAccent),
              label: const Text('Play in Kaiva',
                  style: TextStyle(
                      color: KaivaColors.textOnAccent,
                      fontWeight: FontWeight.w600)),
            ),
          )
        else
          Text("Couldn't find this song in the catalogue.",
              textAlign: TextAlign.center,
              style: KaivaTextStyles.bodySmall
                  .copyWith(color: KaivaColors.textMuted)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _phase = _Phase.idle),
          child: Text('Identify another',
              style: KaivaTextStyles.bodyMedium
                  .copyWith(color: KaivaColors.accentPrimary)),
        ),
      ],
    );
  }

  Widget _noMatch() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off_rounded,
            size: 56, color: KaivaColors.textMuted),
        const SizedBox(height: 20),
        Text('No match', style: KaivaTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text(_message,
            textAlign: TextAlign.center,
            style: KaivaTextStyles.bodyMedium
                .copyWith(color: KaivaColors.textSecondary)),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () => setState(() => _phase = _Phase.idle),
          style: FilledButton.styleFrom(
              backgroundColor: KaivaColors.accentPrimary),
          child: const Text('Try again',
              style: TextStyle(color: KaivaColors.textOnAccent)),
        ),
      ],
    );
  }
}
