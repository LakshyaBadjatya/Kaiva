import 'package:flutter/foundation.dart';
import '../../core/ai/ai_config.dart';

/// What a recognition attempt produced.
class RecognitionResult {
  final bool matched;
  final String? title;
  final String? artist;
  final String? album;
  final String? message; // shown when no match / error

  const RecognitionResult.match({
    required this.title,
    required this.artist,
    this.album,
  })  : matched = true,
        message = null;

  const RecognitionResult.noMatch([this.message = 'No match found'])
      : matched = false,
        title = null,
        artist = null,
        album = null;
}

/// Pluggable audio-fingerprint recognizer.
///
/// The full capture → recognize → result pipeline is built. Recognition
/// itself needs a fingerprinting backend (JioSaavn cannot do this). Drop
/// an ACRCloud or AudD.io key into [AiConfig] and implement the call in
/// [_recognizeWithBackend] to enable real Shazam-style matching.
abstract class SongRecognitionService {
  factory SongRecognitionService() => _DefaultRecognitionService();

  /// [audioFilePath] is a short recorded clip (~8s).
  Future<RecognitionResult> recognize(String audioFilePath);

  bool get isConfigured;
}

class _DefaultRecognitionService implements SongRecognitionService {
  @override
  bool get isConfigured => AiConfig.hasSongRecognitionKey;

  @override
  Future<RecognitionResult> recognize(String audioFilePath) async {
    if (!isConfigured) {
      // Stub mode — pipeline works, recognition key not set.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return const RecognitionResult.noMatch(
        'Recognition isn\'t set up yet. Add an ACRCloud or AudD key '
        'in AiConfig to enable song identification.',
      );
    }
    return _recognizeWithBackend(audioFilePath);
  }

  // TODO: plug ACRCloud / AudD.io here.
  // ACRCloud: build the signed multipart request to
  // https://<host>/v1/identify with the recorded sample bytes,
  // parse `metadata.music[0]` → title/artists/album.
  Future<RecognitionResult> _recognizeWithBackend(String audioFilePath) async {
    try {
      // Intentionally unimplemented until a key + host are provided.
      return const RecognitionResult.noMatch(
        'Recognition backend not implemented.',
      );
    } catch (e) {
      debugPrint('Recognition failed: $e');
      return const RecognitionResult.noMatch('Recognition failed.');
    }
  }
}
