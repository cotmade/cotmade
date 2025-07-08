import 'package:cotmade/view/ai/cotmind_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CotmindResponse {
  final String message;
  final List<String> videos;

  CotmindResponse({required this.message, this.videos = const []});
}

class CotmindConversationEngine {
  static final List<String> _vibeWords = [
    "vibrant", "lively", "energetic", "peaceful",
    "relaxed", "balanced", "serene", "buzzing"
  ];

  static final List<String> _greetingPrompts = [
    "Curious about a place? Ask me anything!",
    "Where are you thinking of traveling next?",
    "Tell me a destination — I'm all ears!",
    "Want travel tips or vibes? Just ask!",
  ];

  static String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    return hour < 12
        ? "Good morning"
        : hour < 18
            ? "Good afternoon"
            : "Good evening";
  }

  static String _describeVibe(double score) {
    final candidates = score > 1.2
        ? _vibeWords.sublist(0, 4)
        : score < 0.8
            ? _vibeWords.sublist(3, 7)
            : _vibeWords.sublist(5, 8);
    final idx = DateTime.now().millisecondsSinceEpoch % candidates.length;
    return candidates[idx];
  }

  static String _dynamicGreeting(String tone, String input) {
    final timeGreet = _getTimeGreeting();
    final idx = DateTime.now().millisecondsSinceEpoch % _greetingPrompts.length;
    final prompt = _greetingPrompts[idx];
    return "$timeGreet! 👋 $prompt";
  }

  static Future<CotmindResponse> respond(String input) async {
    final tone = CotmindService.detectTone(input);
    final normCity = await CotmindService.normalizeCity(input);
    final normCountry = await CotmindService.normalizeCountry(input);
    final hasCity = normCity != input;
    final hasCountry = normCountry != input;

    if (!hasCity && !hasCountry) {
      return CotmindResponse(message: _dynamicGreeting(tone, input));
    }

    final location = hasCity ? normCity : normCountry;
    final tip = hasCity
        ? await CotmindService.getCityTip(normCity)
        : await CotmindService.getCountryTip(normCountry);
    final vibeScore = hasCity
        ? await CotmindService.getCitySentiment(normCity)
        : await CotmindService.getCountrySentiment(normCountry);
    final vibe = _describeVibe(vibeScore);
    final prefix = hasCity ? "📍 *$normCity*" : "🌍 *$normCountry*";
    final message = "$prefix feels *$vibe*. Tip: $tip";

    final postings = await FirebaseFirestore.instance
        .collection('postings')
        .where(hasCity ? 'city' : 'country', isEqualTo: location)
        .limit(10)
        .get();
    final ids = postings.docs.map((d) => d.id).toList();

    if (ids.isEmpty) {
      return CotmindResponse(message: message);
    }

    final reels = await FirebaseFirestore.instance
        .collection('reels')
        .where('postingId', whereIn: ids.take(10).toList())
        .limit(2)
        .get();
    final videos = reels.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['url'] as String;
    }).toList();

    return CotmindResponse(message: message, videos: videos);
  }
}
