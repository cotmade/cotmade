import 'package:cotmade/view/ai/cotmind_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CotmindResponse {
  final String message;
  final List<String> videos;

  CotmindResponse({required this.message, this.videos = const []});
}

class CotmindConversationEngine {
  static Future<CotmindResponse> respond(String input) async {
    final normalizedCity = await CotmindService.normalizeCity(input);
    final normalizedCountry = await CotmindService.normalizeCountry(input);
    final tone = CotmindService.detectTone(input);

    final hasCity = normalizedCity != input;
    final hasCountry = normalizedCountry != input;

    if (hasCity || hasCountry) {
      final tip = hasCity
          ? await CotmindService.getCityTip(normalizedCity)
          : await CotmindService.getCountryTip(normalizedCountry);
      final vibeScore = hasCity
          ? await CotmindService.getCitySentiment(normalizedCity)
          : await CotmindService.getCountrySentiment(normalizedCountry);

      final vibe = vibeScore > 1.2
          ? "vibe is energetic"
          : vibeScore < 0.8
              ? "vibe is calm"
              : "vibe is balanced";

      String location = hasCity ? normalizedCity : normalizedCountry;
      String prefix =
          hasCity ? "📍 *$normalizedCity*" : "🌍 *$normalizedCountry*";
      String message = "$prefix is trending — $vibe. Tip: $tip";

      // 🔍 Step 1: Query postings for documents matching city/country
      QuerySnapshot postingsSnapshot = await FirebaseFirestore.instance
          .collection('postings')
          .where(hasCity ? 'city' : 'country', isGreaterThanOrEqualTo: location)
          .where(hasCity ? 'city' : 'country',
              isLessThanOrEqualTo: location + '\uf8ff')
          .get();

      if (postingsSnapshot.docs.isEmpty) {
        return CotmindResponse(message: message);
      }

      // 🔄 Step 2: Collect posting document IDs
      List<String> postingIds =
          postingsSnapshot.docs.map((doc) => doc.id).toList();

      // 🎥 Step 3: Query reels collection for videos with postingId in postingIds
      QuerySnapshot reelsSnapshot = await FirebaseFirestore.instance
          .collection('reels') // assuming 'reels' collection has videos
          .where('postingId',
              whereIn: postingIds.take(10).toList()) // Firestore limit
          .limit(2)
          .get();

      // 📦 Step 4: Extract video info (title or url)
      List<String> reels = reelsSnapshot.docs.map<String>((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['url'] as String;
      }).toList();

      return CotmindResponse(message: message, videos: reels);
    }

    if (tone == 'calm' || tone == 'energetic') {
      final trending = await CotmindService.getTopTrendingCities(limit: 5);
      final matches = <String>[];

      for (final city in trending) {
        final sentiment = await CotmindService.getCitySentiment(city);
        if (tone == 'calm' && sentiment < 0.8) matches.add(city);
        if (tone == 'energetic' && sentiment > 1.2) matches.add(city);
      }

      if (matches.isNotEmpty) {
        final message = tone == 'calm'
            ? "😌 You might enjoy these peaceful cities: ${matches.join(', ')}."
            : "🎉 Feeling hyped? These buzzing places might be your vibe: ${matches.join(', ')}.";
        return CotmindResponse(message: message);
      }
    }

    String getDynamicGreeting({String? userInput, String? tone}) {
      final hour = DateTime.now().hour;
      String timeGreeting;

      if (hour < 12) {
        timeGreeting = "Good morning";
      } else if (hour < 18) {
        timeGreeting = "Good afternoon";
      } else {
        timeGreeting = "Good evening";
      }

      String vibePart = "";

      if (tone == 'calm') {
        vibePart = "Looking for some peaceful spots?";
      } else if (tone == 'energetic') {
        vibePart = "Ready for some exciting adventures?";
      } else if (userInput != null && userInput.isNotEmpty) {
        vibePart = "Tell me more about \"$userInput\" or ask for travel vibes!";
      } else {
        vibePart = "Ask me about a city, country, or your travel vibe!";
      }

      return "$timeGreeting! 👋 $vibePart";
    }

    return CotmindResponse(
      message: getDynamicGreeting(userInput: input, tone: tone),
    );
  }
}
