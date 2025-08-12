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
        min(
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + (s[i - 1] == t[j - 1] ? 0 : 1),
        ),
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

    // Reset conversation
    if (lower.contains("reset") || lower.contains("start over")) {
      _state.reset();
      return CotmindResponse(
        message:
            "✅ Conversation reset. What destination or vibe are you interested in?",
        typewriter: true,
      );
    }

    // Greet once
    if (!_state.hasGreeted) {
      _state.hasGreeted = true;
      return CotmindResponse(
        message:
            "Hey there! 👋 I'm Cotmind, your travel buddy. Dreaming of a beach, city, or mountain escape? Where to?",
        typewriter: true,
      );
    }

    // Small talk handling
    if (_isSmallTalk(lower)) {
      final reply = _getRandomSmallTalkReply();
      _state.conversationHistory.add("Bot: $reply");
      return CotmindResponse(message: reply, typewriter: true);
    }

    // Mood detection for positive/negative sentiment
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

    // Handle awaiting inputs first
    if (_state.awaitingLocation) {
      _state.city = text;
      _state.country = null; // reset country if user specifies city now
      _state.awaitingLocation = false;
      _state.intent = Intent.searchLocation;
    } else if (_state.awaitingAmenities) {
      final ams = _extractAmenities(text);
      if (ams.isEmpty) {
        // Still no amenities, ask again
        return CotmindResponse(
          message:
              "Sorry, I still didn't catch any features. Examples: pool, wifi, breakfast, spa.",
          typewriter: true,
        );
      }
      _state.amenities = ams;
      _state.awaitingAmenities = false;
      _state.intent = Intent.searchAmenities;
    }

    // Infer type keywords like 'luxury', 'family', etc.
    final typeKeywords = ['luxury', 'budget', 'family', 'romantic'];
    final detectedType = typeKeywords.firstWhere(
      (t) => lower.contains(t),
      orElse: () => '',
    );
    if (detectedType.isNotEmpty) {
      _state.type = detectedType;
    }

    // If intent unknown, try to infer it from input
    if (_state.intent == Intent.unknown) {
      await _inferIntentFromInput(lower);
    }

    // Now handle intents
    switch (_state.intent) {
      case Intent.askMore:
        _state.intent = Intent.unknown; // reset for next
        return _handleAskMore();

      case Intent.searchLocation:
        _state.intent = Intent.unknown;
        return _handleSearchLocation(text);

      case Intent.searchAmenities:
        _state.intent = Intent.unknown;
        return _handleSearchAmenities(text, uid);

      default:
        print(
            "⚠️ Fallback triggered. State: intent=${_state.intent}, city=${_state.city}, country=${_state.country}, amenities=${_state.amenities}");
        return CotmindResponse(
          message: _getFallbackResponse(),
          typewriter: true,
        );
    }
  }

  static Future<void> _inferIntentFromInput(String text) async {
    final amenities = _extractAmenities(text);
    final city = await CotmindService.normalizeCity(text);
    final country = await CotmindService.normalizeCountry(text);
    final hasPlace = (city != null && city.isNotEmpty) ||
        (country != null && country.isNotEmpty);

    if (text.contains("more") || text.contains("again")) {
      _state.intent = Intent.askMore;
      return;
    }

    if (hasPlace) {
      _state.city = city;
      _state.country = country;
    }

    if (amenities.isNotEmpty) {
      _state.amenities = amenities;
    }

    if (hasPlace && amenities.isNotEmpty) {
      _state.intent = Intent.searchAmenities;
    } else if (hasPlace) {
      _state.intent = Intent.searchLocation;
    } else if (amenities.isNotEmpty) {
      _state.intent = Intent.searchAmenities;
      _state.awaitingLocation = true;
    }
  }

  static Future<CotmindResponse> _handleAskMore() async {
    if (_state.city != null || _state.country != null) {
      final loc = _state.city ?? _state.country!;
      final isCity = _state.city != null;
      return _fetchPostingsAndVideos(
        loc,
        isCity,
        "Here are more videos for $loc 👇",
      );
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
    final hasCity = normalizedCity != null && normalizedCity.isNotEmpty;
    final hasCountry =
        normalizedCountry != null && normalizedCountry.isNotEmpty;

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
    Query query = FirebaseFirestore.instance
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

    String msg = "$prefix\n📍 $loc$filterSummary — vibe: *$vibe*\nTip: $tip";

    if (videos.isEmpty) {
      final listingsSummary = snaps.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Accommodation';
            final description = data['description'] ?? 'No description';
            final price = data['price'] != null
                ? "\$${data['price']}"
                : "Price on request";
            return "• *$title* — $description ($price)";
          })
          .take(3)
          .join("\n");

      msg +=
          "\n\nNo videos found, but here are some listings:\n$listingsSummary";
    } else {
      msg += "\n\nWatch these 👇";
    }

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
    final tokens = input.toLowerCase().split(RegExp(r'\W+'));
    return known.where((k) => tokens.contains(k.toLowerCase())).toList();
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
    if (hour < 12) return "Good morning! Ready to explore?";
    if (hour < 18) return "Good afternoon! Where to next?";
    return "Good evening! Dreaming of a getaway?";
  }

  static String _detectMood(String input) {
    final positiveWords = [
      'great',
      'awesome',
      'love',
      'happy',
      'fantastic',
      'nice'
    ];
    final negativeWords = ['bad', 'sad', 'hate', 'tired', 'bored', 'upset'];
    if (positiveWords.any((w) => input.contains(w))) return 'positive';
    if (negativeWords.any((w) => input.contains(w))) return 'negative';
    return 'neutral';
  }

  static String _getFallbackResponse() {
    if (_state.awaitingLocation) {
      return "Could you tell me which city or country you're interested in?";
    } else if (_state.awaitingAmenities) {
      return "What kind of features are you looking for? (e.g., pool, wifi, breakfast)";
    }

    final suggestions = [
      "Could you tell me more? Are you looking for a beach, city escape, or mountain getaway?",
      "I’m not quite sure what you mean. Try something like 'luxury spots in Paris' or 'places with wifi in Lagos'.",
      "Need help deciding? Just say 'surprise me' or name any place!",
    ];
    return suggestions[Random().nextInt(suggestions.length)];
  }

  static String _suggestSampleDestinations() {
    final samples = [
      "Try typing: 'Paris', 'Bali', or 'Kenya'.",
      "Try: 'New York', 'Tokyo', or 'Maldives'.",
      "For example: 'Santorini', 'Sydney', or 'Cape Town'."
    ];
    return samples[Random().nextInt(samples.length)];
  }

  static String _getRandomSearchIntro(String location) {
    final intros = [
      "Searching the best stays in $location 👇",
      "Here’s what I found in $location 👇",
      "Top picks around $location 👇",
      "Your travel guide for $location 👇",
      "Check out these spots in $location 👇"
    ];
    return intros[Random().nextInt(intros.length)];
  }

  static String _getVibeFromScore(double score) {
    if (score > 0.5) return "energetic";
    if (score > 0.2) return "positive";
    if (score > 0) return "neutral";
    return "calm";
  }
}
