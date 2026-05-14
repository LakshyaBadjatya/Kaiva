import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Controls iOS Live Activities / Dynamic Island for the now-playing track.
/// All calls are no-ops on Android and in debug builds on unsupported devices.
class LiveActivityService {
  static const _channel = MethodChannel('com.lakshya.kaiva/live_activity');

  static LiveActivityService? _instance;
  static LiveActivityService get instance =>
      _instance ??= LiveActivityService._();
  LiveActivityService._();

  bool _supported = false;
  bool _checked = false;

  Future<bool> get isSupported async {
    if (!Platform.isIOS) return false;
    if (_checked) return _supported;
    try {
      _supported = await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      _supported = false;
    }
    _checked = true;
    return _supported;
  }

  Future<void> start({
    required String title,
    required String artist,
    required String albumArt,
    required bool isPlaying,
    required double elapsedSeconds,
    required double durationSeconds,
  }) async {
    if (!await isSupported) return;
    try {
      await _channel.invokeMethod('start', {
        'title': title,
        'artist': artist,
        'albumArt': albumArt,
        'isPlaying': isPlaying,
        'elapsedSeconds': elapsedSeconds,
        'durationSeconds': durationSeconds,
      });
    } catch (e) {
      debugPrint('[LiveActivity] start failed: $e');
    }
  }

  Future<void> update({
    required String title,
    required String artist,
    required String albumArt,
    required bool isPlaying,
    required double elapsedSeconds,
    required double durationSeconds,
  }) async {
    if (!await isSupported) return;
    try {
      await _channel.invokeMethod('update', {
        'title': title,
        'artist': artist,
        'albumArt': albumArt,
        'isPlaying': isPlaying,
        'elapsedSeconds': elapsedSeconds,
        'durationSeconds': durationSeconds,
      });
    } catch (e) {
      debugPrint('[LiveActivity] update failed: $e');
    }
  }

  Future<void> stop() async {
    if (!await isSupported) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      debugPrint('[LiveActivity] stop failed: $e');
    }
  }
}
