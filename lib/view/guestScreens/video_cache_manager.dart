import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VideoCacheManager {
  /// Get the local directory for storing cached videos
  static Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/cached_videos';
    await Directory(path).create(recursive: true);
    return path;
  }

  /// Get the file name with correct extension from URL
  static String _getFileName(String videoId, String url) {
    final ext = p.extension(url); // e.g. .mp4 or .mov
    return '$videoId$ext';
  }

  /// Get the File reference for the video
  static Future<File> _getVideoFile(String videoId, String url) async {
    final path = await _getLocalPath();
    final fileName = _getFileName(videoId, url);
    return File('$path/$fileName');
  }

  /// Check if video is already cached
  static Future<String?> getCachedVideo(String videoId, String url) async {
    final file = await _getVideoFile(videoId, url);
    return file.existsSync() ? file.path : null;
  }

  /// Download and cache the video if not already cached
  static Future<String> cacheVideo(String videoId, String url) async {
    final file = await _getVideoFile(videoId, url);

    if (await file.exists()) return file.path;

    final dio = Dio();
    await dio.download(url, file.path);
    return file.path;
  }
}
