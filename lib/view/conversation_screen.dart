import 'package:cotmade/global.dart';
import 'package:cotmade/model/conversation_model.dart';
import 'package:cotmade/model/message_model.dart';
import 'package:cotmade/view/widgets/message_list_tile_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/app_constants.dart';

class ConversationScreen extends StatefulWidget {
  ConversationModel? conversation;

  ConversationScreen({
    super.key,
    this.conversation,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  ConversationModel? conversation;
  TextEditingController controller = TextEditingController();

  sendMessage() {
    String text = controller.text;

    if (text.isEmpty) {
      return;
    }

    conversation!.addMessageToFirestore(text).whenComplete(() {
      setState(() {
        controller.text = "";
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    conversation = widget.conversation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //   backgroundColor: Colors.white,
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
        // leading: Icon(Icons.bac, color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          conversation!.otherContact!.getFullNameOfUser(),
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     iconSize: 25.0,
        //     icon: Icon(Icons.video_collection_rounded),
        //     onPressed: () {
        //       Get.to(ReelScreen());
        //     },
        //    color: Colors.black,
        //  ),
        // ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: inboxViewModel.getMessages(conversation),
              builder: (context, snapshots) {
                if (snapshots.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return ListView.builder(
                    itemCount: snapshots.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot snapshot = snapshots.data!.docs[index];
                      MessageModel currentMessage = MessageModel();
                      currentMessage.getMessageInfoFromFirestore(snapshot);

                      if (currentMessage.sender!.id ==
                          AppConstants.currentUser.id) {
                        currentMessage.sender =
                            AppConstants.currentUser.createContactFromUser();
                      } else {
                        currentMessage.sender = conversation!.otherContact;
                      }

                      return MessageListTileUI(
                        message: currentMessage,
                      );
                    },
                  );
                }
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
                border: Border.all(
              color: Colors.black,
            )),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 5 / 6,
                  child: TextField(
                    decoration: const InputDecoration(
                        hintText: 'Write a message',
                        contentPadding: EdgeInsets.all(20.0),
                        border: InputBorder.none),
                    minLines: 1,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 20.0),
                    controller: controller,
                  ),
                ),
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      sendMessage();
                    },
                    icon: const Icon(Icons.send),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
