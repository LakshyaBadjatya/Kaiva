import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/utils/settings_keys.dart';
import '../../core/firebase/firebase_service.dart';

// ── Onboarding completion gate ────────────────────────────────
final onboardingCompleteProvider = StateProvider<bool>((ref) {
  return Hive.box('kaiva_settings')
      .get(SettingsKeys.onboardingComplete, defaultValue: false) as bool;
});

// ── Selected languages ────────────────────────────────────────
final selectedLanguagesProvider =
    StateNotifierProvider<SelectedLanguagesNotifier, List<String>>(
        (ref) => SelectedLanguagesNotifier());

class SelectedLanguagesNotifier extends StateNotifier<List<String>> {
  SelectedLanguagesNotifier() : super([]);

  void toggle(String lang) {
    if (state.contains(lang)) {
      state = state.where((l) => l != lang).toList();
    } else {
      state = [...state, lang];
    }
  }

  bool isSelected(String lang) => state.contains(lang);
}

// ── Selected artists ──────────────────────────────────────────
final selectedArtistsProvider =
    StateNotifierProvider<SelectedArtistsNotifier, List<String>>(
        (ref) => SelectedArtistsNotifier());

class SelectedArtistsNotifier extends StateNotifier<List<String>> {
  SelectedArtistsNotifier() : super([]);

  void toggle(String artistId) {
    if (state.contains(artistId)) {
      state = state.where((a) => a != artistId).toList();
    } else {
      state = [...state, artistId];
    }
  }

  bool isSelected(String artistId) => state.contains(artistId);
}

// ── Persist and finish onboarding ────────────────────────────
Future<void> completeOnboarding({
  required List<String> languages,
  required List<String> artistIds,
}) async {
  final box = Hive.box('kaiva_settings');
  await box.put(SettingsKeys.onboardingComplete, true);
  await box.put(SettingsKeys.onboardingLanguages, languages);
  await box.put(SettingsKeys.onboardingArtists, artistIds);

  // Primary language drives home feed
  if (languages.isNotEmpty) {
    await box.put(SettingsKeys.selectedLanguage, _toApiLang(languages.first));
  }

  // Push to Firestore if signed in
  if (FirebaseService.instance.isSignedIn) {
    await FirebaseService.instance.pushSettings({
      'onboardingLanguages': languages,
      'onboardingArtists': artistIds,
      'selectedLanguage': languages.isNotEmpty ? _toApiLang(languages.first) : 'hindi',
    });
  }
}

String _toApiLang(String displayLang) {
  const map = {
    'Hindi': 'hindi',
    'English': 'english',
    'Punjabi': 'punjabi',
    'Tamil': 'tamil',
    'Telugu': 'telugu',
    'Kannada': 'kannada',
    'Malayalam': 'malayalam',
    'Bengali': 'bengali',
    'Marathi': 'marathi',
    'Gujarati': 'gujarati',
    'Bhojpuri': 'bhojpuri',
    'Rajasthani': 'rajasthani',
    'Odia': 'odia',
    'Assamese': 'assamese',
    'Urdu': 'urdu',
    'Spanish': 'spanish',
    'Korean': 'korean',
    'Punjabi (Pakistani)': 'punjabi',
  };
  return map[displayLang] ?? displayLang.toLowerCase();
}

// ── Language catalogue ────────────────────────────────────────
class LanguageEntry {
  final String name;
  final String emoji;
  final bool isIndian;

  const LanguageEntry(this.name, this.emoji, {this.isIndian = true});
}

const kOnboardingLanguages = [
  LanguageEntry('Hindi',               '🇮🇳', isIndian: true),
  LanguageEntry('Punjabi',             '🥁', isIndian: true),
  LanguageEntry('Tamil',               '🎵', isIndian: true),
  LanguageEntry('Telugu',              '🎶', isIndian: true),
  LanguageEntry('Kannada',             '🪘', isIndian: true),
  LanguageEntry('Malayalam',           '🌴', isIndian: true),
  LanguageEntry('Bengali',             '🎸', isIndian: true),
  LanguageEntry('Marathi',             '🎺', isIndian: true),
  LanguageEntry('Gujarati',            '🪗', isIndian: true),
  LanguageEntry('Bhojpuri',            '🥳', isIndian: true),
  LanguageEntry('Rajasthani',          '🏜️', isIndian: true),
  LanguageEntry('Odia',                '🌊', isIndian: true),
  LanguageEntry('Assamese',            '🌿', isIndian: true),
  LanguageEntry('Urdu',                '🌙', isIndian: true),
  LanguageEntry('English',             '🎤', isIndian: false),
  LanguageEntry('Spanish',             '💃', isIndian: false),
  LanguageEntry('Korean',              '🎧', isIndian: false),
];

// ── Artist catalogue ──────────────────────────────────────────
class ArtistEntry {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> languages;

  const ArtistEntry({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.languages,
  });
}

const kOnboardingArtists = [
  // Hindi
  ArtistEntry(id: 'arijit-singh',     name: 'Arijit Singh',     imageUrl: 'https://c.saavncdn.com/artists/Arijit_Singh_500x500.jpg',     languages: ['Hindi', 'Bengali']),
  ArtistEntry(id: 'shreya-ghoshal',   name: 'Shreya Ghoshal',   imageUrl: 'https://c.saavncdn.com/artists/Shreya_Ghoshal_500x500.jpg',   languages: ['Hindi', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Bengali', 'Marathi', 'Gujarati']),
  ArtistEntry(id: 'atif-aslam',       name: 'Atif Aslam',       imageUrl: 'https://c.saavncdn.com/artists/Atif_Aslam_500x500.jpg',       languages: ['Hindi', 'Urdu']),
  ArtistEntry(id: 'jubin-nautiyal',   name: 'Jubin Nautiyal',   imageUrl: 'https://c.saavncdn.com/artists/Jubin_Nautiyal_500x500.jpg',   languages: ['Hindi']),
  ArtistEntry(id: 'armaan-malik',     name: 'Armaan Malik',     imageUrl: 'https://c.saavncdn.com/artists/Armaan_Malik_500x500.jpg',     languages: ['Hindi', 'English']),
  ArtistEntry(id: 'neha-kakkar',      name: 'Neha Kakkar',      imageUrl: 'https://c.saavncdn.com/artists/Neha_Kakkar_500x500.jpg',      languages: ['Hindi', 'Punjabi']),
  ArtistEntry(id: 'sonu-nigam',       name: 'Sonu Nigam',       imageUrl: 'https://c.saavncdn.com/artists/Sonu_Nigam_500x500.jpg',       languages: ['Hindi', 'Kannada', 'Tamil', 'Telugu']),
  ArtistEntry(id: 'kumar-sanu',       name: 'Kumar Sanu',       imageUrl: 'https://c.saavncdn.com/artists/Kumar_Sanu_500x500.jpg',       languages: ['Hindi', 'Bengali']),

  // Punjabi
  ArtistEntry(id: 'diljit-dosanjh',   name: 'Diljit Dosanjh',   imageUrl: 'https://c.saavncdn.com/artists/Diljit_Dosanjh_500x500.jpg',   languages: ['Punjabi', 'Hindi']),
  ArtistEntry(id: 'ap-dhillon',       name: 'AP Dhillon',       imageUrl: 'https://c.saavncdn.com/artists/AP_Dhillon_500x500.jpg',       languages: ['Punjabi', 'English']),
  ArtistEntry(id: 'sidhu-moosewala',  name: 'Sidhu Moosewala',  imageUrl: 'https://c.saavncdn.com/artists/Sidhu_Moosewala_500x500.jpg',  languages: ['Punjabi']),
  ArtistEntry(id: 'babbu-maan',       name: 'Babbu Maan',       imageUrl: 'https://c.saavncdn.com/artists/Babbu_Maan_500x500.jpg',       languages: ['Punjabi']),
  ArtistEntry(id: 'guru-randhawa',    name: 'Guru Randhawa',    imageUrl: 'https://c.saavncdn.com/artists/Guru_Randhawa_500x500.jpg',    languages: ['Punjabi', 'Hindi']),

  // Tamil
  ArtistEntry(id: 'anirudh',          name: 'Anirudh Ravichander', imageUrl: 'https://c.saavncdn.com/artists/Anirudh_Ravichander_500x500.jpg', languages: ['Tamil']),
  ArtistEntry(id: 'sid-sriram',       name: 'Sid Sriram',       imageUrl: 'https://c.saavncdn.com/artists/Sid_Sriram_500x500.jpg',       languages: ['Tamil', 'Telugu']),
  ArtistEntry(id: 'haricharan',       name: 'Haricharan',       imageUrl: 'https://c.saavncdn.com/artists/Haricharan_500x500.jpg',       languages: ['Tamil', 'Telugu']),
  ArtistEntry(id: 'sunitha',          name: 'Sunitha',          imageUrl: 'https://c.saavncdn.com/artists/Sunitha_500x500.jpg',          languages: ['Telugu', 'Tamil']),

  // Telugu
  ArtistEntry(id: 'sp-balasubrahmanyam', name: 'S.P. Balasubrahmanyam', imageUrl: 'https://c.saavncdn.com/artists/SP_Balasubrahmanyam_500x500.jpg', languages: ['Telugu', 'Tamil', 'Kannada', 'Hindi', 'Malayalam']),
  ArtistEntry(id: 'armaan-malik-telugu', name: 'Yazin Nizar',   imageUrl: 'https://c.saavncdn.com/artists/Yazin_Nizar_500x500.jpg',      languages: ['Malayalam', 'Tamil']),

  // Kannada
  ArtistEntry(id: 'rajesh-krishnan',  name: 'Rajesh Krishnan',  imageUrl: 'https://c.saavncdn.com/artists/Rajesh_Krishnan_500x500.jpg',  languages: ['Kannada', 'Tamil', 'Telugu']),

  // Malayalam
  ArtistEntry(id: 'kj-yesudas',       name: 'K.J. Yesudas',    imageUrl: 'https://c.saavncdn.com/artists/KJ_Yesudas_500x500.jpg',       languages: ['Malayalam', 'Tamil', 'Telugu', 'Hindi', 'Kannada']),

  // Bengali
  ArtistEntry(id: 'usha-uthup',       name: 'Usha Uthup',       imageUrl: 'https://c.saavncdn.com/artists/Usha_Uthup_500x500.jpg',       languages: ['Bengali', 'Hindi']),

  // English / International
  ArtistEntry(id: 'the-weeknd',       name: 'The Weeknd',       imageUrl: 'https://c.saavncdn.com/artists/The_Weeknd_500x500.jpg',       languages: ['English']),
  ArtistEntry(id: 'taylor-swift',     name: 'Taylor Swift',     imageUrl: 'https://c.saavncdn.com/artists/Taylor_Swift_500x500.jpg',     languages: ['English']),
  ArtistEntry(id: 'ed-sheeran',       name: 'Ed Sheeran',       imageUrl: 'https://c.saavncdn.com/artists/Ed_Sheeran_500x500.jpg',       languages: ['English']),
  ArtistEntry(id: 'billie-eilish',    name: 'Billie Eilish',    imageUrl: 'https://c.saavncdn.com/artists/Billie_Eilish_500x500.jpg',    languages: ['English']),
  ArtistEntry(id: 'bts',              name: 'BTS',              imageUrl: 'https://c.saavncdn.com/artists/BTS_500x500.jpg',              languages: ['Korean']),
];

/// Artists sorted so selected-language artists appear first, English last.
List<ArtistEntry> sortedArtistsFor(List<String> selectedLanguages) {
  if (selectedLanguages.isEmpty) return kOnboardingArtists;

  final primary   = <ArtistEntry>[];
  final secondary = <ArtistEntry>[];
  final english   = <ArtistEntry>[];
  final rest      = <ArtistEntry>[];

  for (final a in kOnboardingArtists) {
    final matchesPrimary = a.languages.any((l) => selectedLanguages.contains(l));
    final isEnglishOnly  = a.languages.every((l) => l == 'English' || l == 'Korean' || l == 'Spanish');
    if (matchesPrimary) {
      primary.add(a);
    } else if (isEnglishOnly) {
      english.add(a);
    } else {
      secondary.add(a);
    }
  }

  return [...primary, ...secondary, ...english, ...rest];
}
