// lib/stubs/flutter_sound_stub.dart
typedef RecordingCallback = void Function(String path);

class FlutterSoundRecorder {
  bool _isRecording = false;

  Future<void> openRecorder() async {
    // Stub: pretend opened
  }

  Future<void> startRecorder({required String toFile}) async {
    _isRecording = true;
    // Stub: pretend recording
  }

  Future<void> stopRecorder() async {
    _isRecording = false;
    // Stub: pretend stopped
  }

  Future<void> closeRecorder() async {
    // Stub: pretend closed
  }

  bool get isRecording => _isRecording;
}
