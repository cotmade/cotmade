import 'package:cotmade/model/contact_model.dart';
import 'package:cotmade/model/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'app_constants.dart';

class ConversationModel {
  String? id;
  ContactModel? otherContact;
  List<MessageModel>? messages;
  MessageModel? lastMessage;

  ConversationModel() {
    messages = [];
  }

  // Create a new conversation in Firestore
  addConversationToFirestore(ContactModel otherContact) async {
    List<String> userNames = [
      AppConstants.currentUser.getFullNameOfUser(),
      otherContact.getFullNameOfUser(),
    ];

    List<String> userIDs = [
      AppConstants.currentUser.id!,
      otherContact.id!,
    ];

    Map<String, dynamic> conversationDataMap = {
      'lastMessageDateTime': DateTime.now(),
      'lastMessageText': "",
      'userNames': userNames,
      'userIDs': userIDs,
    };

    DocumentReference reference = await FirebaseFirestore.instance
        .collection('conversations')
        .add(conversationDataMap);
    id = reference.id;
  }

  // Add a message to Firestore conversation + send push notification via PHP backend
  addMessageToFirestore(String messageText) async {
    // Step 1: Save message in Firestore
    Map<String, dynamic> messageData = {
      'dateTime': DateTime.now(),
      'senderID': AppConstants.currentUser.id,
      'text': messageText
    };

    await FirebaseFirestore.instance
        .collection('conversations/$id/messages')
        .add(messageData);

    // Step 2: Update conversation metadata
    Map<String, dynamic> conversationData = {
      'lastMessageDateTime': DateTime.now(),
      'lastMessageText': messageText
    };

    await FirebaseFirestore.instance
        .doc('conversations/$id')
        .update(conversationData);

    // Step 3: Fetch recipient FCM token from Firestore
    if (otherContact?.id != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherContact!.id)
            .get();

        String? fcmToken = userDoc['fcmToken'];

        if (fcmToken != null && fcmToken.isNotEmpty) {
          await sendPushNotificationViaPhp(fcmToken, messageText);
        } else {
          debugPrint('No FCM token found for user ${otherContact!.id}');
        }
      } catch (e) {
        debugPrint('Error fetching FCM token or sending notification: $e');
      }
    }
  }

  // Call your PHP backend to send push notification securely
  Future<void> sendPushNotificationViaPhp(String token, String message) async {
    final String phpUrl = 'https://cotmade.com/fire/send_fcm.php';

    // Build URL with parameters (encode to handle spaces & special chars)
    final url = Uri.parse(
        '$phpUrl?token=$token');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        debugPrint('Push notification sent via PHP backend');
      } else {
        debugPrint(
            'Failed to send push via PHP backend: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calling PHP push backend: $e');
    }
  }

  // Load conversation info from Firestore snapshot
  getConversationInfoFromFirestore(DocumentSnapshot snapshot) {
    id = snapshot.id;

    String lastMessageText = snapshot['lastMessageText'] ?? "";
    Timestamp lastMessageDateTimestamp =
        snapshot['lastMessageDateTime'] ?? Timestamp.now();
    DateTime lastMessageDateTime = lastMessageDateTimestamp.toDate();

    lastMessage = MessageModel();
    lastMessage!.dateTime = lastMessageDateTime;
    lastMessage!.text = lastMessageText;

    List<String> userIDs = List<String>.from(snapshot['userIDs']) ?? [];
    List<String> userNames = List<String>.from(snapshot['userNames']) ?? [];
    otherContact = ContactModel();

    for (String userID in userIDs) {
      if (userID != AppConstants.currentUser.id) {
        otherContact!.id = userID;
        break;
      }
    }

    for (String name in userNames) {
      if (name != AppConstants.currentUser.getFullNameOfUser()) {
        otherContact!.firstName = name.split(" ")[0];
        otherContact!.lastName = name.split(" ")[1];
      }
    }
  }
}