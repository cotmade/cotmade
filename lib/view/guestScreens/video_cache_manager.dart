import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VideoCacheManager {
  static Future<Directory> _getCacheDir() async {
    return await getApplicationDocumentsDirectory();
  }

  static Future<bool> isCached(String videoId) async {
    final dir = await _getCacheDir();
    final files = dir.listSync();
    return files.any((f) =>
        f is File && p.basenameWithoutExtension(f.path) == videoId);
  }

  static Future<String?> getCachedFilePath(String videoId) async {
  final dir = await _getCacheDir();
  final files = dir.listSync();
  final match = files.firstWhere(
    (f) => f is File && p.basenameWithoutExtension(f.path) == videoId,
    orElse: () => File(''),
  );

  return match.path.isNotEmpty ? match.path : null;
}


  static Future<void> cacheVideo(String videoId, String url) async {
    try {
      final ext = p.extension(url);
      final dir = await _getCacheDir();
      final path = '${dir.path}/$videoId$ext';
      final file = File(path);
      if (await file.exists()) return;

      await Dio().download(url, path);
      print('Video cached: $path');
    } catch (e) {
      print('Failed to cache video: $e');
    }
  }

  static Future<void> deleteVideo(String videoId) async {
    final dir = await _getCacheDir();
    final files = dir.listSync();
    for (var file in files) {
      if (file is File &&
          p.basenameWithoutExtension(file.path) == videoId) {
        await file.delete();
      }
    }
  }

  static Future<List<File>> getCachedFiles() async {
    final dir = await _getCacheDir();
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => ['.mp4', '.mov', '.avi', '.mkv'].contains(p.extension(f.path).toLowerCase()))
        .toList();
  }
}
