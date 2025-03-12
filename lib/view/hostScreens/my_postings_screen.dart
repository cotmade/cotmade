import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/view/hostScreens/create_posting_screen.dart';
import 'package:cotmade/view/widgets/posting_list_tile_button.dart';
import 'package:cotmade/view/widgets/posting_list_tile_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyPostingsScreen extends StatefulWidget {
  const MyPostingsScreen({super.key});

  @override
  State<MyPostingsScreen> createState() => _MyPostingsScreenState();
}

class _MyPostingsScreenState extends State<MyPostingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: ListView.builder(
        itemCount: AppConstants.currentUser.myPostings!.length + 1,
        itemBuilder: (context, index) {
          // Check if we are on the first item (the button to create a new posting)
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
                      color: Colors.black),
                  child: PostingListTileButton(), // This button comes first
                ),
              ),
            );
          }

          // For other indices, show the postings
          return Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
            child: InkResponse(
              onTap: () {
                // Navigate to Create Posting screen with selected posting
                Get.to(CreatePostingScreen(
                  posting: AppConstants.currentUser.myPostings![index -
                      1], // Account for the first index being the button
                ));
              },
              child: Container(
                width: 190,
                height: 70,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black),
                child: PostingListTileUI(
                  posting: AppConstants.currentUser
                      .myPostings![index - 1], // Adjust index for the postings
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
