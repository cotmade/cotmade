import 'package:cotmade/global.dart';
import 'package:cotmade/model/conversation_model.dart';
import 'package:cotmade/model/message_model.dart';
import 'package:cotmade/view/widgets/message_list_tile_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/app_constants.dart';

class ConversationScreen extends StatefulWidget {
  final ConversationModel? conversation;

  const ConversationScreen({super.key, this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  ConversationModel? conversation;
  TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    conversation = widget.conversation;
  }

  void sendMessage() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

    await conversation!.addMessageToFirestore(text);
    controller.clear();

    // Delay and scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          conversation!.otherContact!.getFullNameOfUser(),
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: inboxViewModel.getMessages(conversation),
              builder: (context, snapshots) {
                if (snapshots.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshots.data?.docs ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot snapshot = docs[index];
                    MessageModel message = MessageModel();
                    message.getMessageInfoFromFirestore(snapshot);

                    // Determine sender
                    if (message.sender!.id == AppConstants.currentUser.id) {
                      message.sender =
                          AppConstants.currentUser.createContactFromUser();
                    } else {
                      message.sender = conversation!.otherContact;
                    }

                    return MessageListTileUI(message: message);
                  },
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Write a message...',
                      contentPadding: EdgeInsets.all(20.0),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 18.0),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
