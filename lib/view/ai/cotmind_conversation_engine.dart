import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cotmade/view/ai/cotmind_services.dart';
import 'dart:math';

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
  String? type;
  List<String> amenities = [];
  bool awaitingLocation = false;
  bool awaitingAmenities = false;
  bool hasGreeted = false;
  List<String> conversationHistory = [];

  void reset() {
    intent = Intent.unknown;
    city = null;
    country = null;
    type = null;
    amenities = [];
    awaitingLocation = false;
    awaitingAmenities = false;
    hasGreeted = false;
    conversationHistory.clear();
  }
}

class CotmindResponse {
  final String message;
  final List<String> videos;
  final bool typewriter;

  CotmindResponse({
    required this.message,
    this.videos = const [],
    this.typewriter = false,
  });
}

class CotmindConversationEngine {
  static final ConversationState _state = ConversationState();

  static Future<CotmindResponse> respond(String input, {String? uid}) async {
    final text = input.trim();
    final lower = text.toLowerCase();

    _state.conversationHistory.add("User: $text");

    if (lower.contains("reset") || lower.contains("start over")) {
      _state.reset();
      return CotmindResponse(
        message:
            "✅ Conversation reset. What destination or vibe are you interested in?",
        typewriter: true,
      );
    }

    if (!_state.hasGreeted) {
      _state.hasGreeted = true;
      return CotmindResponse(
        message:
            "Hey there! 👋 I'm Cotmind, your travel buddy. Where are you thinking of going, or what kind of vibe do you want?",
        typewriter: true,
      );
    }

    if (_isSmallTalk(lower)) {
      final reply = _getRandomSmallTalkReply();
      _state.conversationHistory.add("Bot: $reply");
      return CotmindResponse(message: reply, typewriter: true);
    }

    final mood = _detectMood(lower);
    if (mood == 'positive') {
      return CotmindResponse(
        message: "Love that energy! 😄 Got a dream spot in mind?",
        typewriter: true,
      );
    } else if (mood == 'negative') {
      return CotmindResponse(
        message:
            "Let’s plan something uplifting 💫 Where do you want to escape to?",
        typewriter: true,
      );
    }

    if (_state.awaitingLocation) {
      _state.city = text;
      _state.awaitingLocation = false;
      _state.intent = Intent.searchLocation;
    }

    if (_state.awaitingAmenities) {
      _state.amenities = _extractAmenities(text);
      _state.awaitingAmenities = false;
      _state.intent = Intent.searchAmenities;
    }

    if (_state.intent == Intent.unknown) {
      if (lower.contains("more") || lower.contains("again")) {
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

      default:
        return CotmindResponse(
          message: _getFallbackResponse(),
          typewriter: true,
        );
    }
  }

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

  static Future<CotmindResponse> _handleSearchLocation(String text) async {
    final normalizedCity = await CotmindService.normalizeCity(text);
    final normalizedCountry = await CotmindService.normalizeCountry(text);
    final hasCity = normalizedCity != text.toLowerCase();
    final hasCountry = normalizedCountry != text.toLowerCase();

    if (!hasCity && !hasCountry) {
      _state.awaitingLocation = true;
      return CotmindResponse(
        message:
            "I didn’t catch the city or country name. Could you tell me where you’d like to go?\n${_suggestSampleDestinations()}",
        typewriter: true,
      );
    }

    _state.city = hasCity ? normalizedCity : null;
    _state.country = hasCountry && !hasCity ? normalizedCountry : null;
    _state.intent = Intent.unknown;

    final loc = _state.city ?? _state.country!;
    final isCity = _state.city != null;
    return _fetchPostingsAndVideos(loc, isCity, _getRandomSearchIntro(loc));
  }

  static Future<CotmindResponse> _handleSearchAmenities(
      String text, String? uid) async {
    final ams = _extractAmenities(text);
    if (ams.isEmpty) {
      _state.awaitingAmenities = true;
      return CotmindResponse(
        message:
            "What kind of features are you looking for? (e.g., pool, wifi, breakfast, spa)",
        typewriter: true,
      );
    }
    _state.amenities = ams;
    _state.intent = Intent.unknown;

    if (_state.city == null && _state.country == null) {
      _state.awaitingLocation = true;
      return CotmindResponse(
        message:
            "Awesome! Amenities noted: ${ams.join(", ")}. Where should I search?",
        typewriter: true,
      );
    }

    final loc = _state.city ?? _state.country!;
    final isCity = _state.city != null;
    return _fetchPostingsAndVideos(
        loc, isCity, "Search results in $loc with ${ams.join(", ")} 👇",
        filterAmenities: ams, uid: uid);
  }

  static Future<CotmindResponse> _fetchPostingsAndVideos(
      String loc, bool isCity, String prefix,
      {List<String>? filterAmenities, String? uid}) async {
    var query = FirebaseFirestore.instance
        .collection('postings')
        .where(isCity ? 'city' : 'country', isEqualTo: loc);

    if (filterAmenities != null) {
      for (var a in filterAmenities) {
        query = query.where('amenities', arrayContains: a);
      }
    }

    if (_state.type != null) {
      query = query.where('type', isEqualTo: _state.type);
    }

    final snaps = await query.get();
    if (snaps.docs.isEmpty) {
      return CotmindResponse(
        message:
            "Hmm, I found no listings in $loc. Want to try another place or change filters like 'luxury' or 'family'?",
        typewriter: true,
      );
    }

    final ids = snaps.docs.map((d) => d.id).toList();
    final reelSnap = await FirebaseFirestore.instance
        .collection('reels')
        .where('postingId', whereIn: ids)
        .orderBy('time', descending: true)
        .limit(2)
        .get();

    final videos = reelSnap.docs
        .map((d) => (d.data() as Map)['reelsVideo'] as String?)
        .whereType<String>()
        .toList();

    final vibeScore = await CotmindService.getSentiment(loc, isCity: isCity);
    final vibe = _getVibeFromScore(vibeScore);
    final tip = await CotmindService.getTip(loc, isCity: isCity);

    final filters = <String>[
      if (_state.type != null) _state.type!,
      if (filterAmenities?.isNotEmpty ?? false) ...filterAmenities!,
    ];
    final filterSummary = filters.isNotEmpty ? ' (${filters.join(', ')})' : '';

    final msg =
        "$prefix\n📍 $loc$filterSummary — vibe: *$vibe*\nTip: $tip\n\n${videos.isEmpty ? 'No videos available yet.' : 'Watch these 👇'}";

    return CotmindResponse(message: msg, videos: videos, typewriter: true);
  }

  static List<String> _extractAmenities(String input) {
    final known = [
      'pool',
      'wifi',
      'beach',
      'breakfast',
      'family',
      'luxury',
      'spa',
      'gym',
      'bar',
      'parking',
      'pet-friendly',
      'air conditioning',
      'balcony',
      'fireplace'
    ];
    return known
        .where((k) => levenshtein(input, k) <= 2 || input.contains(k))
        .toList();
  }

  static bool _hasPlaceMention(String input) {
    final places = [
      'lagos',
      'nigeria',
      'paris',
      'france',
      'bali',
      'barcelona',
      'cape town'
    ];
    return places.any((p) => levenshtein(input, p) <= 2 || input.contains(p));
  }

  static bool _isSmallTalk(String input) {
    final smallTalk = ['hi', 'hello', 'thanks', 'how are you', 'what\'s up'];
    return smallTalk.any((s) => input.contains(s));
  }

  static String _getRandomSmallTalkReply() {
    final replies = [
      "Hey hey! 😊",
      "Hi there! 🌍 Planning a trip?",
      "Always happy to chat! Where are we headed?",
      "Just dreaming of sunny beaches ☀️ You?",
      "Cotmind here at your service 🧳",
      "What’s the vibe today — beach, city, or nature? 🌊🏙️🌲",
      _getDynamicGreeting()
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _getDynamicGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    if (hour < 12) return "Good morning! 🌅 Ready to explore somewhere new?";
    if (hour < 18) return "Good afternoon! ☀️ Any destination in mind?";
    return "Good evening! 🌙 Let’s find your next adventure.";
  }

  static String _detectMood(String input) {
    final positive = [
      'happy',
      'excited',
      'yay',
      'great',
      'awesome',
      'fun',
      'joy'
    ];
    final negative = ['sad', 'tired', 'bored', 'lonely', 'stressed', 'anxious'];
    if (positive.any((w) => input.contains(w))) return 'positive';
    if (negative.any((w) => input.contains(w))) return 'negative';
    return 'neutral';
  }

  static String _getVibeFromScore(double s) => s > 1.2
      ? 'energetic'
      : s < 0.8
          ? 'calm'
          : 'balanced';

  static String _getRandomSearchIntro(String loc) {
    final phrases = [
      "Let’s explore some cool spots in $loc 🔍",
      "Here’s what I found in $loc 👇",
      "Check out these places in $loc 🎥",
      "$loc looks like a great choice! Here's what I found 👇"
    ];
    return phrases[Random().nextInt(phrases.length)];
  }

  static String _suggestSampleDestinations() {
    final samples = [
      'Lagos 🇳🇬',
      'Bali 🇮🇩',
      'Barcelona 🇪🇸',
      'Paris 🇫🇷',
      'Cape Town 🇿🇦'
    ];
    return "Need ideas? How about: ${samples.join(", ")}?";
  }

  static String _getFallbackResponse() {
    final replies = [
      "Could you tell me a bit more? Are you looking for a city, a vibe, or something fun to do?",
      "Hmm, I’m not sure I caught that. Are you planning a trip or just exploring?",
      "Want me to surprise you with a trending destination? 🎯",
      "Not sure what that means... Maybe name a place you’d love to visit?",
      "I didn’t quite get that. Could you rephrase or give me a hint like 'beach', 'mountains', or 'Europe'?",
    ];
    return replies[Random().nextInt(replies.length)];
  }
}
