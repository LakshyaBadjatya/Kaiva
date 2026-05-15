import 'package:hive/hive.dart';
import '../database/daos/play_events_dao.dart';
// The Drift-generated Song row class lives in kaiva_database.dart. We hide
// it so callers of TasteProfile can still use the model Song without
// ambiguity. Internally we only need its `id` field.
import '../database/kaiva_database.dart' hide Song;
import '../database/kaiva_database.dart' as drift show Song;
import '../utils/settings_keys.dart';

/// Compact, in-memory snapshot of the user's listening taste at a moment
/// in time. Derived from PlayEventsDao + LikedSongsDao + onboarding Hive
/// box. The Recommender uses this to score candidate songs.
class TasteProfile {
  /// Map<artistId, affinity in [0,1]> — higher means we should prefer them.
  final Map<String, double> artistAffinity;

  /// Map<language, weight in [0,1]> — normalised so the top language is 1.0.
  final Map<String, double> languageWeights;

  /// Map<hourOfDay (0-23), weight in [0,1]>. Used to softly bias toward
  /// languages the user listens to at this time of day.
  final Map<int, double> hourWeights;

  /// Songs the user has explicitly liked (always boosted).
  final Set<String> likedSongIds;

  /// Recently-seen song IDs to avoid in recommendations.
  final Set<String> recentSongIds;

  /// Song IDs the user has skipped — soft negative signal.
  final Set<String> skippedSongIds;

  /// Songs the user has completed 2+ times — best recommendation seeds.
  final List<String> seedSongIds;

  /// Onboarding language picks — cold-start fallback.
  final List<String> onboardingLanguages;

  /// Onboarding artist IDs — cold-start fallback.
  final List<String> onboardingArtistIds;

  /// Total number of real play events — controls cold-start vs warm scoring.
  final int totalPlays;

  /// True when we don't have enough data to score meaningfully.
  bool get isColdStart => totalPlays < 5;

  const TasteProfile({
    required this.artistAffinity,
    required this.languageWeights,
    required this.hourWeights,
    required this.likedSongIds,
    required this.recentSongIds,
    required this.skippedSongIds,
    required this.seedSongIds,
    required this.onboardingLanguages,
    required this.onboardingArtistIds,
    required this.totalPlays,
  });

  /// Build a fresh profile from the local database.
  static Future<TasteProfile> build(KaivaDatabase db) async {
    final dao = db.playEventsDao;

    final results = await Future.wait([
      dao.totalPlays(),
      dao.topArtists(limit: 25),
      dao.topLanguages(limit: 8),
      dao.hourDistribution(),
      dao.recentSongIds(days: 14),
      dao.skippedSongIds(),
      dao.topSeedSongs(limit: 10),
      db.likedSongsDao.watchLikedSongs().first,
    ]);

    final totalPlays = results[0] as int;
    final artists = results[1] as List<ArtistAffinity>;
    final languages = results[2] as List<LanguageAffinity>;
    final hours = results[3] as List<HourAffinity>;
    final recent = results[4] as Set<String>;
    final skipped = results[5] as Set<String>;
    final seeds = results[6] as List<String>;
    final liked = (results[7] as List<drift.Song>).map((s) => s.id).toSet();

    // Normalise language weights so top language == 1.0.
    final maxLang =
        languages.isEmpty ? 1 : languages.first.completes.clamp(1, 1 << 30);
    final langWeights = <String, double>{};
    for (final l in languages) {
      langWeights[l.language] = l.completes / maxLang;
    }

    // Hour weights normalised to top hour == 1.0; smooth with +1 prior.
    final maxHour = hours.isEmpty ? 1 : hours.map((h) => h.plays).reduce((a, b) => a > b ? a : b);
    final hourWeights = <int, double>{
      for (final h in hours) h.hour: (h.plays + 1) / (maxHour + 1),
    };

    final artistAff = <String, double>{
      for (final a in artists) a.artistId: a.affinity,
    };

    // Cold-start fallback from onboarding Hive box.
    final box = Hive.box('kaiva_settings');
    final onboardLangs = (box.get(SettingsKeys.onboardingLanguages, defaultValue: <String>[]) as List)
        .cast<String>();
    final onboardArtists = (box.get(SettingsKeys.onboardingArtists, defaultValue: <String>[]) as List)
        .cast<String>();

    return TasteProfile(
      artistAffinity: artistAff,
      languageWeights: langWeights,
      hourWeights: hourWeights,
      likedSongIds: liked,
      recentSongIds: recent,
      skippedSongIds: skipped,
      seedSongIds: seeds,
      onboardingLanguages: onboardLangs,
      onboardingArtistIds: onboardArtists,
      totalPlays: totalPlays,
    );
  }

  /// Pick the languages the recommender should weight most heavily right now.
  /// Falls back to onboarding picks during cold-start.
  List<String> get topLanguages {
    if (isColdStart && onboardingLanguages.isNotEmpty) {
      return onboardingLanguages;
    }
    final sorted = languageWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(4).map((e) => e.key).toList();
  }

  /// Top-affinity artists, again falling back to onboarding picks.
  List<String> get topArtistIds {
    if (isColdStart && onboardingArtistIds.isNotEmpty) {
      return onboardingArtistIds;
    }
    final sorted = artistAffinity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).map((e) => e.key).toList();
  }
}
