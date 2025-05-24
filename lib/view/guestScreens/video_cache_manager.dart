import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class VideoCacheManager {
  // Extract extension from URL (default to .mp4 if not found)
  static String _getExtensionFromUrl(String url) {
    String extension = path.extension(url).split('?').first;
    return extension.isNotEmpty ? extension : '.mp4';
  }

  // Cache video with correct extension
  static Future<String> cacheVideo(String videoId, String videoUrl) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final extension = _getExtensionFromUrl(videoUrl);
      final filePath = '${cacheDir.path}/$videoId$extension';
      final file = File(filePath);

      if (await file.exists()) {
        return file.path;
      }

      final response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        throw Exception('Failed to download video');
      }
    } catch (e) {
      print("Cache error: $e");
      rethrow;
    }
  }

  // Check if cached by searching for any extension
  static Future<bool> isCached(String videoId) async {
    final cacheDir = await getTemporaryDirectory();
    final files = cacheDir.listSync().whereType<File>();
    return files
        .any((file) => path.basenameWithoutExtension(file.path) == videoId);
  }

  // Get the cached file path regardless of extension
  static Future<String> getVideoPath(String videoId) async {
    final cacheDir = await getTemporaryDirectory();
    final files = cacheDir.listSync().whereType<File>();
    final match = files.firstWhere(
      (file) => path.basenameWithoutExtension(file.path) == videoId,
      orElse: () => throw Exception('Cached video not found'),
    );
    return match.path;
  }

  // Delete video (any extension)
  static Future<void> deleteVideo(String videoId) async {
    final cacheDir = await getTemporaryDirectory();
    final files = cacheDir.listSync().whereType<File>();
    for (var file in files) {
      if (path.basenameWithoutExtension(file.path) == videoId) {
        await file.delete();
      }
    }
  }

  // Return all cached video files
  static Future<List<File>> getCachedFiles() async {
    final cacheDir = await getTemporaryDirectory();
    return cacheDir.listSync().whereType<File>().toList();
  }
}
