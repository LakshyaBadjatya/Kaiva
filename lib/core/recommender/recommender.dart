import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/song.dart';
import 'taste_profile.dart';

/// On-device content-based recommender.
///
/// Strategy:
///   1. Generate a candidate pool from JioSaavn's /api/songs/{id}/suggestions
///      using the user's seed songs (top completions) + top artists.
///   2. Score each candidate by weighted signals from the [TasteProfile].
///   3. De-duplicate, filter out recently-played, sort by score descending,
///      and return the top N.
///
/// Stateless service — instantiate freely. Each `recommend()` call hits the
/// API in parallel for all seeds.
class Recommender {
  final ApiClient _api;
  final Random _rng;

  Recommender({ApiClient? api, Random? rng})
      : _api = api ?? ApiClient.instance(),
        _rng = rng ?? Random();

  /// Returns up to [limit] recommended songs ordered by score.
  /// [excludeIds] lets callers skip songs already shown elsewhere on Home.
  Future<List<Song>> recommend({
    required TasteProfile profile,
    int limit = 20,
    Set<String> excludeIds = const {},
  }) async {
    debugPrint('[Recommender] start: totalPlays=${profile.totalPlays} '
        'seeds=${profile.seedSongIds.length} '
        'topArtists=${profile.topArtistIds.length} '
        'topLanguages=${profile.topLanguages.join(",")} '
        'onboardLangs=${profile.onboardingLanguages.join(",")} '
        'onboardArtists=${profile.onboardingArtistIds.length}');
    final candidates = await _gatherCandidates(profile);
    debugPrint('[Recommender] gathered ${candidates.length} candidates');
    if (candidates.isEmpty) return const [];

    final exclude = {
      ...excludeIds,
      ...profile.recentSongIds,
    };

    final hour = DateTime.now().hour;
    final scored = <_Scored>[];
    final seen = <String>{};
    for (final song in candidates) {
      if (song.id.isEmpty || seen.contains(song.id)) continue;
      if (exclude.contains(song.id)) continue;
      seen.add(song.id);
      scored.add(_Scored(song, _score(song, profile, hour)));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    // Light shuffle within the top half so the same user doesn't see the
    // exact same order on every refresh.
    final top = scored.take(limit * 2).toList();
    _diversify(top);
    final result = top.take(limit).map((s) => s.song).toList();
    debugPrint('[Recommender] returning ${result.length} songs');
    return result;
  }

  // ── Candidate generation ────────────────────────────────────

  Future<List<Song>> _gatherCandidates(TasteProfile profile) async {
    // 1. Seed songs (top completions) — strongest signal.
    final seeds = <String>{...profile.seedSongIds};

    // 2. Top liked songs — also great seeds.
    seeds.addAll(profile.likedSongIds.take(5));

    final calls = <Future<List<Song>>>[];

    // Direct /suggestions calls per seed song.
    for (final id in seeds.take(8)) {
      calls.add(_fetchSuggestions(id));
    }

    // Cold-start or seed-poor: search-based fallback so we always have
    // *something* to recommend. Uses top artists / onboarding artists +
    // top languages / onboarding languages.
    if (seeds.length < 3) {
      final artists = profile.topArtistIds;
      for (final aid in artists.take(4)) {
        calls.add(_fetchArtistTopSongs(aid));
      }
      for (final lang in profile.topLanguages.take(2)) {
        calls.add(_fetchLanguageHits(lang));
      }
    }

    // True cold-start with no onboarding signals at all: pull a generic
    // trending pool so the "For You" section is never empty. The scoring
    // step will still order them sensibly even with no taste profile.
    if (calls.isEmpty) {
      calls.add(_fetchLanguageHits('top hits 2025'));
      calls.add(_fetchLanguageHits('hindi'));
    }

    if (calls.isEmpty) return const [];

    final results = await Future.wait(calls.map((c) => c.catchError((_) => <Song>[])));
    return results.expand((x) => x).toList();
  }

  Future<List<Song>> _fetchSuggestions(String songId) async {
    final res = await _api.get(ApiEndpoints.songSuggestions(songId), params: {'limit': '12'});
    return _parseSongs(_extractList(res.data));
  }

  Future<List<Song>> _fetchArtistTopSongs(String artistId) async {
    final res = await _api.get(ApiEndpoints.artistSongs(artistId), params: {'limit': '12'});
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return _parseSongs(data['songs']);
      }
    }
    return const [];
  }

  Future<List<Song>> _fetchLanguageHits(String language) async {
    final res = await _api.get(
      ApiEndpoints.searchSongs,
      params: {'query': '$language top hits 2025', 'limit': '15'},
    );
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return _parseSongs(data['results']);
      }
    }
    return const [];
  }

  // Defensive JSON extraction — JioSaavn returns slightly different shapes
  // across endpoints.
  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final inner = data['results'] ?? data['songs'] ?? data;
        if (inner is List) return inner;
      }
    }
    return const [];
  }

  List<Song> _parseSongs(dynamic raw) {
    final list = (raw as List<dynamic>?) ?? const [];
    return list
        .map((e) {
          try {
            return Song.fromJson(e as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Song>()
        .toList();
  }

  // ── Scoring ────────────────────────────────────────────────

  double _score(Song song, TasteProfile profile, int hour) {
    // Base score lives in [0, ~3.0] before randomness; the components
    // below contribute independently and are weighted experimentally.
    var score = 0.5; // baseline so cold-start candidates aren't all 0

    // Liked songs always float to the top.
    if (profile.likedSongIds.contains(song.id)) score += 1.0;

    // Skipped — strong negative.
    if (profile.skippedSongIds.contains(song.id)) score -= 1.5;

    // Artist affinity (Bayesian-smoothed in [0,1]).
    final aff = profile.artistAffinity[song.artistId];
    if (aff != null) {
      // Scale so a 1.0 affinity adds 1.0, 0.5 affinity adds 0.0, 0.0 adds -0.5.
      score += (aff - 0.5) * 2.0;
    } else if (profile.isColdStart &&
        profile.onboardingArtistIds.contains(song.artistId)) {
      // Onboarding artists get a fixed boost during cold-start.
      score += 0.8;
    }

    // Language match.
    final lw = profile.languageWeights[song.language];
    if (lw != null) {
      score += lw * 0.6;
    } else if (profile.isColdStart &&
        profile.onboardingLanguages.contains(song.language)) {
      score += 0.6;
    } else if (song.language.isNotEmpty &&
        profile.languageWeights.isNotEmpty &&
        !profile.languageWeights.containsKey(song.language)) {
      // Unknown language — small penalty so we don't drift away from user's
      // preferred languages once the profile is warm.
      score -= 0.15;
    }

    // Time-of-day bonus — songs by artists the user listens to at this hour
    // get a small lift. (Approximation: use the user's overall hour weight.)
    final hw = profile.hourWeights[hour];
    if (hw != null && hw > 0.5) score += 0.2 * hw;

    // Tiny jitter so identical-score songs don't pin to the same slot.
    score += _rng.nextDouble() * 0.05;

    return score;
  }

  // Light artist-diversification: prevent the top-10 from being 6 songs by
  // the same artist. Walks the sorted list and demotes a song if 2 songs by
  // the same artist already appeared above it.
  void _diversify(List<_Scored> scored) {
    final perArtist = <String, int>{};
    final demoted = <_Scored>[];
    final kept = <_Scored>[];
    for (final s in scored) {
      final count = perArtist[s.song.artistId] ?? 0;
      if (count >= 2 && s.song.artistId.isNotEmpty) {
        demoted.add(s);
      } else {
        kept.add(s);
        perArtist[s.song.artistId] = count + 1;
      }
    }
    scored
      ..clear()
      ..addAll(kept)
      ..addAll(demoted);
  }
}

class _Scored {
  final Song song;
  final double score;
  _Scored(this.song, this.score);
}
