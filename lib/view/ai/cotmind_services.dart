import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CotmindService {
  // Synonyms for cities + countries
  static Map<String, String> _citySynonyms = {
    'abj': 'abuja',
    'lasgidi': 'lagos',
    'ph': 'port harcourt',
    'cpt': 'cape town',
    'ikoyi': 'lagos',
  };
  static Map<String, String> _countrySynonyms = {
    'naija': 'nigeria',
    'ng': 'nigeria',
    'sa': 'south africa',
    'gh': 'ghana',
    'uk': 'united kingdom',
  };

  static final Map<String, String> _tipsCacheCity = {};
  static final Map<String, String> _tipsCacheCountry = {};
  static final Map<String, String> _cityCache = Map.from(_citySynonyms);
  static final Map<String, String> _countryCache = Map.from(_countrySynonyms);

  static const double _simThreshold = 0.6;

  /// Normalize city input, learn unknown aliases
  static Future<String> normalizeCity(String input) async {
    input = input.trim().toLowerCase();
    if (_cityCache.containsKey(input)) return _cityCache[input]!;
    for (var k in _cityCache.keys) {
      if (_stringSim(input, k) > _simThreshold) return _cityCache[k]!;
    }
    await _learnCitySynonym(input, input);
    return input;
  }

  static Future<void> _learnCitySynonym(String alias, String city) async {
    if (_cityCache.containsKey(alias)) return;

    final docRef =
        FirebaseFirestore.instance.collection('dynamicCitySynonyms').doc(alias);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final docSnap = await tx.get(docRef);
      if (!docSnap.exists) {
        tx.set(docRef, {'city': city, 'createdAt': Timestamp.now()});
        _cityCache[alias] = city;
      }
    });
  }

  /// Normalize country input, learn unknown
  static Future<String> normalizeCountry(String input) async {
    input = input.trim().toLowerCase();
    if (_countryCache.containsKey(input)) return _countryCache[input]!;
    for (var k in _countryCache.keys) {
      if (_stringSim(input, k) > _simThreshold) return _countryCache[k]!;
    }
    await _learnCountrySynonym(input, input);
    return input;
  }

  static Future<void> _learnCountrySynonym(String alias, String country) async {
    if (_countryCache.containsKey(alias)) return;

    final docRef = FirebaseFirestore.instance
        .collection('dynamicCountrySynonyms')
        .doc(alias);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final docSnap = await tx.get(docRef);
      if (!docSnap.exists) {
        tx.set(docRef, {'country': country, 'createdAt': Timestamp.now()});
        _countryCache[alias] = country;
      }
    });
  }

  /// Log search with both city + country normalization, tone, trending
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

    await incrementSearchCount(cityNorm);
    await incrementCountryCount(countryNorm);
    await _updateUserTaste(user?.uid, cityNorm, tone);
    await updateUserPreferences(cityNorm, countryNorm);
  }

  /// Tone detection
  static String detectTone(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('quiet') || lower.contains('peace')) return 'calm';
    if (lower.contains('party') || lower.contains('fun')) return 'energetic';
    if (lower.contains('?') || lower.contains('help')) return 'inquisitive';
    return 'neutral';
  }

  /// Infer country from city (static mapping fallback)
  static String _inferCountryFromCity(String city) {
    const Map<String, String> map = {
      'lagos': 'nigeria',
      'abuja': 'nigeria',
      'cape town': 'south africa',
      'accra': 'ghana',
      'london': 'united kingdom',
    };
    return map[city] ?? 'unknown';
  }

  /// Get or generate tip for a city
  static Future<String> getCityTip(String city) async {
    city = city.toLowerCase();
    if (_tipsCacheCity.containsKey(city)) return _tipsCacheCity[city]!;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('cotmindTipsCities')
          .doc(city)
          .get();
      if (doc.exists) return _tipsCacheCity[city] = doc['tip'];
      return _tipsCacheCity[city] = await _generateDynamicCityTip(city);
    } catch (_) {
      return "I can’t generate a city tip right now. Kindly try another word";
    }
  }

  /// Get or generate tip for a country
  static Future<String> getCountryTip(String country) async {
    country = country.toLowerCase();
    if (_tipsCacheCountry.containsKey(country))
      return _tipsCacheCountry[country]!;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('cotmindTipsCountries')
          .doc(country)
          .get();
      if (doc.exists) return _tipsCacheCountry[country] = doc['tip'];
      return _tipsCacheCountry[country] =
          await _generateDynamicCountryTip(country);
    } catch (_) {
      return "I can’t generate a country tip right now. Kindly try another word";
    }
  }

  /// Generate dynamic city tip
  static Future<String> _generateDynamicCityTip(String city) async {
    final cntSnap = await FirebaseFirestore.instance
        .collection('searchCountsByCity')
        .doc(city)
        .get();
    final cnt = cntSnap.exists ? (cntSnap.data()?['count'] ?? 0) : 0;
    final sentiment = await getCitySentiment(city);
    final mood = sentiment > 1.2
        ? "vibe is buzzing"
        : sentiment < 0.8
            ? "seems calm"
            : "energy is balanced";

    if (cnt > 100) return "🔥 $city is popular — $mood.";
    if (cnt > 20) return "🌟 $city is trending — $mood.";
    return "$city is emerging — $mood.";
  }

  /// Generate dynamic country tip
  static Future<String> _generateDynamicCountryTip(String country) async {
    final cntSnap = await FirebaseFirestore.instance
        .collection('searchCountsByCountry')
        .doc(country)
        .get();
    final cnt = cntSnap.exists ? (cntSnap.data()?['count'] ?? 0) : 0;
    final sentiment = await getCountrySentiment(country);
    final mood = sentiment > 1.2
        ? "mood is upbeat"
        : sentiment < 0.8
            ? "feels calm"
            : "feels balanced";

    if (cnt > 100) return "🔥 $country is hot — $mood.";
    if (cnt > 20) return "🌟 $country is gaining interest — $mood.";
    return "$country is emerging — $mood.";
  }

  /// Sentiment scoring for city
  static Future<double> getCitySentiment(String city) async {
    final weekAgo =
        Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7)));
    final q = await FirebaseFirestore.instance
        .collection('searchLogs')
        .where('city', isEqualTo: city)
        .where('timestamp', isGreaterThan: weekAgo)
        .get();
    if (q.docs.isEmpty) return 1.0;
    int e = 0, c = 0;
    for (var d in q.docs) {
      if (d['tone'] == 'energetic') e++;
      if (d['tone'] == 'calm') c++;
    }
    return (e + 0.1) / (c + 0.1);
  }

  /// Sentiment scoring for country
  static Future<double> getCountrySentiment(String country) async {
    final weekAgo =
        Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7)));
    final q = await FirebaseFirestore.instance
        .collection('searchLogs')
        .where('country', isEqualTo: country)
        .where('timestamp', isGreaterThan: weekAgo)
        .get();
    if (q.docs.isEmpty) return 1.0;
    int e = 0, c = 0;
    for (var d in q.docs) {
      if (d['tone'] == 'energetic') e++;
      if (d['tone'] == 'calm') c++;
    }
    return (e + 0.1) / (c + 0.1);
  }

  /// Increment city search count
  static Future<void> incrementSearchCount(String city) async {
    final ref =
        FirebaseFirestore.instance.collection('searchCountsByCity').doc(city);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      tx.set(ref, {'count': (snap.data()?['count'] ?? 0) + 1},
          SetOptions(merge: true));
    });
  }

  /// Increment country search count
  static Future<void> incrementCountryCount(String country) async {
    final ref = FirebaseFirestore.instance
        .collection('searchCountsByCountry')
        .doc(country);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      tx.set(ref, {'count': (snap.data()?['count'] ?? 0) + 1},
          SetOptions(merge: true));
    });
  }

  /// Get top trending cities
  static Future<List<String>> getTopTrendingCities({int limit = 5}) async {
    final q = await FirebaseFirestore.instance
        .collection('searchCountsByCity')
        .orderBy('count', descending: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => d.id).toList();
  }

  /// Get top trending countries
  static Future<List<String>> getTopTrendingCountries({int limit = 5}) async {
    final q = await FirebaseFirestore.instance
        .collection('searchCountsByCountry')
        .orderBy('count', descending: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => d.id).toList();
  }

  /// User’s taste profiling (increments frequency)
  static Future<void> _updateUserTaste(
      String? uid, String city, String tone) async {
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('userTastes').doc(uid);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      Map<String, dynamic> data = snap.exists
          ? snap.data() as Map<String, dynamic>
          : {'counts': {}, 'tones': {}};

      data['counts'][city] = (data['counts'][city] ?? 0) + 1;
      data['tones'][tone] = (data['tones'][tone] ?? 0) + 1;

      tx.set(ref, data, SetOptions(merge: true));
    });
  }

  /// Get trending locations (city + country context)
  static Future<List<Map<String, dynamic>>> getTrendingWithContext(
      {int limit = 5}) async {
    final cities = await getTopTrendingCities(limit: limit);
    final countries = await getTopTrendingCountries(limit: limit);
    final results = <Map<String, dynamic>>[];

    for (var city in cities) {
      final tip = await getCityTip(city);
      final sent = await getCitySentiment(city);
      final label = sent > 1.2
          ? "👌 buzzing"
          : sent < 0.8
              ? "😌 calm"
              : "😊 balanced";
      results.add({'type': 'city', 'name': city, 'tip': tip, 'label': label});
    }

    for (var country in countries) {
      final tip = await getCountryTip(country);
      final sent = await getCountrySentiment(country);
      final label = sent > 1.2
          ? "👌 upbeat"
          : sent < 0.8
              ? "😌 calm"
              : "😊 balanced";
      results.add(
          {'type': 'country', 'name': country, 'tip': tip, 'label': label});
    }

    return results;
  }

  /// Find posting IDs by city
  static Future<List<String>> getMatchingPostsByCity(String city) async {
    final q = await FirebaseFirestore.instance
        .collection('postings')
        .where('city', isGreaterThanOrEqualTo: city)
        .where('city', isLessThanOrEqualTo: city + '\uf8ff')
        .get();
    return q.docs.map((d) => d.id).toList(); // FIXED
  }

  /// Find posting IDs by country
  static Future<List<String>> getMatchingPostsByCountry(String country) async {
    final q = await FirebaseFirestore.instance
        .collection('postings')
        .where('country', isGreaterThanOrEqualTo: country)
        .where('country', isLessThanOrEqualTo: country + '\uf8ff')
        .get();
    return q.docs.map((d) => d.id).toList(); // FIXED
  }

  /// Simple fuzzy similarity (Jaccard)
  static double _stringSim(String a, String b) {
    final sa = a.split('').toSet(), sb = b.split('').toSet();
    final inter = sa.intersection(sb).length;
    final union = sa.union(sb).length;
    return union == 0 ? 0.0 : inter / union;
  }

  /// Update user preferences with both city & country
  static Future<void> updateUserPreferences(String city, String country) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('userPreferences')
        .doc(user.uid)
        .set({
      'recentCity': city,
      'recentCountry': country,
      'updatedAt': Timestamp.now()
    }, SetOptions(merge: true));
  }

  /// Load all dynamic synonyms on startup
  static Future<void> loadDynamicSynonyms() async {
    final citySnaps = await FirebaseFirestore.instance
        .collection('dynamicCitySynonyms')
        .get();
    for (var d in citySnaps.docs) _cityCache[d.id] = d['city'];

    final countrySnaps = await FirebaseFirestore.instance
        .collection('dynamicCountrySynonyms')
        .get();
    for (var d in countrySnaps.docs) _countryCache[d.id] = d['country'];
  }
}
