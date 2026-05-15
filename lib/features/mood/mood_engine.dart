import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../core/ai/ai_config.dart';
import '../../core/ai/nvidia_client.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/database/kaiva_database.dart' hide Song;
import '../../core/models/song.dart';
import '../../core/utils/settings_keys.dart';

/// The result of a mood-detection pass: a human label, a short blurb,
/// and the songs to queue.
class MoodMix {
  final String mood;
  final String description;
  final List<Song> songs;
  final bool aiPowered;

  const MoodMix({
    required this.mood,
    required this.description,
    required this.songs,
    required this.aiPowered,
  });
}

/// Builds a mood-based auto-queue.
///
/// Strategy:
///  1. Gather context (time of day, weekday, recent listening, top artists,
///     language preference).
///  2. If an NVIDIA key is present + online, ask the LLM for a mood label
///     and 4–6 JioSaavn search seeds.
///  3. Otherwise fall back to a fully on-device heuristic.
///  4. Resolve seeds → songs via JioSaavn search, dedupe, shuffle lightly.
class MoodEngine {
  MoodEngine(this._db);

  final KaivaDatabase _db;

  Future<MoodMix> buildMix() async {
    final ctx = await _gatherContext();

    // Try AI first
    if (AiConfig.hasNvidiaKey) {
      final ai = await _askAi(ctx);
      if (ai != null && ai.songs.isNotEmpty) return ai;
    }

    // Heuristic fallback
    return _heuristicMix(ctx);
  }

  // ── Context ───────────────────────────────────────────────────

  Future<_MoodContext> _gatherContext() async {
    final now = DateTime.now();
    final hour = now.hour;
    final partOfDay = switch (hour) {
      >= 5 && < 12 => 'morning',
      >= 12 && < 17 => 'afternoon',
      >= 17 && < 21 => 'evening',
      _ => 'night',
    };
    final weekday = now.weekday >= 6 ? 'weekend' : 'weekday';

    final box = Hive.box('kaiva_settings');
    final language =
        box.get(SettingsKeys.selectedLanguage, defaultValue: 'hindi') as String;

    List<String> recentArtists = const [];
    try {
      final recent = await _db.recentlyPlayedDao
          .watchRecentlyPlayed(limit: 15)
          .first;
      recentArtists = recent
          .map((s) => s.artist)
          .where((a) => a.isNotEmpty)
          .toSet()
          .take(8)
          .toList();
    } catch (_) {}

    return _MoodContext(
      partOfDay: partOfDay,
      weekday: weekday,
      language: language,
      recentArtists: recentArtists,
    );
  }

  // ── AI path ───────────────────────────────────────────────────

  Future<MoodMix?> _askAi(_MoodContext ctx) async {
    const system =
        'You are a music mood curator for an Indian music streaming app. '
        'Given a listening context, infer the most fitting mood and produce '
        'search queries that work on a JioSaavn-style catalogue. '
        'Respond ONLY with strict minified JSON, no prose, no markdown. '
        'Schema: {"mood":"<2-3 word label>","description":"<one warm sentence>",'
        '"queries":["q1","q2","q3","q4","q5"]}. '
        'Queries should be short and use the listener\'s language where natural.';

    final user = jsonEncode({
      'part_of_day': ctx.partOfDay,
      'day_type': ctx.weekday,
      'preferred_language': ctx.language,
      'recent_artists': ctx.recentArtists,
    });

    final raw = await NvidiaClient.instance.chat(
      systemPrompt: system,
      userPrompt: user,
      temperature: 0.7,
      maxTokens: 400,
    );
    if (raw == null) return null;

    try {
      final jsonStr = _extractJson(raw);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final mood = (map['mood'] as String?)?.trim() ?? 'Your Vibe';
      final desc = (map['description'] as String?)?.trim() ??
          'A mix picked for this moment.';
      final queries = ((map['queries'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .take(6)
          .toList();
      if (queries.isEmpty) return null;

      final songs = await _resolveQueries(queries);
      if (songs.isEmpty) return null;

      return MoodMix(
        mood: mood,
        description: desc,
        songs: songs,
        aiPowered: true,
      );
    } catch (e) {
      debugPrint('MoodEngine AI parse failed: $e');
      return null;
    }
  }

  /// LLMs sometimes wrap JSON in ```json fences or add stray text.
  String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start >= 0 && end > start) return raw.substring(start, end + 1);
    return raw;
  }

  // ── Heuristic path ────────────────────────────────────────────

  Future<MoodMix> _heuristicMix(_MoodContext ctx) async {
    final (mood, desc, seeds) = switch (ctx.partOfDay) {
      'morning' => (
          'Morning Calm',
          'Easy songs to ease into the day.',
          ['morning chill ${ctx.language}', 'soft acoustic ${ctx.language}', 'feel good ${ctx.language}'],
        ),
      'afternoon' => (
          'Afternoon Drive',
          'Upbeat tracks to keep the momentum.',
          ['upbeat ${ctx.language}', 'top hits ${ctx.language} 2025', 'energetic ${ctx.language}'],
        ),
      'evening' => (
          'Evening Unwind',
          'Mellow vibes for winding down.',
          ['evening melodies ${ctx.language}', 'romantic ${ctx.language}', 'lofi ${ctx.language}'],
        ),
      _ => (
          'Late Night',
          'Quiet songs for the small hours.',
          ['late night ${ctx.language}', 'slow ${ctx.language}', 'soulful ${ctx.language}'],
        ),
    };

    final songs = await _resolveQueries(seeds);
    return MoodMix(
      mood: mood,
      description: desc,
      songs: songs,
      aiPowered: false,
    );
  }

  // ── Shared: resolve search seeds → songs ──────────────────────

  Future<List<Song>> _resolveQueries(List<String> queries) async {
    final api = ApiClient.instance();
    final seen = <String>{};
    final out = <Song>[];

    Future<dynamic> safe(Future<dynamic> f) => f.catchError((_) => null);

    final responses = await Future.wait(
      queries.map((q) => safe(api.get(
            ApiEndpoints.searchSongs,
            params: {'query': q, 'limit': '8'},
          ))),
    );

    for (final resp in responses) {
      if (resp == null) continue;
      final data = (resp.data as Map<String, dynamic>?)?['data'];
      final results =
          ((data as Map<String, dynamic>?)?['results'] as List<dynamic>?) ??
              const [];
      for (final r in results) {
        try {
          final song = Song.fromJson(r as Map<String, dynamic>);
          if (song.id.isEmpty || !seen.add(song.id)) continue;
          if (song.bestStreamUrl.isEmpty) continue;
          out.add(song);
        } catch (_) {}
      }
    }

    out.shuffle();
    return out.take(40).toList();
  }
}

class _MoodContext {
  final String partOfDay;
  final String weekday;
  final String language;
  final List<String> recentArtists;

  const _MoodContext({
    required this.partOfDay,
    required this.weekday,
    required this.language,
    required this.recentArtists,
  });
}
