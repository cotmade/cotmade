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
import 'package:flutter_sound/flutter_sound.dart';
import 'package:cotmade/model/app_constants.dart';

class VideoUploadPage extends StatefulWidget {
  @override
  _VideoUploadPageState createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? _videoFile;
  String? _audioName; // Track selected audio name
  VideoPlayerController? _videoController; // Video controller
  String? _caption;
  bool _isUploading = false;
  bool _isTermsAccepted = false; // Track checkbox state
  String? _selectedPostingId; // To hold the selected posting ID
  List<Map<String, String>> _postings =
      []; // List to hold posting IDs and names
  bool _audioFinished = false;
  bool _isPlaying = false;
  FlutterSoundPlayer? _audioPlayer; // Audio player for preview

  @override
  void initState() {
    super.initState();
    _fetchUserPostings(); // Fetch the posting IDs associated with the current user
    _audioPlayer = FlutterSoundPlayer(); // Initialize audio player
  }

  @override
  void dispose() {
    _videoController?.dispose(); // Dispose video controller
    _audioPlayer?.stopPlayer(); // Dispose audio player
    super.dispose();
  }

  // Fetch posting IDs from the current user's document
  Future<void> _fetchUserPostings() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        // Fetch the user's document from the 'users' collection
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          // Fetch the posting IDs from the user's document
          List<dynamic> postingIDs = userDoc['myPostingIDs'] ?? [];

          // Query the 'postings' collection using the posting IDs
          List<Map<String, String>> postings = [];
          for (String postingId in postingIDs) {
            final postingDoc =
                await _firestore.collection('postings').doc(postingId).get();
            if (postingDoc.exists) {
              postings.add({
                'id': postingId, // Document ID (posting ID)
                'name': postingDoc[
                    'name'], // Assuming there's a 'name' field in the posting document
              });
            }
          }

          setState(() {
            _postings = postings; // Update the postings list
          });
        }
      } catch (e) {
        print("Error fetching postings: $e");
      }
    }
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

  // Pick an audio file from assets
  // Pick an audio file from assets with Play/Stop buttons
  Future<void> _pickAudio() async {
    // Let's assume you have an assets folder with audio files
    final audioFiles = [
      'cinematic-intro.mp3',
      'gospel-choir-heavenly.mp3',
      'prazkhanalmusic__chimera-afro-tim-clap-loop.wav'
    ]; // Example audio files in assets

    final selectedAudio = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Audio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: audioFiles.map((audio) {
              bool isPlaying = false; // Track play state for each audio

              return ListTile(
                title: Text(audio),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: () async {
                        // Stop any currently playing audio before starting the new one
                        if (_audioPlayer != null && _audioPlayer!.isPlaying) {
                          await _audioPlayer?.stopPlayer();
                          setState(() {
                            isPlaying = false; // Reset play state
                          });
                        }

                        if (isPlaying) {
                          // Pause the current audio if it's playing
                          await _audioPlayer?.pausePlayer();
                          setState(() {
                            isPlaying = false;
                          });
                        } else {
                          // Start the audio or resume from the paused state
                          await _audioPlayer?.startPlayer(
                            fromURI:
                                'assets/audio/$audio', // Assuming audio is in the assets folder
                            whenFinished: () {
                              setState(() {
                                isPlaying =
                                    false; // Reset when the audio finishes
                              });
                            },
                          );
                          setState(() {
                            isPlaying = true;
                          });
                        }
                      },
                    ),
                    if (isPlaying) // Only show the Stop button if the audio is playing
                      IconButton(
                        icon: Icon(Icons.stop),
                        onPressed: () async {
                          // Stop the audio
                          await _audioPlayer?.stopPlayer();
                          setState(() {
                            isPlaying = false; // Reset when stop is pressed
                          });
                        },
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(audio); // Return selected audio
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedAudio != null) {
      setState(() {
        _audioName = selectedAudio;
        _audioFinished = false; // Reset audio finish state
      });

      // Stop the previous audio player if any
      await _audioPlayer?.stopPlayer();

      // Start playing the selected audio for preview
      await _audioPlayer?.startPlayer(
        fromURI:
            'assets/audio/$selectedAudio', // Assuming audio is in the assets folder
        whenFinished: () {
          setState(() {
            _audioFinished = true; // Reset UI when audio finishes
          });
        },
      );
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

  // Upload video to Firebase Storage and store metadata in Firestore
  Future<void> _uploadVideo() async {
    if (_videoFile == null ||
        _caption == null ||
        _caption!.isEmpty ||
        _selectedPostingId == null ||
        !_isTermsAccepted) {
      // Ensure terms are accepted
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("Please accept the terms and conditions before uploading."),
      ));
      return; // Ensure there's a video, caption, and selected posting ID
    }

    // Set uploading state to true
    setState(() {
      _isUploading = true;
    });

    try {
      final videoSize = await _videoFile!.length();
      if (videoSize > 10 * 1024 * 1024) {
        // If video size > 20MB, compress the video
        File? compressedVideo = await _compressVideo(_videoFile!);
        if (compressedVideo == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Compression failed or video is too large.")),
          );
          return;
        }

        final compressedSize = await compressedVideo.length();
        if (compressedSize > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("Video size still exceeds 10MB after compression")),
          );
          return;
        }

        // Upload the compressed video
        await _uploadToStorage(compressedVideo);
      } else {
        // Upload the original video if compression is not needed
        await _uploadToStorage(_videoFile!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      // Reset the uploading state after upload is complete (success or failure)
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Upload the video to Firebase Storage and save metadata in Firestore
  Future<void> _uploadToStorage(File videoFile) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('reels/$fileName');
      final uploadTask = ref.putFile(videoFile);

      // Get the download URL after upload completes
      final snapshot = await uploadTask.whenComplete(() {});
      final videoUrl = await snapshot.ref.getDownloadURL();

      // Get user data
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
            code: "user-not-logged-in", message: "User is not logged in");
      }

      // Ensure non-null email and caption (use empty string if null)
      final email = user.email ?? ''; // Use empty string if email is null
      final caption = _caption ?? ''; // Use empty string if caption is null

      // Save video metadata in Firestore, including the selected posting ID
      await _firestore.collection('reels').add({
        'caption': caption, // Non-nullable string
        'email': email, // Non-nullable string
        'likes': 0,
        'postId': fileName,
        'audioName': _audioName, // Store the audio name
        'postingId': _selectedPostingId, // Store selected posting ID
        'reelsVideo': videoUrl,
        'time': Timestamp.now(),
        'uid': user.uid,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Video uploaded successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to upload video: $e")));
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
                        Container(
                          child: _videoController == null ||
                                  !_videoController!.value.isInitialized
                              ? Center(child: CircularProgressIndicator())
                              : AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
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
                child: _postings.isEmpty
                    ? CircularProgressIndicator()
                    : DropdownButton<String>(
                        hint: Text("Select Posting"),
                        value: _selectedPostingId,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPostingId = newValue;
                          });
                        },
                        items: _postings.map((posting) {
                          return DropdownMenuItem<String>(
                            value: posting['id'],
                            child: Text(posting['name']!),
                          );
                        }).toList(),
                      ),
              ),
              SizedBox(height: 20),
              TextField(
                onChanged: (value) {
                  _caption = value;
                },
                decoration: InputDecoration(hintText: 'Enter video caption'),
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
              Center(
                child: _isUploading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _uploadVideo,
                        child: Text("submit"),
                      ),
              ),
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
