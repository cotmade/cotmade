import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/model/app_constants.dart';
import 'dart:async';

class PostingsManager {
  static final PostingsManager _instance = PostingsManager._internal();
  List<PostingModel> _postings = [];
  User? _currentUser;
  late StreamSubscription<QuerySnapshot> _postingsSubscription;

  List<PostingModel> get postings => _postings;

  PostingsManager._internal(); // Singleton pattern

  factory PostingsManager() {
    return _instance;
  }

  // Initialize the current user
  Future<void> initializeUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  // Listen to changes in the postings collection
  Future<void> startPostingsListener() async {
    if (_currentUser == null) {
      return; // No user logged in, exit early
    }

    // Listen for changes in the 'postings' collection where hostID matches the current user's UID
    _postingsSubscription = FirebaseFirestore.instance
        .collection('postings')
        .where('hostID', isEqualTo: _currentUser!.uid)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      // Handle changes in the postings data
      _handlePostingsChanges(snapshot);
    });
  }

  // Handle incoming changes to the postings collection
  void _handlePostingsChanges(QuerySnapshot snapshot) {
    // Create a list of PostingModel objects from the snapshot
    List<PostingModel> updatedPostings = [];

    for (var doc in snapshot.docs) {
      PostingModel posting = PostingModel(id: doc.id);
      updatedPostings.add(posting);
    }

    // Compare the old postings with the new postings and update the list
    // You can choose to merge, remove or add postings as needed
    _syncPostings(updatedPostings);
  }

  // Sync the local list of postings with the new data
  void _syncPostings(List<PostingModel> updatedPostings) {
    // First, remove postings that no longer exist in the snapshot
    _postings.removeWhere((existingPosting) => !updatedPostings
        .any((newPosting) => newPosting.id == existingPosting.id));

    // Add new postings that don't exist in the local list
    for (var updatedPosting in updatedPostings) {
      if (!_postings
          .any((existingPosting) => existingPosting.id == updatedPosting.id)) {
        _postings.add(updatedPosting);
      }
    }

    // Fetch full details and images for each updated posting
    _fetchPostingDetails();
  }

  // Fetch the full details and images for all postings
  Future<void> _fetchPostingDetails() async {
    for (var posting in _postings) {
      await posting.getPostingInfoFromFirestore();
      await posting.getAllImagesFromStorage();
    }
  }

  // Initialize the postings for the current user (can be called initially or when necessary)
  Future<void> initializePostings() async {
    if (_currentUser == null) {
      return; // No user logged in, exit early
    }

    // Query postings that belong to the current user
    QuerySnapshot postingsSnapshot = await FirebaseFirestore.instance
        .collection('postings')
        .where('hostID', isEqualTo: _currentUser!.uid)
        .get();

    for (var doc in postingsSnapshot.docs) {
      PostingModel posting = PostingModel(id: doc.id);
      await posting.getPostingInfoFromFirestore();
      await posting.getAllImagesFromStorage();
      _postings.add(posting);
    }
  }

  // Stop the listener when it's no longer needed (for example, when the user logs out)
  void stopPostingsListener() {
    _postingsSubscription.cancel();
  }
}
