import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  static String? _cachedKey;
  static DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 10);
  static const _configUrl =
      'https://cotmade.com/get_key.php'; // your PHP endpoint

  static Future<String> getApiKey() async {
    final now = DateTime.now();

    if (_cachedKey != null && _lastFetch != null) {
      if (now.difference(_lastFetch!) < _cacheDuration) {
        return _cachedKey!;
      }
    }

    final res = await http.get(Uri.parse(_configUrl));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _cachedKey = data['cohereApiKey'];
      _lastFetch = now;
      return _cachedKey!;
    } else {
      throw Exception('Failed to fetch API key');
    }
  }

  static void clearCache() {
    _cachedKey = null;
    _lastFetch = null;
  }
}
