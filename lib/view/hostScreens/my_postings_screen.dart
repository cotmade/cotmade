import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/view/hostScreens/create_posting_screen.dart';
import 'package:cotmade/view/widgets/posting_list_tile_button.dart';
import 'package:cotmade/view/widgets/posting_list_tile_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/model/posting_model.dart';

class MyPostingsScreen extends StatefulWidget {
  const MyPostingsScreen({super.key});

  @override
  State<MyPostingsScreen> createState() => _MyPostingsScreenState();
}

class _MyPostingsScreenState extends State<MyPostingsScreen> {
  List<PostingModel> _postings = []; // List to hold the actual postings
  Map<String, bool> _loadingStatus = {}; // Map to track loading state of each posting

  @override
  void initState() {
    super.initState();
    _loadPostings();
  }

  Future<void> _loadPostings() async {
    var filteredPostings = AppConstants.currentUser.myPostings!
        .where((posting) =>
            posting.status != 0) // Only show postings with status != 0.0
        .toList();

    // Remove duplicates based on posting ID
    var uniquePostings = <PostingModel>[];
    var seenIds = <String>{};

    for (var posting in filteredPostings) {
      if (!seenIds.contains(posting.id)) {
        seenIds.add(posting.id!);
        uniquePostings.add(posting);
      }
    }

    // Load postings asynchronously, showing them one by one
    for (var posting in uniquePostings) {
      _loadingStatus[posting.id!] = true; // Mark as loading
      await posting.getPostingInfoFromFirestore();
      await posting.getAllImagesFromStorage();
      setState(() {
        _postings.add(posting); // Add posting once it's loaded
        _loadingStatus[posting.id!] = false; // Mark as not loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: ListView.builder(
        itemCount: _postings.length + 1, // Add one for the "Create Posting" button
        itemBuilder: (context, index) {
          // If index is 0, display the "Create Posting" button
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
              child: InkResponse(
                onTap: () {
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
          var posting = _postings[index - 1]; // Adjust index for the postings
          bool isLoading = _loadingStatus[posting.id!] ?? false;

          return Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
            child: InkResponse(
              onTap: () {
                Get.to(CreatePostingScreen(posting: posting));
              },
              child: Container(
                width: 190,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black,
                ),
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(), // Show progress indicator while loading
                      )
                    : PostingListTileUI(posting: posting), // Show actual posting when ready
              ),
            ),
          );
        },
      ),
    );
  }
}
