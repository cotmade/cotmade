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
            child: InkResponse(
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
