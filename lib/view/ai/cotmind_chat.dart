import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cotmade/model/posting_model.dart';
import 'dart:async';
import 'package:cotmade/view/view_posting_screen.dart';

class ChatMessage {
  final String message;
  final bool isUser;
  final String? videoUrl;
  final PostingModel? posting;

  ChatMessage({
    required this.message,
    required this.isUser,
    this.videoUrl,
    this.posting,
  });
}

class CotmindBot {
  static const _cohereApiKey = 'eSjwajsYSr7KkI6UvHgPpmE4XcDSp2QjJU4v5R6g';
  static const _cohereEndpoint = 'https://api.cohere.ai/v1/generate';

  static List<String> extractKeywords(String input) {
    final stopWords = {
      'what',
      'is',
      'the',
      'a',
      'in',
      'of',
      'to',
      'on',
      'with',
      'how',
      'can',
      'i',
      'you',
      'tell',
      'me',
      'about',
      'need',
      'know',
      'where',
      'why',
      'are',
      'for',
      'and',
      'or',
      'an',
      'do'
    };

    return input
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((word) => word.isNotEmpty && !stopWords.contains(word))
        .toSet()
        .toList();
  }

  static Future<String> getAIResponse(String input) async {
    final trimmedInput = input.trim();

    if (trimmedInput.isEmpty) {
      return "❌ Input is empty or whitespace only.";
    }

    final body = {
      "model": "command-light", // Match PHP model
      "prompt": "User: $trimmedInput\nBot:",
      "max_tokens": 100,
      "temperature": 0.8,
    };

    final res = await http.post(
      Uri.parse(_cohereEndpoint),
      headers: {
        'Authorization': 'Bearer $_cohereApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      print("✅ Cohere response: $data");

      return data['generations']?[0]?['text']?.trim() ??
          "⚠️ No response text found.";
    } else {
      print("❌ Cohere error ${res.statusCode}: ${res.body}");
      return "❌ API error ${res.statusCode}: ${res.body}";
    }
  }

  static Future<List<Map<String, dynamic>>> fetchVideosBySearch(
      String query) async {
    final keywords = extractKeywords(query);
    final firestore = FirebaseFirestore.instance;
    final results = <Map<String, dynamic>>[];

    for (final word in keywords.take(5)) {
      final snapshot = await firestore
          .collection('reels')
          .where('searchText', isGreaterThanOrEqualTo: word)
          .where('searchText', isLessThanOrEqualTo: word + '\uf8ff')
          .limit(1) // Limit results for each keyword search
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Check if the video is already in the results list
        if (!results.any((e) => e['reelsVideo'] == data['reelsVideo'])) {
          results.add(data);

          // Fetch posting information if necessary
          String postingId = data['postingId'];
          final postingSnapshot =
              await firestore.collection('postings').doc(postingId).get();

          // You can use the PostingModel here to handle the data more cleanly
          PostingModel postingModel = PostingModel(id: postingId);
          postingModel.getPostingInfoFromSnapshot(postingSnapshot);

          // Add posting details to the video data
        }

        // Exit early if we already have 2 results
        if (results.length >= 2) {
          break;
        }
      }

      // Exit the loop early once we have 2 unique results
      if (results.length >= 2) {
        break;
      }
    }

    return results.take(2).toList(); // Limit to 2 results max
  }
}

class CotmindChat extends StatefulWidget {
  @override
  _CotmindChatState createState() => _CotmindChatState();
}

class _CotmindChatState extends State<CotmindChat> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isBotTyping = false;
  MemoryImage? displayImage;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _handleSend(String input) async {
    if (input.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(message: input, isUser: true));
      _isBotTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    // Get the AI response
    final botReply = await CotmindBot.getAIResponse(input);

    // Get video suggestions
    final videoSuggestions = await CotmindBot.fetchVideosBySearch(input);

    // Now that async operations are done, update the state
    setState(() {
      _messages.add(ChatMessage(message: botReply, isUser: false));
      _isBotTyping = false;

      // Add video suggestions to the messages list
      for (var video in videoSuggestions) {
        String postingId = video['postingId'];

        // Fetch posting data asynchronously
        _addPostingData(postingId, video);
      }

      _scrollToBottom();
    });
  }

  Future<void> _addPostingData(
      String postingId, Map<String, dynamic> video) async {
    try {
      // Fetch the posting data
      final postingSnapshot = await FirebaseFirestore.instance
          .collection('postings')
          .doc(postingId)
          .get();

      PostingModel postingModel = PostingModel(id: postingId);
      postingModel.getPostingInfoFromSnapshot(postingSnapshot);

      // After fetching the posting data, add it to messages
      setState(() {
        _messages.add(ChatMessage(
          message: video['caption'] ?? 'Suggested Video',
          isUser: false,
          videoUrl: video['reelsVideo'],
          posting: postingModel, // Pass the PostingModel
        ));
      });
    } catch (e) {
      print("Error fetching posting data: $e");
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (_) {},
      onError: (e) => print("Speech error: $e"),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          _controller.text = result.recognizedWords;
          if (result.finalResult) {
            _handleSend(result.recognizedWords);
            _stopListening();
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
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
  void dispose() {
    _messages.clear();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🤖")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isBotTyping && index == _messages.length) {
                  return _buildTypingBubble();
                }
                return _buildChatBubble(_messages[index]);
              },
            ),
          ),
          Divider(height: 1),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: CircleAvatar(child: Icon(Icons.smart_toy)),
        ),
        Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text("Typing..."),
        ),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) CircleAvatar(child: Icon(Icons.smart_toy)),
          if (!isUser) SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.pinkAccent : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (msg.videoUrl != null) _buildVideoCard(msg),
              ],
            ),
          ),
          if (isUser) SizedBox(width: 8),
          isUser
              ? (displayImage != null
                  ? CircleAvatar(
                      backgroundImage: displayImage,
                      radius: 29,
                    )
                  : Icon(
                      Icons.account_circle,
                      size: 30,
                      color: Colors.white,
                    ))
              : Container(), // or another widget for bot
        ],
      ),
    );
  }

  Widget _buildVideoCard(ChatMessage msg) {
    return Container(
      margin: EdgeInsets.only(top: 6),
      width: 220,
      child: VideoPreviewCard(
        videoUrl: msg.videoUrl!,
        caption: msg.message,
        posting: msg.posting!,
      ),
    );
  }

  void _playVideo(String videoUrl) {
    showModalBottomSheet(
      context: context,
      builder: (_) => VideoPlayerScreen(videoUrl: videoUrl),
      isScrollControlled: true,
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: _handleSend,
              decoration: InputDecoration(
                hintText: "Ask something...",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => _handleSend(_controller.text),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) => setState(() {}))
      ..play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 400,
        padding: EdgeInsets.all(12),
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class VideoPreviewCard extends StatefulWidget {
  final String videoUrl;
  final String caption;
  final PostingModel
      posting; // Adding PostingModel for passing to ViewPostingScreen

  const VideoPreviewCard({
    required this.videoUrl,
    required this.caption,
    required this.posting, // Accept PostingModel as a parameter
  });

  @override
  _VideoPreviewCardState createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends State<VideoPreviewCard> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Method to open the full-screen video
  void _openFullVideo() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context), // Close dialog when tapped
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: _initialized
                  ? VideoPlayer(_controller) // Play video in full-screen
                  : Container(
                      color: Colors.grey[300],
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),
        ),
      ),
    );

    // Play the video when the modal opens
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openFullVideo, // Open full-screen video on tap
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: _initialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      Container(
                        color: Colors.black26,
                        child: Icon(Icons.play_circle_fill,
                            size: 48, color: Colors.white),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.grey[300],
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  ),
          ),
          SizedBox(height: 4),
          Text(widget.caption, style: TextStyle(fontWeight: FontWeight.bold)),

          // "Book Now" Button at the bottom center
          Padding(
            padding:
                const EdgeInsets.only(top: 8.0), // Optional margin for button
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Navigate to ViewPostingScreen when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ViewPostingScreen(posting: widget.posting),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
