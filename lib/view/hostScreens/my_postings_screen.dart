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
  late List<PostingModel> _postings;

  @override
  void initState() {
    super.initState();
    _postings = AppConstants.currentUser.myPostings!
        .where((posting) =>
            posting.status != 0) // Only show postings with status != 0.0
        .toList();
  }

  Future<void> _loadPostingsData(PostingModel posting) async {
    await posting.getPostingInfoFromFirestore();
    await posting.getAllImagesFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: ListView.builder(
        itemCount:
            _postings.length + 1, // Add one for the "Create Posting" button
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

          var posting = _postings[index - 1]; // Adjust index for the postings

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
                child: FutureBuilder(
                  future: _loadPostingsData(posting),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child:
                            CircularProgressIndicator(), // Show loading indicator
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading posting',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    } else {
                      // Once data is loaded, display the actual UI
                      return PostingListTileUI(posting: posting);
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
