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
import 'package:cotmade/view/ai/api_config.dart';
import 'dart:convert';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter/services.dart';

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
  // final apiKey = await ApiConfig.getApiKey();
  static const _cohereEndpoint = 'https://api.cohere.ai/v1/generate';

  static Future<String> getAIResponse(String input) async {
    final trimmedInput = input.trim();

    if (trimmedInput.isEmpty) {
      return "❌ Input is empty or whitespace only.";
    }

    final apiKey = await ApiConfig.getApiKey();

    final body = {
      "model": "command-light", // Match PHP model
      "prompt": "User: $trimmedInput\nBot:",
      "max_tokens": 100,
      "temperature": 0.8,
    };
    final res = await http.post(
      Uri.parse(_cohereEndpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
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
    final firestore = FirebaseFirestore.instance;
    final results = <Map<String, dynamic>>[];
    final seenVideos = <String>{};
    bool usedFallback = false;

    /// Keyword extractor to remove filler words
    List<String> extractKeywords(String input) {
      const stopWords = {
        'i',
        'me',
        'my',
        'myself',
        'we',
        'our',
        'ours',
        'ourselves',
        'you',
        'your',
        'yours',
        'yourself',
        'yourselves',
        'he',
        'him',
        'his',
        'himself',
        'she',
        'her',
        'hers',
        'herself',
        'it',
        'its',
        'itself',
        'they',
        'them',
        'their',
        'theirs',
        'themselves',
        'what',
        'which',
        'who',
        'whom',
        'this',
        'that',
        'these',
        'those',
        'am',
        'is',
        'are',
        'was',
        'were',
        'be',
        'been',
        'being',
        'have',
        'has',
        'had',
        'having',
        'do',
        'does',
        'did',
        'doing',
        'a',
        'an',
        'the',
        'and',
        'but',
        'if',
        'or',
        'because',
        'as',
        'until',
        'while',
        'of',
        'at',
        'by',
        'for',
        'with',
        'about',
        'against',
        'between',
        'into',
        'through',
        'during',
        'before',
        'after',
        'above',
        'below',
        'to',
        'from',
        'up',
        'down',
        'in',
        'out',
        'on',
        'off',
        'over',
        'under',
        'again',
        'further',
        'then',
        'once',
        'here',
        'there',
        'when',
        'where',
        'why',
        'how',
        'all',
        'any',
        'both',
        'each',
        'few',
        'more',
        'most',
        'other',
        'some',
        'such',
        'no',
        'nor',
        'not',
        'only',
        'own',
        'same',
        'so',
        'than',
        'too',
        'very',
        'can',
        'will',
        'just',
        'don',
        'should',
        'now',
        'need',
        'want',
        'find',
        'looking',
        'searching',
        'show',
        'please',
        'let',
        'could',
        'would',
        'may',
        'might',
        'shall',
        'must',
        'another',
        'people',
        'friends'
      };

      return input
          .toLowerCase()
          .split(RegExp(r'\W+')) // Split by non-word characters
          .where((word) => word.isNotEmpty && !stopWords.contains(word))
          .toList();
    }

    final trimmedQuery = query.trim().toLowerCase();
    final queryWords = extractKeywords(trimmedQuery);

    if (queryWords.isEmpty) {
      print("❗ Query is empty after filtering stopwords.");
      return {
        'results': [],
        'usedFallback': false,
      };
    }

    try {
      final snapshot = await firestore
          .collection('reels')
          .where('premium', isGreaterThan: 0)
          .limit(50)
          .get();

      print("🔍 Fetched ${snapshot.docs.length} documents from Firestore");

      // Score-based matching
      final scoredResults = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final videoUrl = data['reelsVideo'];

        if (videoUrl == null ||
            seenVideos.contains(videoUrl) ||
            excludeUrls.contains(videoUrl)) {
          continue;
        }

        final searchText = data['searchText'];
        if (searchText == null || searchText is! List) continue;

        final keywords =
            searchText.whereType<String>().map((e) => e.toLowerCase()).toList();

        int score = 0;

        for (final word in queryWords) {
          for (final keyword in keywords) {
            if (keyword == word) {
              score += 2; // Exact match
            } else if (keyword.contains(word) || word.contains(keyword)) {
              score += 1; // Partial match
            }
          }
        }

        if (score >= 2) {
          scoredResults.add({'data': data, 'score': score});
          seenVideos.add(videoUrl);
        }
      }

      // Sort by score (highest match first)
      scoredResults.sort((a, b) => b['score'].compareTo(a['score']));

      for (final item in scoredResults) {
        if (results.length >= 2) break;
        results.add(item['data']);
      }

      // Fallback if nothing found
      if (results.isEmpty) {
        usedFallback = true;
        final fallbackSnapshot =
            await firestore.collection('reels').limit(50).get();
        print("🔁 Fallback: checking fallback scores...");

        for (final doc in fallbackSnapshot.docs) {
          final data = doc.data();
          final videoUrl = data['reelsVideo'];

          if (videoUrl == null || seenVideos.contains(videoUrl)) continue;

          final searchText = data['searchText'];
          if (searchText == null || searchText is! List) continue;

          final keywords = searchText
              .whereType<String>()
              .map((e) => e.toLowerCase())
              .toList();
          int score = 0;

          for (final word in queryWords) {
            for (final keyword in keywords) {
              if (keyword == word) {
                score += 2;
              } else if (keyword.contains(word) || word.contains(keyword)) {
                score += 1;
              }
            }
          }

          if (score <= 1) {
            results.add(data);
            seenVideos.add(videoUrl);
          }

          if (results.length >= 2) break;
        }
      }
      return {
        'results': results,
        'usedFallback': usedFallback,
      };
    } catch (e) {
      print("❌ Error in fetchVideosBySearch: $e");
      return {
        'results': [],
        'usedFallback': false,
      };
    }
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
  bool _showRecordingIndicator = false;
  File? _selectedImage;

  late Interpreter _interpreter;
  late List<String> _labels;

  @override
  void initState() {
    super.initState();
    _loadTFLiteModel();
    _speech = stt.SpeechToText();

    // Add greeting message from the bot
    final greeting = _generateGreeting();
    _messages.add(ChatMessage(message: greeting, isUser: false));
  }

  Future<void> _handleImageUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final image = File(picked.path);
    setState(() => _selectedImage = image);

    _classifyImage(image);
  }

  Future<void> _classifyImage(File imageFile) async {
    // Decode the image from file
    final rawBytes = await imageFile.readAsBytes();
    final rawImage = img.decodeImage(rawBytes);

    if (rawImage == null) {
      setState(() {
        _messages.add(ChatMessage(
          message: "❌ Failed to decode the image.",
          isUser: false,
        ));
      });
      return;
    }

    const inputSize = 224; // MobileNet expects 224x224 input
    final resizedImage = img.copyResize(
      rawImage,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert resized image to normalized Float32List input
    final input = Float32List(inputSize * inputSize * 3);
    final bytes = resizedImage.getBytes(); // RGB sequence

    for (int i = 0, pixelIndex = 0; i < bytes.length; i += 3) {
      final r = bytes[i].toDouble();
      final g = bytes[i + 1].toDouble();
      final b = bytes[i + 2].toDouble();

      input[pixelIndex++] = (r - 127.5) / 127.5;
      input[pixelIndex++] = (g - 127.5) / 127.5;
      input[pixelIndex++] = (b - 127.5) / 127.5;
    }

    // Run inference
    final output = List.filled(1001, 0.0).reshape([1, 1001]);
    _interpreter.run(input, output);

    // Process top 3 predictions
    final results = List.generate(
      1001,
      (i) => MapEntry(i, output[0][i]),
    )..sort((a, b) => b.value.compareTo(a.value));

    final topResults = results.take(3).toList();

    if (topResults.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          message: "❌ Couldn't classify the image.",
          isUser: false,
        ));
      });
      return;
    }

    final labelsStr = topResults.map((e) {
      final label = e.key < _labels.length ? _labels[e.key] : "Unknown";
      return "$label (${(e.value * 100).toStringAsFixed(1)}%)";
    }).join(", ");

    setState(() {
      _messages.add(ChatMessage(
        message: "📷 Detected: $labelsStr\nLet me find listings for this...",
        isUser: false,
      ));
      _isBotTyping = true;
    });

    final query = topResults.map((e) => _labels[e.key]).join(" ");
    final videoResult = await CotmindBot.fetchVideosBySearch(query);
    final videoSuggestions = videoResult['results'];
    final usedFallback = videoResult['usedFallback'];

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
        _addPostingData(video['postingId'], video);
      }

      if (videoSuggestions.length == 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _messages.add(ChatMessage(
              message: _getMorePromptMessage(),
              isUser: false,
            ));
            _awaitingMoreConfirmation = true;
            _scrollToBottom();
          });
        });
      }
    });
  }

  Future<void> _loadTFLiteModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'tflite/mobilenet_v1.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      final labelData = await rootBundle.loadString('tflite/labels.txt');
      _labels = labelData.split('\n');

      print("✅ Model and labels loaded.");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
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

  bool _isCasualGreeting(String input) {
    final greetings = [
      "hi",
      "hello",
      "hey",
      "how are you",
      "good morning",
      "good afternoon",
      "good evening",
      "what's up",
      "yo",
      "howdy",
      "can we talk",
      "i love how you greet"
          "greetings"
    ];

    final normalized = input.toLowerCase().trim();
    return greetings.any((greet) => normalized == greet);
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
        });

        if (videoSuggestions.length == 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _messages.add(ChatMessage(
                message: _getMorePromptMessage(),
                isUser: false,
              ));
              _awaitingMoreConfirmation = true;
              _scrollToBottom();
            });
          });
        }
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
    setState(() {
      //  _messages.add(ChatMessage(message: botReply, isUser: false));
      _isBotTyping = false;
    });

    if (_isCasualGreeting(trimmedInput)) return;

// Continue with video search only if not a casual message
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
    });

    if (videoSuggestions.length == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _messages.add(ChatMessage(
            message: _getMorePromptMessage(),
            isUser: false,
          ));
          _awaitingMoreConfirmation = true;
          _scrollToBottom();
        });
      });
    }
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

  Timer? _timeoutTimer;

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'stopped') {
          _stopListening();
        }
      },
      onError: (e) {
        print("Speech error: $e");
        _stopListening();
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _showRecordingIndicator = true;
      });

      _speech.listen(
        onResult: (result) {
          _controller.text = result.recognizedWords;
          if (result.finalResult) {
            _handleSend(result.recognizedWords);
            _stopListening(); // Automatically stop listening after result is final
          }
        },
      );

      // Start a timeout to stop listening if no speech is detected within 5 seconds
      _timeoutTimer = Timer(Duration(seconds: 5), () {
        if (_isListening) {
          _stopListening();
        }
      });
    }
  }

  void _stopListening() {
    _timeoutTimer?.cancel(); // Cancel timeout timer when speech stops
    _speech.stop();
    setState(() {
      _isListening = false;
      _showRecordingIndicator = false;
    });
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
    _interpreter.close();
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
        postId: msg.posting!.id ?? '', // Pass postId here
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showRecordingIndicator)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.image),
                    onPressed: _handleImageUpload,
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.mic, color: Colors.redAccent),
                  SizedBox(width: 6),
                  Text(
                    "Listening...",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                onPressed: _isListening ? _stopListening : _startListening,
                color: _isListening ? Colors.redAccent : null,
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
          SizedBox(height: 6),
          Column(
            children: [
              Center(
                child: Text(
                  "cotmind 1.0 – beta phase",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: 2),
              Center(
                child: Text(
                  "Tip: Ask about rentals, listings, areas, amenities or price/night",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 2),
            ],
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
  final String postId; // Add this field

  const VideoPreviewCard({
    required this.videoUrl,
    required this.caption,
    required this.posting, // Accept PostingModel as a parameter
    required this.postId,
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
      ..setVolume(0.0) // 👈 Mute the video
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
    _incrementVideoViews();
    showDialog(
      context: context,
      barrierDismissible: true, // <-- allow tapping outside to dismiss
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // <-- ensures all taps are detected
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

  void _incrementVideoViews() async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('reels').doc(widget.postId);

      await docRef.update({
        'views': FieldValue.increment(1),
      });

      print("✅ Incremented view count for ${widget.postId}");
    } catch (e) {
      print("❌ Failed to increment views: $e");
    }
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
          SizedBox(height: 2),
          //  Text(widget.caption, style: TextStyle(fontWeight: FontWeight.bold)),

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
