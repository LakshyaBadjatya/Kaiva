import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import '../models/song.dart';
import 'recommender.dart';
import 'taste_profile.dart';

/// Shared Recommender instance.
final recommenderProvider = Provider<Recommender>((ref) => Recommender());

/// Cached taste profile — rebuilt when [refreshTasteProfile] is invalidated.
/// `keepAlive` because building it touches several DB queries.
final tasteProfileProvider = FutureProvider<TasteProfile>((ref) async {
  ref.keepAlive();
  final db = ref.watch(databaseProvider);
  return TasteProfile.build(db);
});

/// The "For You" feed — top-ranked recommendations.
///
/// Two-key family: [excludeKey] lets the Home screen pass a stable
/// excludeIds set (e.g. ids visible in Spotlight/Trending sections) so we
/// don't duplicate. Pass an empty set for empty-queue autoplay.
final forYouProvider = FutureProvider.family<List<Song>, ForYouArgs>((ref, args) async {
  debugPrint('[forYou] provider running, limit=${args.limit} '
      'exclude=${args.excludeIds.length}');
  try {
    final profile = await ref.watch(tasteProfileProvider.future);
    final rec = ref.read(recommenderProvider);
    final out = await rec.recommend(
      profile: profile,
      limit: args.limit,
      excludeIds: args.excludeIds,
    );
    debugPrint('[forYou] done, ${out.length} songs');
    return out;
  } catch (e, st) {
    debugPrint('[forYou] error: $e\n$st');
    rethrow;
  }
});

/// Convenience: invalidate this to force re-recompute after a song completes.
void refreshForYou(WidgetRef ref) {
  ref.invalidate(tasteProfileProvider);
  ref.invalidate(forYouProvider);
}

class ForYouArgs {
  final int limit;
  final Set<String> excludeIds;
  const ForYouArgs({this.limit = 20, this.excludeIds = const {}});

  @override
  bool operator ==(Object other) =>
      other is ForYouArgs &&
      other.limit == limit &&
      _setEq(other.excludeIds, excludeIds);

  @override
  int get hashCode => Object.hash(limit, Object.hashAllUnordered(excludeIds));

  static bool _setEq(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
