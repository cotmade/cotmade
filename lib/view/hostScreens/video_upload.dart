import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

// Stubs (safe for Web)
import '../../stubs/video_compress_stub.dart';
import '../../stubs/flutter_sound_stub.dart';

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

  XFile? _videoFile;
  String? _audioName;
  VideoPlayerController? _videoController;
  String? _caption;
  bool _isUploading = false;
  bool _isTermsAccepted = false;
  String? _selectedPostingId;
  List<Map<String, String>> _postings = [];

  @override
  void initState() {
    super.initState();
    _fetchUserPostings();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchUserPostings() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          List<dynamic> postingIDs = userDoc['myPostingIDs'] ?? [];

          List<Map<String, String>> postings = [];
          for (String postingId in postingIDs) {
            final postingDoc =
                await _firestore.collection('postings').doc(postingId).get();
            if (postingDoc.exists) {
              postings.add({
                'id': postingId,
                'name': postingDoc['name'],
              });
            }
          }

          setState(() {
            _postings = postings;
          });
        }
      } catch (e) {
        print("Error fetching postings: $e");
      }
    }
  }

  Future<void> _pickVideo() async {
    final XFile? pickedFile =
        await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = pickedFile;
        _videoController = VideoPlayerController.network(pickedFile.path)
          ..initialize().then((_) {
            setState(() {});
          });
      });
    }
  }

  Future<void> _pickAudio() async {
    final audioFiles = [
      'cinematic-intro.mp3',
      'gospel-choir-heavenly.mp3',
      'prazkhanalmusic__chimera-afro-tim-clap-loop.wav'
    ];

    final selectedAudio = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Select Audio'),
          children: audioFiles.map((audio) {
            return SimpleDialogOption(
              child: Text(audio),
              onPressed: () async {
                Navigator.of(context).pop(audio);

                try {
                  await _audioPlayer.setAsset('assets/audio/$audio');
                  await _audioPlayer.play();
                } catch (e) {
                  print("Audio play error: $e");
                }
              },
            );
          }).toList(),
        );
      },
    );

    if (selectedAudio != null) {
      setState(() {
        _audioName = selectedAudio;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null ||
        _caption == null ||
        _caption!.isEmpty ||
        _selectedPostingId == null ||
        !_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("Please complete all fields and accept terms before upload."),
      ));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // ✅ No compression on web, upload directly
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('reels/$fileName');
      final uploadTask = ref.putData(await _videoFile!.readAsBytes());

      final snapshot = await uploadTask.whenComplete(() {});
      final videoUrl = await snapshot.ref.getDownloadURL();

      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final email = user.email ?? '';
      final caption = _caption ?? '';
      final audioName = _audioName ?? '';

      await _firestore.collection('reels').add({
        'caption': caption,
        'email': email,
        'likes': 0,
        'premium': 1,
        'postId': fileName,
        'audioName': audioName,
        'postingId': _selectedPostingId,
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
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> sendWelcomeEmail(
      String email,
      String fname,
      String audioName,
      String fileName,
      String videoUrl,
      String caption,
      String? postingId) async {
    final url = Uri.parse("https://cotmade.com/app/send_email_videopost.php");

    final response = await http.post(url, body: {
      "email": email,
      "fname": fname,
      "music_name": audioName,
      "userID": fileName,
      "url": videoUrl,
      "caption": caption,
      "postingID": postingId ?? "",
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
      appBar: AppBar(title: Text('Upload Video')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _videoFile == null
                ? Text("No video selected")
                : Container(
                    height: 200,
                    width: 200,
                    child: _videoController == null ||
                            !_videoController!.value.isInitialized
                        ? CircularProgressIndicator()
                        : VideoPlayer(_videoController!),
                  ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _pickVideo, child: Text("Select Video")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _pickAudio, child: Text("Select Audio")),
            SizedBox(height: 10),
            Text(_audioName ?? "No audio selected"),
            SizedBox(height: 20),
            _postings.isEmpty
                ? CircularProgressIndicator()
                : DropdownButton<String>(
                    hint: Text("Select Posting"),
                    value: _selectedPostingId,
                    onChanged: (newValue) {
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
            SizedBox(height: 20),
            TextField(
              onChanged: (value) => _caption = value,
              decoration: InputDecoration(hintText: 'Enter caption'),
            ),
            Row(
              children: [
                Checkbox(
                  value: _isTermsAccepted,
                  onChanged: (bool? v) =>
                      setState(() => _isTermsAccepted = v ?? false),
                ),
                Expanded(
                    child: Text("I agree to the Terms of Use",
                        style: TextStyle(color: Colors.pinkAccent))),
              ],
            ),
            SizedBox(height: 20),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _uploadVideo, child: Text("Submit")),
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
              '1. Uploading videos is only permitted after a property listing has been created and submitted.\n'
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
    );
  }
}
