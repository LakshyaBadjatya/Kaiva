import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/database/kaiva_database.dart' show KaivaDatabase;
import '../../core/models/song.dart';
import '../../core/utils/live_activity_service.dart';

class KaivaAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  int _crossfadeSeconds = 0;
  Timer? _crossfadeTimer;
  StreamSubscription<Duration>? _positionSub;
  bool _isCrossfading = false;

  // Sleep timer — stop after current track ends
  bool stopAfterCurrentTrack = false;

  // Stats recording
  KaivaDatabase? _db;
  DateTime? _trackStartTime;
  String? _currentStatsId;
  String? _currentStatsArtistId;
  // Richer context captured at track-start for the play-events recorder
  String? _currentLanguage;
  String? _currentAlbum;
  Duration? _currentDuration;
  bool _currentEventCompleted = false; // set true when processingState=completed

  void setDatabase(KaivaDatabase db) => _db = db;

  /// Hook invoked when the user reaches the end of the queue (no `hasNext`).
  /// The recommender provider wires this up at app start. Returns a list of
  /// songs to append + autoplay, or empty/null to do nothing.
  Future<List<Song>>? Function()? onQueueExhausted;

  // Expose raw streams for Riverpod providers
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;
  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;

  KaivaAudioHandler() {
    _init();
    LiveActivityService.instance.onAction = _handleLiveActivityAction;
  }

  void _handleLiveActivityAction(String action) {
    switch (action) {
      case 'play_pause':
        _player.playing ? pause() : play();
        break;
      case 'next':
        skipToNext();
        break;
      case 'previous':
        skipToPrevious();
        break;
    }
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Handle audio interruptions (phone calls, headset removal)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        pause();
      } else {
        if (event.type == AudioInterruptionType.pause) play();
      }
    });
    session.becomingNoisyEventStream.listen((_) => pause());

    // Sync just_audio state → audio_service MediaItem + playback state
    _player.sequenceStateStream.listen((state) {
      final item = state?.currentSource?.tag as MediaItem?;
      if (item != null) {
        _onTrackChanged(item);
        mediaItem.add(item);
      }
    });

    // Update Live Activity position every 5 seconds while playing
    _player.positionStream
        .where((_) => _player.playing)
        .where((pos) => pos.inSeconds % 5 == 0)
        .distinct()
        .listen((_) => _updateLiveActivity());

    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // Mark the current event as a clean completion. _onTrackChanged
        // (fired by the sequence listener when the next track starts)
        // will then emit a 'complete' event instead of a 'skip'.
        _currentEventCompleted = true;
        if (stopAfterCurrentTrack) {
          stopAfterCurrentTrack = false;
          stop();
        } else {
          skipToNext();
        }
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (_player.processingState) {
        ProcessingState.idle     => AudioProcessingState.idle,
        ProcessingState.loading  => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready    => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
    // Keep Dynamic Island play/pause indicator in sync
    _updateLiveActivity();
  }

  void _updateLiveActivity() {
    final item = mediaItem.value;
    if (item == null) return;
    final artUrl = (item.artUri?.toString() ?? '')
        .replaceAll('150x150', '500x500');
    LiveActivityService.instance.update(
      title: item.title,
      artist: item.artist ?? '',
      albumArt: artUrl,
      isPlaying: _player.playing,
      elapsedSeconds: _player.position.inSeconds.toDouble(),
      durationSeconds: _player.duration?.inSeconds.toDouble() ?? 0,
    );
  }

  // ── URL rewriting for emulator proxy ────────────────────────
  // On Android emulator, direct CDN URLs fail. Route them through the local proxy.
  // Physical device needs LAN IP; emulator uses 10.0.2.2 (set via enableProxy on emulator only)
  static const String _proxyBase = 'http://192.168.1.10:8888';
  static bool _useProxy = false;

  static void enableProxy() => _useProxy = true;

  Uri _resolveStreamUri(String rawUrl) {
    if (!_useProxy || rawUrl.startsWith('file://') || rawUrl.isEmpty) {
      return Uri.parse(rawUrl);
    }
    // Use path-based /stream/<base64url> so ExoPlayer sees a clean URL
    // and can infer media type from the path (avoids PlatformException Source error)
    final token = Uri.encodeFull(
      base64Url.encode(utf8.encode(rawUrl)),
    );
    return Uri.parse('$_proxyBase/stream/$token');
  }

  // ── Public API ───────────────────────────────────────────────

  Future<void> playSong(Song song) async {
    _resetCrossfadeState();
    final mediaItem = song.toMediaItem();
    this.mediaItem.add(mediaItem);
    queue.add([mediaItem]);
    await _player.setAudioSource(
      AudioSource.uri(
        _resolveStreamUri(song.bestStreamUrl),
        tag: mediaItem,
      ),
    );
    await play();
  }

  Future<void> playQueue(List<Song> songs, int index) async {
    _resetCrossfadeState();
    final items = songs.map((s) => s.toMediaItem()).toList();
    queue.add(items);
    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children: songs
            .map((s) => AudioSource.uri(_resolveStreamUri(s.bestStreamUrl), tag: s.toMediaItem()))
            .toList(),
      ),
      initialIndex: index,
    );
    await play();
  }

  Future<void> addToQueue(Song song) async {
    final source = _player.audioSource as ConcatenatingAudioSource?;
    final item = song.toMediaItem();
    if (source != null) {
      await source.add(AudioSource.uri(_resolveStreamUri(song.bestStreamUrl), tag: item));
      queue.add([...queue.value, item]);
    } else {
      await playSong(song);
    }
  }

  Future<void> addNext(Song song) async {
    final source = _player.audioSource as ConcatenatingAudioSource?;
    final item = song.toMediaItem();
    if (source != null) {
      final nextIndex = (_player.currentIndex ?? 0) + 1;
      await source.insert(nextIndex, AudioSource.uri(_resolveStreamUri(song.bestStreamUrl), tag: item));
      final q = [...queue.value];
      q.insert(nextIndex, item);
      queue.add(q);
    } else {
      await playSong(song);
    }
  }

  Future<void> removeFromQueue(int index) async {
    final source = _player.audioSource as ConcatenatingAudioSource?;
    if (source != null && index < source.length) {
      await source.removeAt(index);
      final q = [...queue.value]..removeAt(index);
      queue.add(q);
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    final source = _player.audioSource as ConcatenatingAudioSource?;
    if (source == null) return;
    await source.move(oldIndex, newIndex);
    final q = [...queue.value];
    final item = q.removeAt(oldIndex);
    q.insert(newIndex, item);
    queue.add(q);
  }

  // ── Stats helpers ────────────────────────────────────────────

  void _onTrackChanged(MediaItem item) {
    _flushStats();

    // Begin tracking the new item. item.id is the stream URL; the
    // canonical JioSaavn song/artist ids live in extras.
    final songId = (item.extras?['songId'] as String?) ?? item.id;
    final artistId = (item.extras?['artistId'] as String?) ?? '';
    _currentStatsId = songId;
    _currentStatsArtistId = artistId;
    _currentAlbum = item.album ?? '';
    _currentLanguage = (item.extras?['language'] as String?) ?? '';
    _currentDuration = item.duration;
    _currentEventCompleted = false;
    _trackStartTime = DateTime.now();
    _db?.recentlyPlayedDao.recordPlay(songId);

    final artUrl = (item.artUri?.toString() ?? '')
        .replaceAll('150x150', '500x500');
    LiveActivityService.instance.start(
      title: item.title,
      artist: item.artist ?? '',
      albumArt: artUrl,
      isPlaying: _player.playing,
      elapsedSeconds: 0,
      durationSeconds: _player.duration?.inSeconds.toDouble() ?? 0,
    );
  }

  void _flushStats() {
    final songId = _currentStatsId;
    final artistId = _currentStatsArtistId;
    final start = _trackStartTime;
    if (songId == null || artistId == null || start == null || _db == null) return;
    final seconds = DateTime.now().difference(start).inSeconds;

    // Always log a play-event for the recommender — even short skips are signal.
    final durationSec = _currentDuration?.inSeconds ?? 0;
    final completedFraction =
        durationSec > 0 ? seconds / durationSec : (seconds >= 30 ? 1.0 : 0.0);
    final eventType = _currentEventCompleted || completedFraction >= 0.8
        ? 'complete'
        : seconds < 10
            ? 'short_skip'
            : 'skip';
    _db!.playEventsDao.recordEvent(
      songId: songId,
      artistId: artistId,
      language: _currentLanguage ?? '',
      album: _currentAlbum ?? '',
      eventType: eventType,
      playedSeconds: seconds,
      durationSeconds: durationSec,
    );

    // Legacy aggregate stats — keep for the Stats screen.
    if (seconds >= 5) {
      _db!.statsDao.recordListening(
        songId: songId,
        artistId: artistId,
        secondsPlayed: seconds,
      );
    }

    _currentStatsId = null;
    _currentStatsArtistId = null;
    _currentLanguage = null;
    _currentAlbum = null;
    _currentDuration = null;
    _currentEventCompleted = false;
    _trackStartTime = null;
  }

  Future<void> setCrossfade(int seconds) async {
    _crossfadeSeconds = seconds;
    _positionSub?.cancel();
    _positionSub = null;
    if (seconds > 0) {
      _positionSub = _player.positionStream.listen(_onPosition);
    } else {
      _isCrossfading = false;
      await _player.setVolume(1.0);
    }
  }

  void _onPosition(Duration position) {
    final duration = _player.duration;
    if (duration == null || _crossfadeSeconds == 0) return;
    final fadeStart = duration - Duration(seconds: _crossfadeSeconds);
    if (position >= fadeStart && !_isCrossfading) {
      _startCrossfade(duration - position);
    } else if (position < fadeStart && _isCrossfading) {
      _isCrossfading = false;
      _player.setVolume(1.0);
    }
  }

  void _startCrossfade(Duration remaining) {
    _isCrossfading = true;
    _crossfadeTimer?.cancel();
    const tickInterval = Duration(milliseconds: 50);
    final totalTicks = remaining.inMilliseconds / tickInterval.inMilliseconds;
    int tick = 0;
    _crossfadeTimer = Timer.periodic(tickInterval, (t) {
      tick++;
      final vol = max(0.0, 1.0 - (tick / totalTicks));
      _player.setVolume(vol);
      if (vol <= 0.0) {
        t.cancel();
        _isCrossfading = false;
        _player.setVolume(1.0); // restore for next track
      }
    });
  }

  bool _gaplessEnabled = false;

  Future<void> setGapless(bool enabled) async {
    _gaplessEnabled = enabled;
    // On iOS, disabling automatic stall minimisation reduces inter-track silence.
    // On Android, just_audio's ConcatenatingAudioSource is always gapless at the
    // ExoPlayer layer — no additional call needed.
    await _player.setAutomaticallyWaitsToMinimizeStalling(!enabled);
  }

  // ── BaseAudioHandler overrides ───────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    _flushStats();
    await _player.stop();
    await super.stop();
    LiveActivityService.instance.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  void _resetCrossfadeState() {
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;
    _isCrossfading = false;
    _player.setVolume(1.0);
  }

  @override
  Future<void> skipToNext() async {
    _resetCrossfadeState();
    if (_player.hasNext) {
      await _player.seekToNext();
      return;
    }
    // Queue exhausted — ask the recommender for more.
    final hook = onQueueExhausted;
    if (hook == null) return;
    try {
      final more = await hook();
      if (more == null || more.isEmpty) return;
      final source = _player.audioSource;
      if (source is ConcatenatingAudioSource) {
        await source.addAll(
          more
              .map((s) => AudioSource.uri(
                    _resolveStreamUri(s.bestStreamUrl),
                    tag: s.toMediaItem(),
                  ))
              .toList(),
        );
        queue.add([...queue.value, ...more.map((s) => s.toMediaItem())]);
        await _player.seekToNext();
      } else {
        // No active queue — start a fresh one.
        await playQueue(more, 0);
      }
    } catch (_) {
      // Recommender failed — just stop.
    }
  }

  @override
  Future<void> skipToPrevious() async {
    _resetCrossfadeState();
    // If more than 3s in, restart track; else go to previous
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    _resetCrossfadeState();
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    await _player.setShuffleModeEnabled(enabled);
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode = switch (repeatMode) {
      AudioServiceRepeatMode.none  => LoopMode.off,
      AudioServiceRepeatMode.one   => LoopMode.one,
      AudioServiceRepeatMode.all   => LoopMode.all,
      AudioServiceRepeatMode.group => LoopMode.all,
    };
    await _player.setLoopMode(loopMode);
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> onTaskRemoved() => stop();

  // Skip forward/backward 10 seconds
  Future<void> seekRelative(Duration offset) {
    final newPos = _player.position + offset;
    final clamped = newPos.isNegative ? Duration.zero : newPos;
    return _player.seek(clamped);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'seekForward10':
        await seekRelative(const Duration(seconds: 10));
      case 'seekBackward10':
        await seekRelative(const Duration(seconds: -10));
    }
  }

  void dispose() {
    _flushStats();
    _crossfadeTimer?.cancel();
    _positionSub?.cancel();
    _player.dispose();
  }
}

// Combined position + duration stream for seek bar
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;

  const PositionData(this.position, this.bufferedPosition, this.duration);
}

Stream<PositionData> positionDataStream(AudioPlayer player) =>
    Rx.combineLatest3(
      player.positionStream,
      player.bufferedPositionStream,
      player.durationStream,
      (position, buffered, duration) => PositionData(position, buffered, duration),
    );
