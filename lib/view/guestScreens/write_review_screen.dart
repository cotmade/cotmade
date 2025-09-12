import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Import rating bar package

class WriteReviewScreen extends StatefulWidget {
  final String postingID; // Pass postingID to the screen

  WriteReviewScreen({Key? key, required this.postingID}) : super(key: key);

  @override
  _WriteReviewScreenState createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0; // To store the rating (stars)
  bool isLoading = false;

  // This will calculate the word count in the review text
  int get wordCount =>
      _reviewController.text.trim().split(RegExp(r'\s+')).length;

  _submitReview() async {
    // Get the review text and rating
    String review = _reviewController.text.trim();

    if (review.isEmpty || _rating == 0) {
      // Show error if review or rating is empty
      Get.snackbar("Error", "Review and Rating cannot be empty!");

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Prepare the new review data
      Map<String, dynamic> newReview = {
        'userID': AppConstants.currentUser.id,
        'review': review,
        'ratings': _rating,
        //  'timestamp':
        //      FieldValue.serverTimestamp(), // This should be part of the map
      };

      // Update the 'reviews' array in the 'postings' document
      await FirebaseFirestore.instance
          .collection('postings')
          .doc(widget.postingID) // Reference the specific posting document
          .update({
        'reviews': FieldValue.arrayUnion(
            [newReview]), // Add the new review to the array
      });

      setState(() {
        isLoading = false;
      });

      // Show success message and navigate back
      Get.snackbar("Success", "Review Submitted!");

      Navigator.pop(context); // Go back after successful submission
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      // Show error message if something goes wrong
      Get.snackbar("Invalid", "Failed to submit review");
    }
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
            // Review text field
            TextField(
              controller: _reviewController,
              maxLines: 5,
              textAlignVertical: TextAlignVertical.top, // Align text at the top
              decoration: InputDecoration(
                labelText: 'Tell us more',
                labelStyle: TextStyle(color: Colors.black), // Label color
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black), // Black border
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colors.black), // Black border on focus
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.black), // Black border when enabled
                ),
                hintText: 'Write your review here...',
                hintStyle: TextStyle(color: Colors.grey), // Placeholder style
                contentPadding: EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 10.0), // Adjust padding to make space for label
              ),
            ),
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
                          backgroundColor:
                              Colors.black, // Background color of the button
                        ),
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 22.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),

            SizedBox(height: 20),
            // Smiley Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sentiment_very_satisfied,
                  color: Colors.green,
                  size: 40,
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.sentiment_neutral,
                  color: Colors.orange,
                  size: 40,
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.sentiment_dissatisfied,
                  color: Colors.red,
                  size: 40,
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.sentiment_very_dissatisfied,
                  color: Colors.purple,
                  size: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}