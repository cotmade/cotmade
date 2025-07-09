import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CotmindService {
  // 🔖 Static Synonym Maps
  static final _citySynonyms = {
    'abj': 'abuja',
    'lasgidi': 'lagos',
    'ph': 'port harcourt',
    'cpt': 'cape town',
    'ikoyi': 'lagos',
  };

  static final _countrySynonyms = {
    'naija': 'nigeria',
    'ng': 'nigeria',
    'sa': 'south africa',
    'gh': 'ghana',
    'uk': 'united kingdom',
  };

  static final _cityCache = Map<String, String>.from(_citySynonyms);
  static final _countryCache = Map<String, String>.from(_countrySynonyms);
  static const double _simThreshold = 0.6;

  // 🔁 Normalize city input (learn unknown)
  static Future<String> normalizeCity(String input) async {
    input = input.trim().toLowerCase();
    if (_cityCache.containsKey(input)) return _cityCache[input]!;

    for (var k in _cityCache.keys) {
      if (_stringSim(input, k) > _simThreshold) return _cityCache[k]!;
    }

    final docRef =
        FirebaseFirestore.instance.collection('dynamicCitySynonyms').doc(input);
    await docRef.set({'city': input});
    _cityCache[input] = input;
    return input;
  }

  // 🔁 Normalize country input (learn unknown)
  static Future<String> normalizeCountry(String input) async {
    input = input.trim().toLowerCase();
    if (_countryCache.containsKey(input)) return _countryCache[input]!;

    for (var k in _countryCache.keys) {
      if (_stringSim(input, k) > _simThreshold) return _countryCache[k]!;
    }

    final docRef = FirebaseFirestore.instance
        .collection('dynamicCountrySynonyms')
        .doc(input);
    await docRef.set({'country': input});
    _countryCache[input] = input;
    return input;
  }

  // 🔎 Detect tone from query
  static String detectTone(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("peace") || lower.contains("quiet")) return "calm";
    if (lower.contains("party") || lower.contains("fun")) return "energetic";
    if (lower.contains("?") || lower.contains("tip")) return "inquisitive";
    return "neutral";
  }

  // 💡 Get tip (returns stored tip or generates one)
  static Future<String> getTip(String location, {bool isCity = true}) async {
    final col = isCity ? 'cotmindTipsCities' : 'cotmindTipsCountries';

    try {
      final doc =
          await FirebaseFirestore.instance.collection(col).doc(location).get();
      if (doc.exists && doc.data()?['tip'] != null) {
        return doc['tip'];
      }

      // Generate if not found
      return isCity
          ? await generateCityTip(location)
          : await generateCountryTip(location);
    } catch (_) {
      return isCity
          ? "Explore $location — it's full of surprises!"
          : "Discover the charm of $location — there's something for everyone!";
    }
  }

  // 🎬 Video URL recommendation based on postings + reels
  static Future<List<String>> getVideoUrlsForLocation(String location,
      {bool isCity = true}) async {
    final field = isCity ? 'city' : 'country';

    try {
      final postingsSnap = await FirebaseFirestore.instance
          .collection('postings')
          .where(field, isEqualTo: location)
          .limit(10)
          .get();

      if (postingsSnap.docs.isEmpty) return [];

      final ids = postingsSnap.docs.map((d) => d.id).toList();

      final reelsSnap = await FirebaseFirestore.instance
          .collection('reels')
          .where('postingId', whereIn: ids.take(10).toList())
          .limit(2)
          .get();

      return reelsSnap.docs
          .map((d) => d.data()['url'] as String?)
          .whereType<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  // 📈 Get sentiment score for location based on search logs
  static Future<double> getSentiment(String location,
      {bool isCity = true}) async {
    final field = isCity ? 'city' : 'country';
    final weekAgo =
        Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7)));
    final q = await FirebaseFirestore.instance
        .collection('searchLogs')
        .where(field, isEqualTo: location)
        .where('timestamp', isGreaterThan: weekAgo)
        .get();

    if (q.docs.isEmpty) return 1.0;

    int energeticCount = 0, calmCount = 0;
    for (var d in q.docs) {
      if (d['tone'] == 'energetic') energeticCount++;
      if (d['tone'] == 'calm') calmCount++;
    }
    return (energeticCount + 0.1) / (calmCount + 0.1);
  }

  // 🧠 Generate AI-style city tip (stores tip)
  static Future<String> generateCityTip(String city) async {
    city = city.trim().toLowerCase();

    final count = await _getSearchCount(city, isCity: true);
    final sentiment = await getSentiment(city, isCity: true);

    String trend;
    if (count > 200) {
      trend = "a trending hotspot";
    } else if (count > 50) {
      trend = "growing in popularity";
    } else if (count > 0) {
      trend = "starting to attract attention";
    } else {
      trend = "quiet and under the radar";
    }

    final mood = sentiment > 1.2
        ? "full of energy and buzz"
        : sentiment < 0.8
            ? "relaxing and peaceful"
            : "a balanced mix of calm and liveliness";

    final tags = _cityTags[city] ?? [];
    final tagDesc = tags.isNotEmpty
        ? "Known for its ${tags.take(2).join(' and ')}"
        : "Full of hidden gems";

    final tip =
        "$city is $trend. It's $mood. $tagDesc — definitely worth exploring!";

    await FirebaseFirestore.instance
        .collection('cotmindTipsCities')
        .doc(city)
        .set({
      'tip': tip,
      'count': count,
      'sentiment': sentiment,
      'tags': tags,
      'updatedAt': FieldValue.serverTimestamp()
    });

    return tip;
  }

  // 🧠 Generate AI-style country tip (stores tip)
  static Future<String> generateCountryTip(String country) async {
    country = country.trim().toLowerCase();

    final sentiment = await getSentiment(country, isCity: false);
    final searchCount = await _getSearchCount(country, isCity: false);

    final vibe = sentiment > 1.2
        ? "upbeat adventures"
        : sentiment < 0.8
            ? "relaxing escapes"
            : "a mix of cultures and energy";

    final tip =
        "$country is trending with $searchCount recent searches. Expect $vibe — from culture to nature, it's worth exploring!";

    try {
      await FirebaseFirestore.instance
          .collection('cotmindTipsCountries')
          .doc(country)
          .set({'tip': tip});
      print("✅ Tip created for country: $country");
    } catch (e) {
      print("❌ Failed to create tip: $e");
    }

    return tip;
  }

  // 💬 Rule-based AI-like tip generator (offline fallback)
  static String _generateLocalTravelTip(String place, String vibe,
      {bool isCity = true}) {
    final adjectives = [
      'vibrant',
      'charming',
      'bustling',
      'relaxing',
      'cultural',
      'lively',
      'dynamic',
      'scenic'
    ];
    final experiences = [
      'local markets',
      'beaches',
      'historic sites',
      'nightlife',
      'food scenes',
      'hidden gems'
    ];
    final endings = [
      "you'll love every moment here.",
      "it's perfect for curious explorers.",
      "you'll find something new each day.",
      "it has something for everyone.",
    ];

    final adjective = adjectives[DateTime.now().second % adjectives.length];
    final experience =
        experiences[DateTime.now().millisecond % experiences.length];
    final ending = endings[DateTime.now().second % endings.length];

    return "$place offers a $adjective atmosphere with $vibe vibes — don't miss the $experience, $ending";
  }

  // 🧠 Load dynamic synonyms from Firebase at app startup
  static Future<void> loadDynamicSynonyms() async {
    final citySnaps = await FirebaseFirestore.instance
        .collection('dynamicCitySynonyms')
        .get();
    for (var d in citySnaps.docs) {
      _cityCache[d.id] = d['city'];
    }

    final countrySnaps = await FirebaseFirestore.instance
        .collection('dynamicCountrySynonyms')
        .get();
    for (var d in countrySnaps.docs) {
      _countryCache[d.id] = d['country'];
    }
  }

  // 📝 Log user search for analytics (tone + normalized location)
  static Future<void> logSearch(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    final cityNorm = await normalizeCity(query);
    final country = _inferCountryFromCity(cityNorm);
    final countryNorm = await normalizeCountry(country);
    final tone = detectTone(query);
    final now = Timestamp.now();

    await FirebaseFirestore.instance.collection('searchLogs').add({
      'uid': user?.uid ?? 'guest',
      'query': query,
      'city': cityNorm,
      'country': countryNorm,
      'tone': tone,
      'timestamp': now,
    });
  }

  // ⛳️ Infer country from known city or return unknown
  static String _inferCountryFromCity(String city) {
    const map = {
      'lagos': 'nigeria',
      'abuja': 'nigeria',
      'cape town': 'south africa',
      'accra': 'ghana',
      'london': 'united kingdom',
    };
    return map[city] ?? 'unknown';
  }

  // 🔍 Simple character-level string similarity (Jaccard index)
  static double _stringSim(String a, String b) {
    final sa = a.split('').toSet();
    final sb = b.split('').toSet();
    final inter = sa.intersection(sb).length;
    final union = sa.union(sb).length;
    return union == 0 ? 0.0 : inter / union;
  }

  /// Returns a list of top trending cities (mocked by searchLogs count)
  static Future<List<String>> getTopTrendingCities({int limit = 10}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('searchLogs')
          .orderBy('timestamp', descending: true)
          .limit(limit * 5) // fetch more for better sorting below
          .get();

      final cityCount = <String, int>{};

      for (var doc in snapshot.docs) {
        final city = doc['city'] as String? ?? 'unknown';
        cityCount[city] = (cityCount[city] ?? 0) + 1;
      }

      final sortedCities = cityCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCities.take(limit).map((e) => e.key).toList();
    } catch (_) {
      return [];
    }
  }

  /// Gets user taste profile, a map of tag->weight (mocked for now)
  static Future<Map<String, double>?> getUserTasteProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('userTastes')
          .doc(uid)
          .get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      final Map<String, dynamic> rawTaste = data['taste'] ?? {};
      return rawTaste.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return null;
    }
  }

  /// Ranks cities by combining user taste and tag matching, returns ordered city list
  static List<String> rankByTasteAndTags(List<String> trending,
      Map<String, double>? userTaste, List<String> tags) {
    if (userTaste == null || userTaste.isEmpty || tags.isEmpty) {
      return trending;
    }

    // Calculate score = sum of tag weights that match userTaste
    final scored = trending.map((city) {
      // Mock city tags (in reality you'd fetch city tags from DB)
      final cityTags = _cityTags[city.toLowerCase()] ?? [];

      double score = 0;
      for (var tag in tags) {
        if (cityTags.contains(tag)) {
          score += userTaste[tag] ?? 0;
        }
      }
      return MapEntry(city, score);
    }).toList();

    // Sort descending by score, fallback to original order for ties
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  /// Smart video fetch by filtering reels for given tags
  static Future<List<String>> getVideoUrlsForLocationSmart(String location,
      {List<String> tags = const []}) async {
    final field = 'city'; // assuming city for demo, adjust if needed
    try {
      // Get postings matching location
      final postingsSnap = await FirebaseFirestore.instance
          .collection('postings')
          .where(field, isEqualTo: location)
          .limit(20)
          .get();

      if (postingsSnap.docs.isEmpty) return [];

      final postingIds = postingsSnap.docs.map((d) => d.id).toList();

      // Get reels that match tags (assuming reels have 'tags' array field)
      final reelsSnap = await FirebaseFirestore.instance
          .collection('reels')
          .where('postingId', whereIn: postingIds)
          .get();

      final filteredUrls = <String>[];

      for (var reelDoc in reelsSnap.docs) {
        final reelData = reelDoc.data();
        final reelTags = (reelData['tags'] as List<dynamic>?)
                ?.map((e) => e.toString().toLowerCase())
                .toList() ??
            [];

        if (tags.isEmpty || tags.any((tag) => reelTags.contains(tag))) {
          final url = reelData['url'] as String?;
          if (url != null) filteredUrls.add(url);
          if (filteredUrls.length >= 5) break; // limit to 5
        }
      }
      return filteredUrls;
    } catch (_) {
      return [];
    }
  }

  /// Dummy city tags for demo; in real case, fetch from DB or external source
  static final Map<String, List<String>> _cityTags = {
    'lagos': ['beach', 'nightlife', 'energetic'],
    'abuja': ['calm', 'peaceful', 'nature'],
    'cape town': ['beach', 'mountain', 'nature'],
    'accra': ['beach', 'energetic', 'party'],
    'london': ['nightlife', 'energetic'],
  };

  static Future<void> refreshAllCityTips() async {
    final countsSnap =
        await FirebaseFirestore.instance.collection('searchCountsByCity').get();

    for (final doc in countsSnap.docs) {
      final city = doc.id;
      await generateCityTip(city); // This regenerates the tip
    }
  }

  static Future<void> refreshAllCountryTips() async {
    final countsSnap = await FirebaseFirestore.instance
        .collection('searchCountsByCountry')
        .get();

    for (final doc in countsSnap.docs) {
      final country = doc.id;
      await generateCountryTip(country); // This regenerates the tip
    }
  }

  // 🔢 Fetch search count from Firebase (searchCountsByCity or searchCountsByCountry)
  // 🔢 Fetch search count from Firebase (searchCountsByCity or searchCountsByCountry)
  static Future<int> _getSearchCount(String location,
      {required bool isCity}) async {
    final collection = isCity ? 'searchCountsByCity' : 'searchCountsByCountry';
    final docId = location.trim().toLowerCase();

    try {
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .get();

      if (doc.exists && doc.data()?['count'] != null) {
        return (doc.data()!['count'] as num).toInt();
      }
    } catch (e) {
      print("⚠️ Error fetching count for $location from $collection: $e");
    }

    return 0; // fallback if no data found
  }
}
