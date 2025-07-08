import 'package:cotmade/view/ai/cotmind_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CotmindConversationEngine {
  static Future<String> respond(String input) async {
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

// 🔍 Step 1: Query postings for videos
      QuerySnapshot postingsSnapshot = await FirebaseFirestore.instance
          .collection('postings')
          .where(hasCity ? 'city' : 'country', isGreaterThanOrEqualTo: location)
          .where(hasCity ? 'city' : 'country',
              isLessThanOrEqualTo: location + '\uf8ff')
          .get();

// 🔄 Step 2: Collect posting IDs
      List<String> postingIds = postingsSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['id'] as String;
      }).toList();

// 🎥 Step 3: Query videos that match posting IDs
      QuerySnapshot videoSnapshot = await FirebaseFirestore.instance
          .collection('videos') // Or whatever your collection is named
          .where('postingId',
              whereIn:
                  postingIds.take(10).toList()) // Firestore limit workaround
          .limit(2)
          .get();

// 📦 Step 4: Extract video info
      if (videoSnapshot.docs.isNotEmpty) {
        final videos = videoSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['title'] ??
              data['url'] ??
              'Video'; // Customize what you want to show
        }).toList();

        message += "\n🎬 Suggested videos: ${videos.join(', ')}";
      }

      return message;
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
        return tone == 'calm'
            ? "😌 You might enjoy these peaceful cities: ${matches.join(', ')}."
            : "🎉 Feeling hyped? These buzzing places might be your vibe: ${matches.join(', ')}.";
      }
    }

    return "👋 Hey! Ask me about a city, country, or your travel vibe — like 'fun places in SA' or 'calm cities near Nigeria'.";
  }
}
