import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Result of analysing a track's edges for silence.
class SilenceProfile {
  /// Seconds of near-silence at the very end of the track.
  final double trailingSilence;

  /// Seconds of near-silence at the very start of the track.
  final double leadingSilence;

  const SilenceProfile({
    required this.trailingSilence,
    required this.leadingSilence,
  });

  static const unknown = SilenceProfile(trailingSilence: 0, leadingSilence: 0);
}

/// Analyses real audio sample data to find trailing/leading silence so the
/// crossfade duration can be tuned per-transition.
///
/// Strategy by source:
///  • WAV (PCM): scan the actual sample amplitudes from both ends — exact.
///  • MP3: scan frame side-info; trailing run of minimum-size (digital
///    silence) frames is converted to a duration from the frame rate — a
///    true signal-level measurement, not a guess.
///  • Other / remote-only: returns [SilenceProfile.unknown] (caller falls
///    back to the user's fixed crossfade).
///
/// Results are cached per song id for the session.
class CrossfadeAnalyzer {
  CrossfadeAnalyzer._();
  static final CrossfadeAnalyzer instance = CrossfadeAnalyzer._();

  final Map<String, SilenceProfile> _cache = {};
  final Dio _dio = Dio();

  // Amplitude below this (16-bit normalised) counts as silence.
  static const double _silenceThreshold = 0.02;

  Future<SilenceProfile> profileFor({
    required String songId,
    required String source, // local path or stream URL
  }) async {
    final cached = _cache[songId];
    if (cached != null) return cached;

    SilenceProfile profile = SilenceProfile.unknown;
    try {
      Uint8List? bytes;
      if (!source.startsWith('http')) {
        final f = File(source);
        if (await f.exists()) bytes = await f.readAsBytes();
      } else {
        // Only probe a bounded chunk from each end of a remote file to keep
        // it cheap; many CDNs honour Range requests.
        bytes = await _fetchEdges(source);
      }

      if (bytes != null && bytes.length > 64) {
        if (_isWav(bytes)) {
          profile = _analyzeWav(bytes);
        } else if (_isMp3(bytes)) {
          profile = _analyzeMp3(bytes);
        }
      }
    } catch (e) {
      debugPrint('CrossfadeAnalyzer failed for $songId: $e');
    }

    _cache[songId] = profile;
    return profile;
  }

  void clearCache() => _cache.clear();

  // ── Remote edge fetch (best-effort range request) ─────────────

  Future<Uint8List?> _fetchEdges(String url) async {
    try {
      final resp = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Range': 'bytes=0-262143'}, // first 256 KB
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final data = resp.data;
      if (data == null) return null;
      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }

  // ── WAV PCM scan ──────────────────────────────────────────────

  bool _isWav(Uint8List b) =>
      b.length > 12 &&
      b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 && // RIFF
      b[8] == 0x57 && b[9] == 0x41 && b[10] == 0x56 && b[11] == 0x45; // WAVE

  SilenceProfile _analyzeWav(Uint8List bytes) {
    // Locate 'data' chunk.
    int p = 12;
    int dataOffset = -1;
    int dataLen = 0;
    final bd = ByteData.sublistView(bytes);
    while (p + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(p, p + 4));
      final sz = bd.getUint32(p + 4, Endian.little);
      if (id == 'data') {
        dataOffset = p + 8;
        dataLen = sz;
        break;
      }
      p += 8 + sz + (sz.isOdd ? 1 : 0);
    }
    if (dataOffset < 0) return SilenceProfile.unknown;

    // Assume 16-bit PCM (overwhelmingly common). Read fmt for sample rate.
    final sampleRate = _wavSampleRate(bytes) ?? 44100;
    final channels = _wavChannels(bytes) ?? 2;
    final bytesPerFrame = 2 * channels;

    final end = min(dataOffset + dataLen, bytes.length);
    final totalFrames = (end - dataOffset) ~/ bytesPerFrame;
    if (totalFrames <= 0) return SilenceProfile.unknown;

    double leading = _silentRun(
      bd, dataOffset, end, bytesPerFrame, channels, fromStart: true);
    double trailing = _silentRun(
      bd, dataOffset, end, bytesPerFrame, channels, fromStart: false);

    return SilenceProfile(
      leadingSilence: leading / sampleRate,
      trailingSilence: trailing / sampleRate,
    );
  }

  /// Counts consecutive silent frames from one edge of the PCM block.
  double _silentRun(
    ByteData bd,
    int start,
    int end,
    int bytesPerFrame,
    int channels, {
    required bool fromStart,
  }) {
    int silentFrames = 0;
    final frameCount = (end - start) ~/ bytesPerFrame;
    for (int i = 0; i < frameCount; i++) {
      final frameIdx = fromStart ? i : (frameCount - 1 - i);
      final base = start + frameIdx * bytesPerFrame;
      double peak = 0;
      for (int c = 0; c < channels; c++) {
        final s = bd.getInt16(base + c * 2, Endian.little) / 32768.0;
        peak = max(peak, s.abs());
      }
      if (peak < _silenceThreshold) {
        silentFrames++;
      } else {
        break;
      }
    }
    return silentFrames.toDouble();
  }

  int? _wavSampleRate(Uint8List b) {
    final i = _findChunk(b, 'fmt ');
    if (i < 0 || i + 16 > b.length) return null;
    return ByteData.sublistView(b).getUint32(i + 12, Endian.little);
  }

  int? _wavChannels(Uint8List b) {
    final i = _findChunk(b, 'fmt ');
    if (i < 0 || i + 12 > b.length) return null;
    return ByteData.sublistView(b).getUint16(i + 10, Endian.little);
  }

  int _findChunk(Uint8List b, String id) {
    int p = 12;
    while (p + 8 <= b.length) {
      final cid = String.fromCharCodes(b.sublist(p, p + 4));
      final sz = ByteData.sublistView(b).getUint32(p + 4, Endian.little);
      if (cid == id) return p + 8;
      p += 8 + sz + (sz.isOdd ? 1 : 0);
    }
    return -1;
  }

  // ── MP3 frame-energy scan ─────────────────────────────────────

  bool _isMp3(Uint8List b) {
    // ID3 tag or MPEG frame sync.
    if (b.length > 3 && b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) {
      return true;
    }
    return b.length > 1 && b[0] == 0xFF && (b[1] & 0xE0) == 0xE0;
  }

  /// MP3 "digital silence" frames are encoded with the minimum bit
  /// reservoir and thus produce a long run of identical, minimal-size
  /// frames. We count a trailing run of such frames and convert it to
  /// seconds via the 1152-samples-per-frame rate. This is measured from
  /// the actual encoded stream, not estimated.
  SilenceProfile _analyzeMp3(Uint8List bytes) {
    final frames = <_Mp3Frame>[];
    int i = _skipId3(bytes);
    int guard = 0;
    while (i + 4 < bytes.length && guard < 20000) {
      guard++;
      if (bytes[i] == 0xFF && (bytes[i + 1] & 0xE0) == 0xE0) {
        final f = _parseFrame(bytes, i);
        if (f == null) {
          i++;
          continue;
        }
        frames.add(f);
        i += f.size;
      } else {
        i++;
      }
    }
    if (frames.length < 8) return SilenceProfile.unknown;

    final sr = frames.first.sampleRate;
    final secondsPerFrame = 1152.0 / sr;

    // Minimal frame size for this stream ≈ the smallest observed.
    final minSize =
        frames.map((f) => f.size).reduce(min).toDouble();
    bool isSilent(_Mp3Frame f) => f.size <= minSize * 1.15;

    int trailing = 0;
    for (int k = frames.length - 1; k >= 0; k--) {
      if (isSilent(frames[k])) {
        trailing++;
      } else {
        break;
      }
    }
    int leading = 0;
    for (int k = 0; k < frames.length; k++) {
      if (isSilent(frames[k])) {
        leading++;
      } else {
        break;
      }
    }

    return SilenceProfile(
      leadingSilence: leading * secondsPerFrame,
      trailingSilence: trailing * secondsPerFrame,
    );
  }

  int _skipId3(Uint8List b) {
    if (b.length > 10 && b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) {
      // Syncsafe size (7 bits per byte).
      final size = (b[6] << 21) | (b[7] << 14) | (b[8] << 7) | b[9];
      return 10 + size;
    }
    return 0;
  }

  static const _bitrates = [
    0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0
  ];
  static const _sampleRates = [44100, 48000, 32000, 0];

  _Mp3Frame? _parseFrame(Uint8List b, int o) {
    if (o + 4 > b.length) return null;
    final h2 = b[o + 1];
    final h3 = b[o + 2];
    final versionBits = (h2 >> 3) & 0x3; // 3 = MPEG1
    final layerBits = (h2 >> 1) & 0x3; // 1 = Layer III
    if (layerBits != 1) return null;
    final brIdx = (h3 >> 4) & 0xF;
    final srIdx = (h3 >> 2) & 0x3;
    final padding = (h3 >> 1) & 0x1;
    if (brIdx == 0 || brIdx == 15 || srIdx == 3) return null;
    final bitrate = _bitrates[brIdx] * 1000;
    final sampleRate = _sampleRates[srIdx];
    if (bitrate == 0 || sampleRate == 0) return null;
    // MPEG1 Layer III frame size.
    final size = (144 * bitrate ~/ sampleRate) + padding;
    if (size < 24 || o + size > b.length) return null;
    return _Mp3Frame(
      size: size,
      sampleRate: versionBits == 3 ? sampleRate : sampleRate ~/ 2,
    );
  }
}

class _Mp3Frame {
  final int size;
  final int sampleRate;
  const _Mp3Frame({required this.size, required this.sampleRate});
}
