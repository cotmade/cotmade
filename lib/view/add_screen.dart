import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart'; // For Get.snackbar

class AddScreen extends StatefulWidget {
  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _videoFile;
  bool _isUploading = false;

  // Pick a video file and compress it if necessary
  Future<void> _pickAndProcessVideo() async {
    // Request permissions for iOS and Android
    if (await Permission.storage.request().isGranted) {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _videoFile = File(result.files.single.path!);
        });

        // Compress the video after selection
        await _compressVideo();

        // Upload the video after compression
        await _uploadVideo();
      }
    } else {
      Fluttertoast.showToast(msg: "Storage permission required");
    }
  }

  // Compress the video using the video_compress package
  Future<void> _compressVideo() async {
    if (_videoFile == null) return;

    final filePath = _videoFile!.path;
    final fileSize = await _videoFile!.length();
    final maxSize = 20 * 1024 * 1024; // 20 MB max size

    // Compress if the file exceeds the max size
    if (fileSize > maxSize) {
      // Use video_compress to compress the video
      final compressedVideo = await VideoCompress.compressVideo(
        filePath,
        quality: VideoQuality
            .MediumQuality, // You can set to LowQuality or HighQuality
        deleteOrigin: false, // Keep the original file or not
      );

      if (compressedVideo != null) {
        setState(() {
          _videoFile = File(compressedVideo.path!);
        });
        Fluttertoast.showToast(msg: "Video compressed");
      }
    }
  }

  // Upload the compressed video to Firebase Storage and save metadata to Firestore
  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;

    setState(() {
      _isUploading = true;
    });

    // Upload video to Firebase Storage
    try {
      final fileName = basename(_videoFile!.path);
      final ref = _storage.ref().child('reels/$fileName');
      final uploadTask = ref.putFile(_videoFile!);
      final taskSnapshot = await uploadTask.whenComplete(() {});

      final videoUrl = await taskSnapshot.ref.getDownloadURL();

      // Save metadata in Firestore
      final user = FirebaseAuth.instance.currentUser!;
      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      final time = Timestamp.now();

      await _firestore.collection('reels').add({
        'caption': "Sample Caption",
        'firstName': user.displayName ?? "Anonymous",
        'postId': postId,
        'reelsVideo': videoUrl,
        'time': time,
        'uid': user.uid,
      });

      // Show success snackbar
      Get.snackbar(
        "Success",
        "Video uploaded successfully!",
        backgroundColor: Color(0xcaf6f6f6),
        colorText: Colors.black,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      // Show error snackbar
      Get.snackbar(
        "Error",
        "Failed to upload video: $e",
        backgroundColor: Color(0xcaf6f6f6),
        colorText: Colors.black,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Video")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _videoFile == null
                ? Text("No video selected")
                : Text("Selected video: ${basename(_videoFile!.path)}"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _pickAndProcessVideo,
              child: _isUploading
                  ? CircularProgressIndicator()
                  : Text("Pick and Upload Video"),
            ),
          ],
        ),
      ),
    );
  }
}
