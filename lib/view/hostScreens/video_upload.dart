import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_compress/video_compress.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:video_player/video_player.dart';
//import 'package:flutter_sound/flutter_sound.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:just_audio/just_audio.dart';

class VideoUploadPage extends StatefulWidget {
  @override
  _VideoUploadPageState createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  File? _videoFile;
  String? _audioName; // Track selected audio name
  VideoPlayerController? _videoController; // Video controller
  String? _caption;
  bool _isUploading = false;
  bool _isTermsAccepted = false; // Track checkbox state
  bool _audioFinished = false;
  bool _isPlaying = false; // Audio player for preview

  @override
  void dispose() {
    _videoController?.dispose(); // Dispose video controller
    _audioPlayer.dispose(); // Dispose audio player
    super.dispose();
  }

  // Pick a video from the gallery
  Future<void> _pickVideo() async {
    final XFile? pickedFile =
        await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _videoController = VideoPlayerController.file(_videoFile!)
          ..initialize().then((_) {
            setState(() {}); // Ensure the video player is initialized
          });
      });
    }
  }

  final List<String> audioFiles = [
    'images/cinematic-intro.mp3',
    'images/cinematic-intro.mp3',
    'images/prazkhanalmusic__chimera-afro-tim-clap-loop.wav',
  ];

  String? _currentPlaying;

  // Pick an audio file from assets/audio
  Future<void> _pickAudio() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Playlist'),
        children: audioFiles.map((file) {
          final fileName = file.split('/').last;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, file),
            child: Text(fileName),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      try {
        await _audioPlayer.setAsset(selected);
        _audioPlayer.play();
        setState(() {
          _audioName = selected;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  // Compress the video if its size exceeds 20MB
  Future<File?> _compressVideo(File videoFile) async {
    try {
      final compressedVideo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality, // Adjust quality as needed
        deleteOrigin: false,
      );

      if (compressedVideo != null && compressedVideo.path != null) {
        return File(compressedVideo.path!); // Return the compressed file
      } else {
        throw "Video compression failed or compressed video has no path.";
      }
    } catch (e) {
      print("Compression error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('upload video'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _videoFile == null
                  ? Center(child: Text("No video selected"))
                  : Column(
                      children: [
                        Center(
                          child: Container(
                            height: 200,
                            width: 100,
                            child: _videoController == null ||
                                    !_videoController!.value.isInitialized
                                ? Center(child: CircularProgressIndicator())
                                : VideoPlayer(_videoController!),
                          ),
                        ),
                      ],
                    ),

              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _pickVideo,
                  child: Text("Select Video"),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _pickAudio,
                  child: Text("Select Audio"),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  _audioName == null ? "No audio selected" : "$_audioName",
                ),
              ),

              SizedBox(height: 20),
              Center(
                child: Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _isTermsAccepted = newValue!;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        "I agree to the Terms of Use",
                        style: TextStyle(color: Colors.pinkAccent),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Center(),
              SizedBox(height: 20),
              Text(
                'End User License Agreement',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.05,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '1. Ensure the video/image does not contain any offensive or inappropriate content.\n'
                '2. Do not upload videos/image that contain phone numbers, or any personal information.\n'
                '3. Avoid uploading videos/images that violate copyright laws.\n'
                '4. Ensure the video/image quality is clear and not overly pixelated.\n'
                '5. Videos/images should be related to your listing and relevant to the content.\n'
                '6. If your video/image exceeds 20MB, it will be compressed automatically.\n'
                '7. No tolerance for objectionable content (e.g. hate speech, nudity, abuse, fraud).\n'
                '8. Violations may result in content removal or account ban.\n'
                '9. Users are solely responsible for the content they upload, including ensuring they have the legal rights to any content included in their videos.',
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 30), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
