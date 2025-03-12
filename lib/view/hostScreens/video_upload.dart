import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_compress/video_compress.dart';

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
  String? _caption;
  bool _isUploading = false;

  // Pick a video from the gallery
  Future<void> _pickVideo() async {
    final XFile? pickedFile =
        await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
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
    if (_videoFile == null || _caption == null || _caption!.isEmpty) {
      return; // Ensure there's a video and caption
    }

    // Set uploading state to true
    setState(() {
      _isUploading = true;
    });

    try {
      final videoSize = await _videoFile!.length();
      if (videoSize > 20 * 1024 * 1024) {
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
        if (compressedSize > 20 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("Video size still exceeds 20MB after compression")),
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

      // Save video metadata in Firestore
      await _firestore.collection('reels').add({
        'caption': caption, // Non-nullable string
        'email': email, // Non-nullable string
        'likes': 0,
        'postId': fileName,
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Video'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _videoFile == null
                ? Text("No video selected")
                : Text("Selected video: ${_videoFile!.path.split('/').last}"),
            SizedBox(height: 20),
            TextField(
              onChanged: (value) {
                _caption = value;
              },
              decoration: InputDecoration(hintText: 'Enter video caption'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text("Select Video"),
            ),
            SizedBox(height: 20),
            _isUploading
                ? Center(
                    child:
                        CircularProgressIndicator()) // Show the circular progress indicator
                : ElevatedButton(
                    onPressed: _uploadVideo,
                    child: Text("Upload Video"),
                  ),
          ],
        ),
      ),
    );
  }
}
