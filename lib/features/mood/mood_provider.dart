import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import 'mood_engine.dart';

final moodEngineProvider = Provider<MoodEngine>((ref) {
  return MoodEngine(ref.watch(databaseProvider));
});

/// Async mood-mix builder. Use `ref.refresh(moodMixProvider.future)` to
/// rebuild on demand (e.g. when the user taps "Mood Mix").
final moodMixProvider = FutureProvider.autoDispose<MoodMix>((ref) async {
  final engine = ref.watch(moodEngineProvider);
  return engine.buildMix();
});
