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
import 'package:cotmade/model/contact_model.dart';
import 'package:cotmade/global.dart';
import 'package:cotmade/model/app_constants.dart';
import 'dart:math';

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

  static Future<Map<String, dynamic>> fetchVideosBySearch(
    String query, {
    List<String> excludeUrls = const [],
  }) async {
    final keywords = extractKeywords(query);
    final firestore = FirebaseFirestore.instance;
    final results = <Map<String, dynamic>>[];
    final seenVideos = <String>{};
    final scoredResults = <Map<String, dynamic>>[];
    bool usedFallback = false;

    if (keywords.isEmpty) {
      return {
        'results': [],
        'usedFallback': false,
      };
    }

    // Perform one single query using arrayContainsAny with searchKeywords
    final snapshot = await firestore
        .collection('reels')
        .where('searchKeywords', arrayContainsAny: keywords.take(40).toList())
        .limit(50)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final videoUrl = data['reelsVideo'];

      if (videoUrl == null ||
          seenVideos.contains(videoUrl) ||
          excludeUrls.contains(videoUrl)) {
        continue;
      }

      final searchKeywords = List<String>.from(data['searchKeywords'] ?? []);
      int score = keywords.fold(0,
          (sum, keyword) => searchKeywords.contains(keyword) ? sum + 1 : sum);

      scoredResults.add({'data': data, 'score': score});
      seenVideos.add(videoUrl);
    }

    // Sort results by score descending
    scoredResults.sort((a, b) => b['score'].compareTo(a['score']));

    // Pick top 2
    for (final item in scoredResults) {
      if (results.length >= 2) break;
      results.add(item['data']);
    }

    // Optional fallback if no results found (using looser match)
    if (results.isEmpty) {
      usedFallback = true;

      final fallbackSnapshot =
          await firestore.collection('reels').limit(10).get();

      for (final doc in fallbackSnapshot.docs) {
        final data = doc.data();
        final videoUrl = data['reelsVideo'];
        if (videoUrl == null || seenVideos.contains(videoUrl)) continue;

        results.add(data);
        seenVideos.add(videoUrl);

        if (results.length >= 2) break;
      }
    }

    return {
      'results': results,
      'usedFallback': usedFallback,
    };
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
  String? _lastQuery;
  Set<String> _seenVideoUrls = {};
  int _followUpCount = 0;
  bool _awaitingMoreConfirmation = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Add greeting message from the bot
    final greeting = _generateGreeting();
    _messages.add(ChatMessage(message: greeting, isUser: false));
  }

  String _generateGreeting() {
    final hour = DateTime.now().hour;
    final userName = AppConstants.currentUser.getFullNameOfUser();
    final random = Random();

    List<String> morningMessages = [
      "Good morning $userName! 🌅 How may I help you today?",
      "Morning $userName! Ready to get started?",
      "Hey $userName, good morning! Need any help?"
    ];

    List<String> afternoonMessages = [
      "Good afternoon $userName! ☀️ How can I assist you today?",
      "Hi $userName, enjoying your afternoon? Let me know if you need anything.",
      "Good day $userName! How may I help?"
    ];

    List<String> eveningMessages = [
      "Good evening $userName! 🌙 What can I help you with?",
      "Evening $userName! Need something before you call it a day?",
      "Hi $userName! 🌜 How can I assist you this evening?"
    ];

    if (hour < 12) {
      return morningMessages[random.nextInt(morningMessages.length)];
    } else if (hour < 17) {
      return afternoonMessages[random.nextInt(afternoonMessages.length)];
    } else {
      return eveningMessages[random.nextInt(eveningMessages.length)];
    }
  }

  String _getRandomFallbackMessage() {
    final fallbackMessages = [
      "I couldn't find an exact match, but here are some similar listings I dug up 👇",
      "Hmm... nothing matched exactly, but these might interest you 🧐",
      "These listings may not be exact, but they’re close to what you asked for 👀",
      "No exact matches, but I think you'll like these similar options!",
      "I searched around and found a few similar listings you might enjoy 🏡"
    ];

    final random = Random();
    return fallbackMessages[random.nextInt(fallbackMessages.length)];
  }

  bool _isPositiveResponse(String input) {
    final lower = input.toLowerCase();
    return [
      "yes",
      "sure",
      "ok",
      "okay",
      "please",
      "show me",
      "go ahead",
      "do it",
      "yeah",
      "why not",
      "more",
      "another"
    ].any((phrase) => lower.contains(phrase));
  }

  bool _isFollowUpRequest(String input) {
    final lower = input.toLowerCase();
    return [
      "more",
      "another",
      "again",
      "next",
      "any other",
      "show me more",
      "give me more"
    ].any((phrase) => lower.contains(phrase));
  }

  String _getRefinementPrompt() {
    final prompts = [
      "I've already shown you a few listings. Could you be a bit more specific so I can help better? 😊",
      "I’m trying my best! Can you give me more details so I can recommend the perfect place? 🧐",
      "Hmm, I’ve run out of similar listings. Could you refine your request a bit? 🔍",
      "Let’s narrow it down. What exactly are you looking for — location, price, type? 🤔",
      "No more matches for now. Could you describe your needs a little more clearly? 🙏"
    ];
    final random = Random();
    return prompts[random.nextInt(prompts.length)];
  }

  String _getMorePromptMessage() {
    final prompts = [
      "Would you like to see 2 more listings? 😊",
      "Want me to show you a couple more options? 🏘️",
      "Should I pull up 2 more listings for you? 👀",
      "Let me know if you'd like to see more! 👍",
      "Need a few more recommendations? I got you! 💡"
    ];
    final random = Random();
    return prompts[random.nextInt(prompts.length)];
  }

  void _handleSend(String input) async {
    if (input.trim().isEmpty) return;

    final trimmedInput = input.trim();
    final isFollowUp = _isFollowUpRequest(trimmedInput);

    setState(() {
      _messages.add(ChatMessage(message: trimmedInput, isUser: true));
      _isBotTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    // Handle confirmation if awaiting user response for more
    if (_awaitingMoreConfirmation) {
      _awaitingMoreConfirmation = false;

      if (_isPositiveResponse(trimmedInput)) {
        _followUpCount++;

        if (_followUpCount >= 2) {
          setState(() {
            _isBotTyping = false;
            _messages.add(ChatMessage(
              message: _getRefinementPrompt(),
              isUser: false,
            ));
          });
          return;
        }

        final videoResult = await CotmindBot.fetchVideosBySearch(
          _lastQuery ?? trimmedInput,
          excludeUrls: _seenVideoUrls.toList(),
        );

        final List<Map<String, dynamic>> videoSuggestions =
            videoResult['results'];
        final bool usedFallback = videoResult['usedFallback'];

        setState(() {
          _isBotTyping = false;

          if (usedFallback && videoSuggestions.isNotEmpty) {
            _messages.add(ChatMessage(
              message: _getRandomFallbackMessage(),
              isUser: false,
            ));
          }

          for (var video in videoSuggestions) {
            _seenVideoUrls.add(video['reelsVideo']);
            final postingId = video['postingId'];
            _addPostingData(postingId, video);
          }

          // Ask again after showing next 2
          if (videoSuggestions.length == 2) {
            _messages.add(ChatMessage(
              message: _getMorePromptMessage(),
              isUser: false,
            ));
            _awaitingMoreConfirmation = true;
          }

          _scrollToBottom();
        });
      } else {
        setState(() {
          _isBotTyping = false;
          _messages.add(ChatMessage(
            message: _getRefinementPrompt(),
            isUser: false,
          ));
        });
      }

      return;
    }

    // Fresh search
    _lastQuery = trimmedInput;
    _followUpCount = 0;
    _seenVideoUrls.clear();

    final botReply = await CotmindBot.getAIResponse(trimmedInput);

    final videoResult = await CotmindBot.fetchVideosBySearch(trimmedInput);
    final List<Map<String, dynamic>> videoSuggestions = videoResult['results'];
    final bool usedFallback = videoResult['usedFallback'];

    setState(() {
      _messages.add(ChatMessage(message: botReply, isUser: false));
      _isBotTyping = false;

      if (usedFallback && videoSuggestions.isNotEmpty) {
        _messages.add(ChatMessage(
          message: _getRandomFallbackMessage(),
          isUser: false,
        ));
      }

      for (var video in videoSuggestions) {
        _seenVideoUrls.add(video['reelsVideo']);
        final postingId = video['postingId'];
        _addPostingData(postingId, video);
      }

      // Ask user if they want more
      if (videoSuggestions.length == 2) {
        _messages.add(ChatMessage(
          message: _getMorePromptMessage(),
          isUser: false,
        ));
        _awaitingMoreConfirmation = true;
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

  @override
  void dispose() {
    _messages.clear();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CotMind🤖")),
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
          child: Text("Thinking..."),
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
              ? (AppConstants.currentUser.displayImage != null
                  ? CircleAvatar(
                      backgroundImage: AppConstants.currentUser.displayImage,
                      radius: 19,
                    )
                  : Icon(
                      Icons.account_circle,
                      size: 20,
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
