import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:cotmade/view/widgets/posting_grid_tile_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserProfilePage extends StatefulWidget {
  final String uid;

  const UserProfilePage({required this.uid});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late String uid;
  late Stream stream;
  String? firstName;
  String? lastName;
  String? bio;
  MemoryImage? displayImage;

  @override
  void initState() {
    super.initState();
    uid = widget.uid; // Store the uid passed to this widget

    // Fetch postings from Firestore where the hostID equals the passed uid
    stream = FirebaseFirestore.instance
        .collection('postings')
        .where('hostID', isEqualTo: uid)
        .where('status', isEqualTo: 1) // Only fetch posts where status >= 1
        .snapshots();

    // Fetch user info and profile image
    getUserInfoFromFirestore(uid);
    getImageFromStorage(uid);
  }

  // Function to get user info from Firestore
  getUserInfoFromFirestore(uid) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    setState(() {
      firstName = snapshot["firstName"] ?? "";
      lastName = snapshot['lastName'] ?? "";
      bio = snapshot['bio'] ?? "";
    });
  }

  // Function to get image from Firebase Storage
  getImageFromStorage(uid) async {
    try {
      final imageDataInBytes = await FirebaseStorage.instance
          .ref()
          .child("userImages")
          .child(uid)
          .child(uid + ".png")
          .getData(1024 * 1024);

      setState(() {
        displayImage = MemoryImage(imageDataInBytes!);
      });
    } catch (e) {
      print("Error fetching image: $e");
      // Handle error: You might want to show a default image or leave it null
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
              ],
              begin: FractionalOffset(0, 0),
              end: FractionalOffset(1, 0),
              stops: [0, 1],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "My Listings",
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 15, 20, 0),
          child: SingleChildScrollView(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  SizedBox(
                    height: 15,
                  ),
                  // Profile image (ensure displayImage is not null before showing)
                  MaterialButton(
                    onPressed: () {
                      if (displayImage != null) {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierColor:
                              Colors.black.withOpacity(0.9), // Dark background
                          transitionDuration: Duration(milliseconds: 200),
                          pageBuilder: (_, __, ___) {
                            return GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pop(), // Tap to dismiss
                              child: Scaffold(
                                backgroundColor: Colors.transparent,
                                body: Center(
                                  child: InteractiveViewer(
                                    panEnabled: true,
                                    minScale: 1.0,
                                    maxScale: 4.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: displayImage!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: 50,
                      child: displayImage != null
                          ? CircleAvatar(
                              backgroundImage: displayImage,
                              radius: 49,
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 50,
                              color: Colors.white,
                            ),
                    ),
                  ),

                  SizedBox(height: 20),
                  // User name and bio
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              firstName ?? '...loading',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              lastName ?? '...loading',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'About Me:',
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Flexible(
                                // Allows text to wrap while avoiding overflow
                                child: Text(
                              bio ?? 'Bio not available',
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  // Display listings
                  StreamBuilder(
                    stream: stream,
                    builder: (context, dataSnapshots) {
                      if (dataSnapshots.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                            strokeWidth: 5,
                          ),
                        );
                      }

                      if (dataSnapshots.hasError) {
                        return Center(
                          child: Text('Error: ${dataSnapshots.error}'),
                        );
                      }

                      if (!dataSnapshots.hasData ||
                          dataSnapshots.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("No listings available."),
                        );
                      }

                      return GridView.builder(
                        physics: const ScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: dataSnapshots.data!.docs.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 15,
                          childAspectRatio: 3 / 4,
                        ),
                        itemBuilder: (context, index) {
                          DocumentSnapshot snapshot =
                              dataSnapshots.data!.docs[index];

                          PostingModel cPosting = PostingModel(id: snapshot.id);
                          cPosting.getPostingInfoFromSnapshot(snapshot);

                          return InkResponse(
                            onTap: () {
                              Get.to(ViewPostingScreen(
                                posting: cPosting,
                              ));
                            },
                            enableFeedback: true,
                            child: PostingGridTileUI(
                              posting: cPosting,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
