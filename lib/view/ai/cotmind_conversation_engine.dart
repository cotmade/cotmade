import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cotmade/view/ai/cotmind_services.dart';

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
  static String? _lastCity;
  static String? _lastCountry;
  static List<String> _lastTags = [];

  static Future<CotmindResponse> respond(String input, {String? uid}) async {
    final lowerInput = input.toLowerCase();
    final tone = CotmindService.detectTone(input);
    final tags = _extractTags(input);

    if (lowerInput.contains("reset") || lowerInput.contains("start over")) {
      _lastCity = null;
      _lastCountry = null;
      _lastTags = [];
      return CotmindResponse(
        message: "Alright, starting fresh! What vibe are you feeling today?",
        typewriter: true,
      );
    }

    if (lowerInput.contains("more") ||
        lowerInput.contains("tell me") ||
        lowerInput.contains("what else") ||
        lowerInput.contains("again")) {
      if (_lastCity != null || _lastCountry != null) {
        final loc = _lastCity ?? _lastCountry!;
        final isCity = _lastCity != null;

        final tip = await CotmindService.getTip(loc, isCity: isCity);
        final vibeScore =
            await CotmindService.getSentiment(loc, isCity: isCity);
        final vibe = _getVibeFromScore(vibeScore);

        final postingsSnap = await FirebaseFirestore.instance
            .collection('postings')
            .where(isCity ? 'city' : 'country', isEqualTo: loc)
            .get();

        List<String> postingIds = postingsSnap.docs.map((d) => d.id).toList();
        final reelsSnap = await FirebaseFirestore.instance
            .collection('reels')
            .where('postingId', whereIn: postingIds)
            .orderBy('time', descending: true)
            .limit(2)
            .get();

        final videos = reelsSnap.docs
            .map((d) => (d.data() as Map<String, dynamic>)['url'] as String)
            .toList();

        final message =
            "${isCity ? "📍" : "🌍"} *$loc*\nTip: $tip\nVibe: *$vibe*\n\n"
            "${videos.isEmpty ? "No more videos for this place right now." : "Watch more 👇"}";

        return CotmindResponse(
          message: message,
          videos: videos,
          typewriter: true,
        );
      }
    }

    final normalizedCity = await CotmindService.normalizeCity(input);
    final normalizedCountry = await CotmindService.normalizeCountry(input);
    final hasCity = normalizedCity != input;
    final hasCountry = normalizedCountry != input;

    if (hasCity || hasCountry) {
      final location = hasCity ? normalizedCity : normalizedCountry;
      final isCity = hasCity;

      final tip = await CotmindService.getTip(location, isCity: isCity);
      final vibeScore =
          await CotmindService.getSentiment(location, isCity: isCity);
      final vibe = _getVibeFromScore(vibeScore);

      final postingsSnap = await FirebaseFirestore.instance
          .collection('postings')
          .where(isCity ? 'city' : 'country', isEqualTo: location)
          .get();

      if (postingsSnap.docs.isEmpty) {
        return CotmindResponse(
          message: "No listings found for *$location* yet. Try another place.",
          typewriter: true,
        );
      }

      final postingIds = postingsSnap.docs.map((d) => d.id).toList();
      final reelsSnap = await FirebaseFirestore.instance
          .collection('reels')
          .where('postingId', whereIn: postingIds)
          .orderBy('time', descending: true)
          .limit(2)
          .get();

      final videos = reelsSnap.docs
          .map((d) => (d.data() as Map<String, dynamic>)['url'] as String)
          .toList();

      _lastCity = isCity ? location : null;
      _lastCountry = isCity ? null : location;
      _lastTags = tags;

      final message =
          "${isCity ? "📍 *$normalizedCity*" : "🌍 *$normalizedCountry*"} — vibe is *$vibe*. Tip: $tip\n\n"
          "${videos.isEmpty ? "No video previews available yet." : "Here are some listings 👇"}";

      return CotmindResponse(
        message: message,
        videos: videos,
        typewriter: true,
      );
    }

    if (tags.isNotEmpty || tone == 'calm' || tone == 'energetic') {
      Query query = FirebaseFirestore.instance.collection('postings');

      for (var tag in tags) {
        query = query.where('amenities', arrayContains: tag);
      }

      final postingsSnap = await query.get();
      if (postingsSnap.docs.isEmpty) {
        return CotmindResponse(
          message:
              "I couldn't find any postings matching that description right now.",
          typewriter: true,
        );
      }

      final postingIds = postingsSnap.docs.map((d) => d.id).toList();
      final reelsSnap = await FirebaseFirestore.instance
          .collection('reels')
          .where('postingId', whereIn: postingIds)
          .orderBy('time', descending: true)
          .limit(2)
          .get();

      final videos = reelsSnap.docs
          .map((d) => (d.data() as Map<String, dynamic>)['url'] as String)
          .toList();

      _lastCity = null;
      _lastCountry = null;
      _lastTags = tags;

      final message =
          "🔎 I found postings based on your description — take a look 👇";
      return CotmindResponse(
        message: message,
        videos: videos,
        typewriter: true,
      );
    }

    return CotmindResponse(
      message: _getDynamicGreeting(input: input, tone: tone),
      typewriter: true,
    );
  }

  static List<String> _extractTags(String input) {
    final lower = input.toLowerCase();
    final tags = <String>[];
    if (lower.contains("pool")) tags.add("pool");
    if (lower.contains("wifi") || lower.contains("internet")) tags.add("wifi");
    if (lower.contains("beach")) tags.add("beach");
    if (lower.contains("breakfast")) tags.add("breakfast");
    if (lower.contains("kid") || lower.contains("family")) tags.add("family");
    if (lower.contains("luxury")) tags.add("luxury");
    return tags;
  }

  static String _getVibeFromScore(double score) {
    return score > 1.2
        ? "energetic"
        : score < 0.8
            ? "calm"
            : "balanced";
  }

  static String _getDynamicGreeting({String? input, String? tone}) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? "Good morning"
        : hour < 18
            ? "Good afternoon"
            : "Good evening";

    String vibePart = tone == 'calm'
        ? "Looking for peaceful accommodations?"
        : tone == 'energetic'
            ? "Seeking something lively?"
            : (input != null && input.isNotEmpty)
                ? "Tell me what you want — I’ll look it up!"
                : "Ask me about a place, price, or amenity!";

    return "$greeting! 👋 $vibePart";
  }
}
