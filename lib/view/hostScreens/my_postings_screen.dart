import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/view/hostScreens/create_posting_screen.dart';
import 'package:cotmade/view/widgets/posting_list_tile_button.dart';
import 'package:cotmade/view/widgets/posting_list_tile_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/hostScreens/postings_manager.dart';

class MyPostingsScreen extends StatefulWidget {
  const MyPostingsScreen({super.key});

  @override
  State<MyPostingsScreen> createState() => _MyPostingsScreenState();
}

class _MyPostingsScreenState extends State<MyPostingsScreen> {
  List<PostingModel> _postings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Check if postings are already loaded in the PostingsManager
    if (PostingsManager().postings.isEmpty) {
      _loadPostings(); // Only load if postings are not already loaded
    } else {
      // Use existing postings if they are already loaded in memory
      setState(() {
        _postings = PostingsManager().postings;
        _isLoading = false;
      });
    }
  }

  // Function to load postings from PostingsManager if not already loaded
  Future<void> _loadPostings() async {
    await PostingsManager().initializeUser(); // Ensure the user is initialized
    await PostingsManager()
        .initializePostings(); // Fetch the postings for the current user
    await PostingsManager()
        .startPostingsListener(); // Start the listener for real-time updates

    setState(() {
      _postings = PostingsManager().postings; // Now we have the postings
      _isLoading = false; // Stop showing the loading spinner
    });
  }

  @override
  void dispose() {
    PostingsManager()
        .stopPostingsListener(); // Stop the listener when the screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter postings with status 0.0 (suspended or inactive) out
    var filteredPostings = AppConstants.currentUser.myPostings!
        .where((posting) =>
            posting.status != 0) // Only show postings with status != 0.0
        .toList();

    // Remove duplicates based on posting ID
    var uniquePostings = <PostingModel>[];
    var seenIds = <String>{}; // Set to track seen posting IDs

    for (var posting in filteredPostings) {
      if (!seenIds.contains(posting.id)) {
        seenIds.add(posting
            .id!); // Add ID to seen set (using null assertion if not null)
        uniquePostings.add(posting); // Add posting to unique list
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: ListView.builder(
        itemCount: uniquePostings.length +
            1, // Add one for the "Create Posting" button
        itemBuilder: (context, index) {
          // If index is 0, display the "Create Posting" button
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
              child: InkResponse(
                onTap: () {
                  // Navigate to Create Posting screen
                  Get.to(CreatePostingScreen(posting: null));
                },
                child: Container(
                  width: 190,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black,
                  ),
                  child: PostingListTileButton(), // Create button
                ),
              ),
            );
          }

          // For other indices, show the filtered postings
          // Since index 0 is for the Create Posting button, use index - 1 for postings
          return Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator()) // Show loading spinner when loading
                : InkResponse(
                    onTap: () {
                      // Navigate to Create Posting screen with the selected posting
                      Get.to(CreatePostingScreen(
                        posting: uniquePostings[
                            index - 1], // Adjust index for the postings
                      ));
                    },
                    child: Container(
                      width: 190,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black,
                      ),
                      child: PostingListTileUI(
                        posting: uniquePostings[
                            index - 1], // Adjust index for the postings
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
