import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class ChatMessage {
  final String message;
  final bool isUser;
  final String? videoUrl;
  final String? thumbnailUrl;

  ChatMessage({
    required this.message,
    required this.isUser,
    this.videoUrl,
    this.thumbnailUrl,
  });
}

class CotmindBot {
  static const _cohereApiKey = 'eSjwajsYSr7KkI6UvHgPpmE4XcDSp2QjJU4v5R6g';
  static const _cohereEndpoint = 'https://api.cohere.ai/v1/generate';

  static Future<String> getAIResponse(String input) async {
    final body = {
      "model": "command-r",
      "prompt": "User: $input\nBot:",
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
      return data['generations']?[0]?['text']?.trim() ?? "Hmm... I’m not sure.";
    } else {
      print("Cohere error: ${res.body}");
      return "Oops! I had trouble thinking.";
    }
  }

  static Future<List<Map<String, dynamic>>> fetchVideosBySearch(
      String query) async {
    final keyword = query.toLowerCase();

    final results = await FirebaseFirestore.instance
        .collection('reels')
        .where('searchText', isGreaterThanOrEqualTo: keyword)
        .where('searchText', isLessThanOrEqualTo: keyword + '\uf8ff')
        .limit(3)
        .get();

    return results.docs.map((doc) => doc.data()).toList();
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

    final botReply = await CotmindBot.getAIResponse(input);
    final videoSuggestions = await CotmindBot.fetchVideosBySearch(input);

    setState(() {
      _messages.add(ChatMessage(message: botReply, isUser: false));
      _isBotTyping = false;

      for (var video in videoSuggestions) {
        _messages.add(ChatMessage(
          message: video['title'] ?? 'Suggested Video',
          isUser: false,
          videoUrl: video['videoUrl'],
          thumbnailUrl: video['thumbnailUrl'],
        ));
      }

      _scrollToBottom();
    });
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

  @override
  void dispose() {
    _messages.clear();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cotmind 🤖")),
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
                    color: isUser ? Colors.blueAccent : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (msg.videoUrl != null && msg.thumbnailUrl != null)
                  _buildVideoCard(msg),
              ],
            ),
          ),
          if (isUser) SizedBox(width: 8),
          if (isUser) CircleAvatar(child: Icon(Icons.person)),
        ],
      ),
    );
  }

  Widget _buildVideoCard(ChatMessage msg) {
    return Container(
      margin: EdgeInsets.only(top: 6),
      width: 220,
      child: GestureDetector(
        onTap: () => _playVideo(msg.videoUrl!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: msg.thumbnailUrl!,
              height: 120,
              width: 220,
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(
                height: 120,
                color: Colors.grey[300],
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (ctx, url, err) => Icon(Icons.error),
            ),
            SizedBox(height: 4),
            Text(
              msg.message,
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
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
