// lib/stubs/video_compress_stub.dart
class MediaInfo {
  final String? path;
  final int? filesize;
  final int? duration;

  MediaInfo({this.path, this.filesize, this.duration});
}

class VideoCompress {
  static Future<MediaInfo?> compressVideo(
    String path, {
    int? quality,
    bool? deleteOrigin,
    bool? includeAudio,
  }) async {
    // Stub: just return fake compressed info
    return MediaInfo(
      path: path,
      filesize: 1024 * 512, // 512 KB
      duration: 0,
    );
  }

  static Future<void> deleteAllCache() async {
    // No-op on web
  }
}

