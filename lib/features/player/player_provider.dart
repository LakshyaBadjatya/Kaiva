import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart' show Color, NetworkImage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/models/song.dart';
import 'audio_handler.dart';

// ── Core handler provider ────────────────────────────────────
// Overridden in main.dart with the real AudioService instance
final audioHandlerProvider = Provider<KaivaAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider not initialized'),
);

// ── Current song ─────────────────────────────────────────────
final currentSongProvider = StreamProvider<Song?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem.map((item) {
    if (item == null) return null;
    final extras = item.extras ?? {};
    return Song(
      id: extras['songId'] as String? ?? '',
      title: item.title,
      artist: item.artist ?? '',
      artistId: '',
      album: item.album ?? '',
      albumId: '',
      artworkUrl: extras['artworkUrl'] as String? ?? item.artUri?.toString() ?? '',
      durationSeconds: item.duration?.inSeconds ?? 0,
      language: '',
      streamUrls: [],
    );
  });
});

// ── Playback state ───────────────────────────────────────────
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  return ref.watch(audioHandlerProvider).playbackState;
});

final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playbackStateProvider).valueOrNull?.playing ?? false;
});

// ── Position + duration ──────────────────────────────────────
final positionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioHandlerProvider).positionStream;
});

final durationProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(audioHandlerProvider).durationStream;
});

final positionDataProvider = StreamProvider<PositionData?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return positionDataStream(handler.player);
});

// ── Queue ─────────────────────────────────────────────────────
final queueProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(audioHandlerProvider).queue;
});

final currentIndexProvider = StreamProvider<int?>((ref) {
  return ref.watch(audioHandlerProvider)
      .playbackState
      .map((s) => s.queueIndex);
});

// ── Shuffle + loop ───────────────────────────────────────────
final shuffleProvider = StreamProvider<bool>((ref) {
  return ref.watch(audioHandlerProvider).shuffleModeStream;
});

final loopModeProvider = StreamProvider<LoopMode>((ref) {
  return ref.watch(audioHandlerProvider).loopModeStream;
});

// ── Player state (loading/playing/paused/stopped) ────────────
final playerStateProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(audioHandlerProvider).playerStateStream;
});

// ── Dominant color from album art ────────────────────────────
final dominantColorProvider =
    FutureProvider.family<Color, String>((ref, artworkUrl) async {
  if (artworkUrl.isEmpty) return const Color(0xFF0E0A05);
  try {
    final generator = await PaletteGenerator.fromImageProvider(
      NetworkImage(artworkUrl.replaceAll('150x150', '500x500')),
      maximumColorCount: 8,
    );
    return generator.dominantColor?.color ?? const Color(0xFF0E0A05);
  } catch (_) {
    return const Color(0xFF0E0A05);
  }
});
