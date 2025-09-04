import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';

class WriteReviewScreen extends StatefulWidget {
  final String postingID; // Pass postingID to the screen
  final bool isVideoReview; // Flag to indicate if it's a video review

  WriteReviewScreen(
      {Key? key, required this.postingID, required this.isVideoReview})
      : super(key: key);

  @override
  _WriteReviewScreenState createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0; // To store the rating (stars)
  bool isLoading = false;

  File? _videoFile;
  VideoPlayerController? _videoController;
  String? _videoUrl;

  // This will calculate the word count in the review text
  int get wordCount =>
      _reviewController.text.trim().split(RegExp(r'\s+')).length;

  _submitReview() async {
    String review = _reviewController.text.trim();

    if (!widget.isVideoReview && (review.isEmpty || _rating == 0)) {
      // Show error if review or rating is empty
      Get.snackbar("Error", "Review and Rating cannot be empty!");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // If it's a video review, compress and upload the video
      if (widget.isVideoReview && _videoFile != null) {
        File? compressedVideo = await _compressVideo(_videoFile!);

        if (compressedVideo != null) {
          _videoUrl = await _uploadVideo(compressedVideo);
        }
      }

      // Prepare the new review data
      Map<String, dynamic> newReview = {
        'userID': AppConstants.currentUser.id,
        'review': review,
        'ratings': _rating,
        'videoUrl': _videoUrl, // Add video URL if uploaded
      };

      // Update the 'reviews' array in the 'postings' document
      await FirebaseFirestore.instance
          .collection('postings')
          .doc(widget.postingID)
          .update({
        'reviews': FieldValue.arrayUnion([newReview]),
      });

      setState(() {
        isLoading = false;
      });

      Get.snackbar("Success", "Review Submitted!");

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.snackbar("Error", "Failed to submit review");
    }
  }

  Future<File?> _compressVideo(File videoFile) async {
    try {
      final MediaInfo? info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false, // Retain original video file
        includeAudio: true,
        frameRate: 24,
      );

      if (info != null) {
        File compressedFile = File(info.path!);
        int fileSize = await compressedFile.length();

        if (fileSize <= 10 * 1024 * 1024) {
          // Check if compressed file is under 10MB
          return compressedFile;
        } else {
          Get.snackbar(
              "Error", "Video size exceeds 10MB even after compression.");
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print("Error compressing video: $e");
      return null;
    }
  }

  Future<String?> _uploadVideo(File videoFile) async {
    try {
      String videoPath = 'reviews/${DateTime.now().millisecondsSinceEpoch}.mp4';

      Reference storageRef = FirebaseStorage.instance.ref().child(videoPath);
      UploadTask uploadTask = storageRef.putFile(videoFile);

      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      String videoUrl = await snapshot.ref.getDownloadURL();

      return videoUrl;
    } catch (e) {
      print("Error uploading video: $e");
      return null;
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      setState(() {
        _videoFile = File(video.path);
      });

      _videoController = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // If it's not a video review, show the rating section
            if (!widget.isVideoReview) ...[
              Text('Tap to rate',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              SizedBox(height: 20),
              // Center the RatingBar
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  itemSize: 40,
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: Colors.pinkAccent,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
              ),
              SizedBox(height: 20),
              // Text Review Section
              TextField(
                controller: _reviewController,
                maxLines: 5,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'Tell us more',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  hintText: 'Write your review here...',
                  hintStyle: TextStyle(color: Colors.grey),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
                ),
              ),
              SizedBox(height: 20),
              // Smiley Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_very_satisfied,
                      color: Colors.green, size: 40),
                  SizedBox(width: 10),
                  Icon(Icons.sentiment_neutral, color: Colors.orange, size: 40),
                  SizedBox(width: 10),
                  Icon(Icons.sentiment_dissatisfied,
                      color: Colors.red, size: 40),
                  SizedBox(width: 10),
                  Icon(Icons.sentiment_very_dissatisfied,
                      color: Colors.purple, size: 40),
                ],
              ),
            ],
            // Video Review Section
            if (widget.isVideoReview) ...[
              // Preview video in a well-sized container
              if (_videoFile != null)
                Center(
                  child: Container(
                    height: 200,
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black,
                    ),
                    child: _videoController != null &&
                            _videoController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : Center(child: CircularProgressIndicator()),
                  ),
                ),
              SizedBox(height: 20),
              // Center the "Pick Video" button
              Center(
                child: ElevatedButton(
                  onPressed: _pickVideo,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Pick Video',
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
              ),
            ],
            SizedBox(height: 20),
            // Submit button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                width: 360,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitReview,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black),
                        child: Text(
                          "Submit",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 22.0,
                              color: Colors.white),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
