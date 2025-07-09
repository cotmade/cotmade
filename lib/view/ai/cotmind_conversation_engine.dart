import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cotmade/view/ai/cotmind_services.dart';
import 'package:collection/collection.dart';
import 'dart:math';

// Simple Levenshtein distance for fuzzy matching
int levenshtein(String s, String t) {
  final m = s.length, n = t.length;
  if (m == 0) return n;
  if (n == 0) return m;
  List<List<int>> dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (int i = 0; i <= m; i++) dp[i][0] = i;
  for (int j = 0; j <= n; j++) dp[0][j] = j;
  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      dp[i][j] = min(
        dp[i - 1][j] + 1,
        min(dp[i][j - 1] + 1,
            dp[i - 1][j - 1] + (s[i - 1] == t[j - 1] ? 0 : 1)),
      );
    }
  }
  return dp[m][n];
}

enum Intent { askMore, searchLocation, searchAmenities, reset, unknown }

class ConversationState {
  Intent intent = Intent.unknown;
  String? city;
  String? country;
  List<String> amenities = [];
  bool awaitingLocation = false;
  bool awaitingAmenities = false;

  void reset() {
    intent = Intent.unknown;
    city = null;
    country = null;
    amenities = [];
    awaitingLocation = false;
    awaitingAmenities = false;
  }
}

class CotmindResponse {
  final String message;
  final List<String> videos;
  final bool typewriter;

  CotmindResponse(
      {required this.message, this.videos = const [], this.typewriter = false});
}

class CotmindConversationEngine {
  static final ConversationState _state = ConversationState();

  static Future<CotmindResponse> respond(String input, {String? uid}) async {
    final text = input.trim();
    final lower = text.toLowerCase();

    // Reset?
    if (lower.contains("reset") || lower.contains("start over")) {
      _state.reset();
      return CotmindResponse(
        message:
            "✅ Conversation reset. What destination or vibe are you interested in?",
        typewriter: true,
      );
    }

    // If awaiting location slot:
    if (_state.awaitingLocation) {
      _state.city = text;
      _state.awaitingLocation = false;
      // Hand off to full search
      _state.intent = Intent.searchLocation;
    }

    // If awaiting amenities:
    if (_state.awaitingAmenities) {
      _state.amenities = _extractAmenities(text);
      _state.awaitingAmenities = false;
      _state.intent = Intent.searchAmenities;
    }

    // Determine intent if not slot-filling
    if (_state.intent == Intent.unknown) {
      if (lower.contains("more") ||
          lower.contains("tell me") ||
          lower.contains("again")) {
        _state.intent = Intent.askMore;
      } else if (_hasPlaceMention(lower)) {
        _state.intent = Intent.searchLocation;
      } else if (_extractAmenities(lower).isNotEmpty) {
        _state.intent = Intent.searchAmenities;
      }
    }

    switch (_state.intent) {
      case Intent.askMore:
        _state.intent = Intent.unknown;
        return _handleAskMore();

      case Intent.searchLocation:
        return _handleSearchLocation(text);

      case Intent.searchAmenities:
        return _handleSearchAmenities(text, uid);

      case Intent.reset:
        // already handled above
        break;

      default:
        return CotmindResponse(
          message: _getDynamicGreeting(),
          typewriter: true,
        );
    }

    return CotmindResponse(message: "Hmm, I'm not sure!", typewriter: true);
  }

  // Handle "tell me more"
  static Future<CotmindResponse> _handleAskMore() async {
    if (_state.city != null || _state.country != null) {
      final loc = _state.city ?? _state.country!;
      final isCity = _state.city != null;
      return _fetchPostingsAndVideos(
          loc, isCity, "Here are more videos for $loc 👇");
    } else {
      return CotmindResponse(
        message: "Which place would you like more videos of?",
        typewriter: true,
      );
    }
  }

  // Location search
  static Future<CotmindResponse> _handleSearchLocation(String text) async {
    final normalizedCity = await CotmindService.normalizeCity(text);
    final normalizedCountry = await CotmindService.normalizeCountry(text);
    final hasCity = normalizedCity != text.toLowerCase();
    final hasCountry = normalizedCountry != text.toLowerCase();

    if (!hasCity && !hasCountry) {
      // Fuzzy prompt for missing place
      _state.awaitingLocation = true;
      return CotmindResponse(
        message:
            "I didn't catch the city or country name. Could you specify which destination?",
        typewriter: true,
      );
    }

    _state.city = hasCity ? normalizedCity : null;
    _state.country = hasCountry && !hasCity ? normalizedCountry : null;
    _state.intent = Intent.unknown;

    final loc = _state.city ?? _state.country!;
    final isCity = _state.city != null;
    return _fetchPostingsAndVideos(
        loc, isCity, "Here are video options for $loc 👇");
  }

  // Amenity search
  static Future<CotmindResponse> _handleSearchAmenities(
      String text, String? uid) async {
    final ams = _extractAmenities(text);
    if (ams.isEmpty) {
      _state.awaitingAmenities = true;
      return CotmindResponse(
        message:
            "What features are you looking for? (e.g. pool, wifi, breakfast)",
        typewriter: true,
      );
    }
    _state.amenities = ams;
    _state.intent = Intent.unknown;

    if (_state.city == null && _state.country == null) {
      _state.awaitingLocation = true;
      return CotmindResponse(
        message:
            "Great! Amenities noted: ${ams.join(", ")}. Which city or country should I search?",
        typewriter: true,
      );
    }

    final loc = _state.city ?? _state.country!;
    final isCity = _state.city != null;
    return _fetchPostingsAndVideos(
        loc, isCity, "Search results in $loc with ${ams.join(", ")} 👇",
        filterAmenities: ams, uid: uid);
  }

  // Core function to get postings & videos
  static Future<CotmindResponse> _fetchPostingsAndVideos(
      String loc, bool isCity, String prefix,
      {List<String>? filterAmenities, String? uid}) async {
    // fetch postings
    var query = FirebaseFirestore.instance
        .collection('postings')
        .where(isCity ? 'city' : 'country', isEqualTo: loc);
    if (filterAmenities != null) {
      for (var a in filterAmenities) {
        query = query.where('amenities', arrayContains: a);
      }
    }
    final snaps = await query.get();
    if (snaps.docs.isEmpty) {
      return CotmindResponse(
          message: "No listings found for $loc.", typewriter: true);
    }
    final ids = snaps.docs.map((d) => d.id).toList();

    final reelSnap = await FirebaseFirestore.instance
        .collection('reels')
        .where('postingId', whereIn: ids)
        .orderBy('time', descending: true)
        .limit(2)
        .get();
    final videos =
        reelSnap.docs.map((d) => (d.data() as Map)['url'] as String).toList();

    // personal profile ranking
    if (uid != null) {
      final profile = await CotmindService.getUserTasteProfile(uid);
      // You could reorder 'snaps' based on profile here
    }

    final vibeScore = await CotmindService.getSentiment(loc, isCity: isCity);
    final vibe = _getVibeFromScore(vibeScore);
    final tip = await CotmindService.getTip(loc, isCity: isCity);

    final message =
        "$prefix\n📍 $loc — vibe: *$vibe*\nTip: $tip\n\n${videos.isEmpty ? 'No videos available.' : 'Watch these 👇'}";
    return CotmindResponse(message: message, videos: videos, typewriter: true);
  }

  static List<String> _extractAmenities(String input) {
    final known = ['pool', 'wifi', 'beach', 'breakfast', 'family', 'luxury'];
    return known
        .where((k) => levenshtein(input, k) <= 2 || input.contains(k))
        .toList();
  }

  static bool _hasPlaceMention(String input) {
    // fuzzy match against a small list
    final places = ['lagos', 'nigeria', 'paris', 'france'];
    return places.any((p) => levenshtein(input, p) <= 2 || input.contains(p));
  }

  static String _getVibeFromScore(double s) => s > 1.2
      ? 'energetic'
      : s < 0.8
          ? 'calm'
          : 'balanced';

  static String _getDynamicGreeting() {
    final h = DateTime.now().hour;
    final g = h < 12
        ? 'Good morning'
        : h < 18
            ? 'Good afternoon'
            : 'Good evening';
    return "$g! 👋 What kind of trip are you planning today?";
  }
}
