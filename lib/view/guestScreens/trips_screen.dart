import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/data/firestor.dart';
import 'package:cotmade/view/guest_home_screen.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:cotmade/view/widgets/posting_grid_tile_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cotmade/view/widgets/trips_grid_tile_ui.dart';
import 'package:cotmade/view/widgets/trips_grid_tile_ui.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/view_model/user_view_model.dart';

class TripsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        // Second StreamBuilder: Listen to posts for the specific user
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(AppConstants.currentUser.id)
            .collection('bookings')
            .snapshots(),
        builder: (context, postSnapshot) {
          if (postSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (postSnapshot.hasError) {
            return Center(child: Text("Error: ${postSnapshot.error}"));
          }

          if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
            return Center(child: Text("No booked trips found for you"));
          }

          var posts = postSnapshot.data!.docs;

          return Column(
            children: posts.map<Widget>((post) {
              // var postId = post.id;
              var postingID = post['postingID'];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Card(
                  color: Color(0xcaf6f6f6),
                  shadowColor: Colors.black12,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(postingID,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        StreamBuilder<QuerySnapshot>(
                          // Third StreamBuilder: Listen to comments for this post
                          stream: FirebaseFirestore.instance
                              .collection('postings')
                              .where(postingID, isEqualTo: postingID)
                              .snapshots(),
                          builder: (context, commentSnapshot) {
                            if (commentSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (commentSnapshot.hasError) {
                              return Center(
                                  child:
                                      Text("Error: ${commentSnapshot.error}"));
                            }

                            if (!commentSnapshot.hasData ||
                                commentSnapshot.data!.docs.isEmpty) {
                              return Text("No comments on this post.");
                            }

                            var comments = commentSnapshot.data!.docs;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: comments.map<Widget>((comment) {
                                // Retrieve the 'bookings' subcollection for each post
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('postings')
                                      .doc(comment
                                          .id) // Use the document ID to access the subcollection
                                      .collection('bookings')
                                      .where('userID',
                                          isEqualTo: AppConstants.currentUser
                                              .id) // Filter by userID
                                      .snapshots(),
                                  builder: (context, bookingSnapshot) {
                                    if (bookingSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }
                                    if (bookingSnapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              "Error: ${bookingSnapshot.error}"));
                                    }

                                    var bookings =
                                        bookingSnapshot.data?.docs ?? [];

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              SizedBox(width: 8),
                                              Text(comment['description']),
                                              SizedBox(width: 8),
                                              Text(comment['type']),
                                              SizedBox(width: 8),
                                              Text(comment['address']),
                                              SizedBox(width: 8),
                                              Text(comment['city']),
                                              SizedBox(width: 8),
                                              Text(comment['country']),
                                            ],
                                          ),
                                          if (bookings.isNotEmpty) ...[
                                            SizedBox(height: 8),
                                            Text('Booking Info:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            for (var booking in bookings)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4.0),
                                                child: Row(
                                                  children: [
                                                    SizedBox(width: 8),
                                                    Text(
                                                        'Booking ID: ${comment.id}'),
                                                    Text(
                                                        'Date(s): ${booking['dates']}'),
                                                    SizedBox(width: 8),
                                                    Text(
                                                        'Payment: ${booking['payment']}'),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
