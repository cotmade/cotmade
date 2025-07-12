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
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

class VideoUploadPage extends StatefulWidget {
  @override
  _VideoUploadPageState createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? _videoFile;
  String? _audioName; //  selected audio name
  VideoPlayerController? _videoController; // Video controller
  String? _caption;
  bool _isUploading = false;
  bool _isTermsAccepted = false; // Track checkbox state
  String? _selectedPostingId; // To hold the selected posting ID
  List<Map<String, String>> _postings =
      []; // List to hold posting IDs and names
  bool _audioFinished = false;
  bool _isPlaying = false; // Audio player for preview

  @override
  void initState() {
    super.initState();
    _fetchUserPostings(); // Initialize audio player
  }

  @override
  void dispose() {
    _videoController?.dispose(); // Dispose video controller
    _audioPlayer.dispose(); // Dispose audio player
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

  final List<String> audioFiles = [
    'images/cinematic-intro.mp3',
    'images/gospel-choir-heavenly.mp3',
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
          _audioName = selected.split('/').last;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('cannot select audio at this time: kindly proceed with your submission')),
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
      final audioName = _audioName ?? ''; // Use empty string if caption is null

      // Save video metadata in Firestore, including the selected posting ID
      await _firestore.collection('reels').add({
        'caption': caption, // Non-nullable string
        'email': email, // Non-nullable string
        'likes': 0,
        'premium': 1,
        'postId': fileName,
        'audioName': audioName, // Store the audio name
        'postingId': _selectedPostingId, // Store selected posting ID
        'reelsVideo': videoUrl,
        'views': 0,
        'time': Timestamp.now(),
        'uid': user.uid,
      });

       await sendWelcomeEmail(
          AppConstants.currentUser.email.toString(),
          AppConstants.currentUser.getFullNameOfUser(),
          audioName,
          fileName,
          videoUrl,
          caption,
          _selectedPostingId);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Video uploaded successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to upload video: $e")));
    }
  }

  Future<void> sendWelcomeEmail(String email, String fname, String audioName,
      String fileName, String videoUrl, String caption, _selectedPostingId) async {
    final url = Uri.parse("https://cotmade.com/app/send_email_videopost.php");

    final response = await http.post(url, body: {
      "email": email,
      "fname": fname,
      "music_name": audioName,
      "userID": fileName,
      "url": videoUrl,
      "caption": caption,
      "postingID": _selectedPostingId,
    });

    if (response.statusCode == 200) {
      print("Email sent successfully");
    } else {
      print("Failed to send email: ${response.body}");
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
              Text('1. Uploading videos is only permitted after a property listing has been created and submitted.\n'
                '2. Ensure the video/image does not contain any offensive or inappropriate content.\n'
                '3. Do not upload videos/image that contain phone numbers, or any personal information.\n'
                '4. Avoid uploading videos/images that violate copyright laws.\n'
                '5. Ensure the video/image quality is clear and not overly pixelated.\n'
                '6. Videos/images should be related to your listing and relevant to the content.\n'
                '7. If your video/image exceeds 20MB, it will be compressed automatically.\n'
                '8. No tolerance for objectionable content (e.g. hate speech, nudity, abuse, fraud).\n'
                '9. Violations may result in content removal or account ban.\n'
                '10. Users are solely responsible for the content they upload, including ensuring they have the legal rights to any content included in their videos.',
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
