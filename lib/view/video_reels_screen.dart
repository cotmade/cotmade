import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cotmade/view/guestScreens/user_profile_page.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/guestScreens/feedback_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/guest_home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cotmade/view/webview_screen.dart';
import 'package:cotmade/view/ai/cotmind_chat.dart';

class VideoReelsPage extends StatefulWidget {
  final String? reelId;

  const VideoReelsPage({this.reelId, Key? key}) : super(key: key);
  @override
  _VideoReelsPageState createState() => _VideoReelsPageState();
}

class _VideoReelsPageState extends State<VideoReelsPage> {
  late PageController _pageController;
  List<DocumentSnapshot> _allVideos = []; // Store all videos in memory as cach
  List<DocumentSnapshot> _filteredVideos = [];
  Map<int, VideoPlayerController> _controllers = {};
  Map<int, AudioPlayer> _audioPlayers = {};
  int _currentIndex = 0;
  bool _isMuted = true;
  bool _isSearchVisible = false;
  TextEditingController _searchController = TextEditingController();
  Set<String> _viewedVideoIds = {};
  final cacheManager = DefaultCacheManager(); // Cache manager forr videos
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Listen to search input changes to update filtered videos dynamically
    _searchController.addListener(() {
      _filterVideos();
    });
    _loadUserProfile().then((_) {
      _loadVideos();
    }); // Load videos from Firestore initially
  }

  Map<String, dynamic>? _userProfile;

  Future<void> _loadUserProfile() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users') // or your users collection name
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      _userProfile = doc.data();
    }
  }

  double computeScore(Map<String, dynamic> data) {
    final views = (data['views'] ?? 0).toDouble();
    final likes = (data['likes'] ?? 0).toDouble();
    final premium = (data['premium'] ?? 0).toDouble();
    final createdAt = (data['time'] as Timestamp?)?.toDate() ?? DateTime.now();
    final city = data['city'] ?? '';
    final country = data['country'] ?? '';
    final videoId = data['id'] ?? '';

    double watchRatio = 1.0;

    int hoursSincePost = DateTime.now().difference(createdAt).inHours;
    int daysSincePost = DateTime.now().difference(createdAt).inDays;
    double freshnessScore = 1 / (1 + hoursSincePost);

    // 🌟 NEW LISTING BOOST: Time-decayed + Engagement-aware
    double newListingBoost = 1.0;

    if (daysSincePost <= 14) {
      // Time decay: from 1.3 → 1.0 over 14 days
      double decayFactor = 1.3 - (0.3 * (daysSincePost / 14.0)).clamp(0.0, 1.0);

      // Engagement boost: use like/view ratio
      double engagementScore =
          (views > 0) ? (likes / views).clamp(0.0, 1.0) : 0.0;

      if (engagementScore >= 0.3) {
        newListingBoost = decayFactor;
      } else if (engagementScore >= 0.1) {
        newListingBoost = decayFactor * 0.9;
      } else {
        newListingBoost = decayFactor * 0.7;
      }
    }

    // 🔼 Premium boost
    double premiumBoost = 0.0;
    if (premium == 6) {
      premiumBoost = 1.2;
    } else if (premium == 5) {
      premiumBoost = 1.0;
    } else if (premium == 3 && views < 500) {
      premiumBoost = 0.25;
    }
    premiumBoost *= freshnessScore * 2;

    // 📍 User location match
    double userMatchScore = 0;
    if (_userProfile != null) {
      final userCountry = _userProfile!['country'] ?? '';
      final userCity = _userProfile!['city'] ?? '';
      if (userCountry == country || userCity == city) {
        userMatchScore = 1.0;
      }
    }

    // 👁️ Viewed penalty
    double viewedPenalty = _viewedVideoIds.contains(videoId) ? 0.5 : 1.0;

    // 📊 Base score
    double score = (views * 0.2) +
        (likes * 0.25) +
        (watchRatio * 0.2) +
        (freshnessScore * 0.15) +
        (premium * 0.1) +
        (userMatchScore * 0.1);

    score = (score + premiumBoost) * newListingBoost * viewedPenalty;

    return score;
  }

  void _cleanupFarControllers(int centerIndex) {
    final keysToRemove = _controllers.keys.where((index) {
      return (index - centerIndex).abs() > 2;
    }).toList();

    for (final index in keysToRemove) {
      final controller = _controllers.remove(index);
      controller?.pause();
      controller?.dispose();
    }
  }

  // Helper function to break consecutive Premium 5 and 6 videos
  void _breakConsecutivePremiums(List<DocumentSnapshot> videos) {
    for (int i = 1; i < videos.length; i++) {
      final current = videos[i].data() as Map<String, dynamic>;
      final previous = videos[i - 1].data() as Map<String, dynamic>;

      final currentPremium = current['premium'] ?? 0;
      final previousPremium = previous['premium'] ?? 0;

      // If both are 5 or 6, try to swap current with a lower-premium video further down
      if ((currentPremium == 5 || currentPremium == 6) &&
          (previousPremium == 5 || previousPremium == 6)) {
        for (int j = i + 1; j < videos.length; j++) {
          final future = videos[j].data() as Map<String, dynamic>;
          final futurePremium = future['premium'] ?? 0;

          // Swap with a video that's not 5 or 6
          if (futurePremium < 5) {
            final temp = videos[i];
            videos[i] = videos[j];
            videos[j] = temp;
            break;
          }
        }
      }
    }
  }

  // Function to load videos from Firestore and cache them locally
  // Updated _loadVideos with anti-consecutive-premium logic
  Future<void> _loadVideos() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reels')
          .orderBy('time', descending: true)
          .get();

      _allVideos = snapshot.docs;

      // Sort using computeScore
      _allVideos.sort((a, b) {
        double scoreA = computeScore(a.data() as Map<String, dynamic>);
        double scoreB = computeScore(b.data() as Map<String, dynamic>);
        return scoreB.compareTo(scoreA); // descending
      });

      // Optional shuffle to add freshness
      if (_allVideos.length > 2) {
        final rand = _allVideos.removeAt(2);
        _allVideos.insert(0, rand);
      }

      // Filter out non-premium videos
      _filteredVideos = _allVideos.where((video) {
        final data = video.data() as Map<String, dynamic>;
        final premium = data['premium'] ?? 0;
        return premium != 0;
      }).toList();

      int initialPage = 0;
      // ✅ Handle deep link scroll
      final reelId = widget.reelId;

      if (reelId != null && reelId.isNotEmpty) {
        final targetIndex = _filteredVideos.indexWhere((video) {
          final data = video.data() as Map<String, dynamic>;
          return data['id'] == reelId;
        });

        if (targetIndex != -1) {
          initialPage = targetIndex;
          _currentIndex = targetIndex;
        }
      }

      // Prevent Premium 5 and 6 from being consecutive
      _breakConsecutivePremiums(_filteredVideos);

      setState(() {});

      // Preload first few videos
      for (int i = 0; i <= 1 && i < _filteredVideos.length; i++) {
        _preloadVideo(i);
      }

      // Start caching the rest in the background
      _cacheVideosInBackground(startFromIndex: 4);
    } catch (e) {
      print("Error loading videos: $e");
    }
  }

  // Function to preload videos from the cacheimages
  Future<void> _preloadVideo(int index) async {
    if (index < 0 ||
        index >= _filteredVideos.length ||
        _controllers.containsKey(index)) return;

    var videoData = _filteredVideos[index].data() as Map<String, dynamic>;
    var videoUrl = videoData['reelsVideo'];
    var audioName = videoData['audioName'];
    var premium = videoData['premium'] ?? 0;

    final filePath = await _cacheVideo(videoUrl);
    if (filePath != null) {
      final controller = VideoPlayerController.file(File(filePath));
      _controllers[index] = controller;

      await controller.initialize();
      controller.setLooping(true);

      // Set volume based on premium (mute or unmute)
      if (premium == 6) {
        controller.setVolume(1.0);
      } else if (premium == 5) {
        controller.setVolume(0.0);
      } else if (premium >= 3) {
        controller.setVolume(_isMuted ? 0.0 : 1.0);
      } else {
        controller.setVolume(0.0);
      }

      // Don't call play here! Let onPageChanged handle playing.

      // Optionally, prepare audio logic here if needed:
      // if (premium < 3 && audioName != null && audioName.isNotEmpty) {
      //   _playAudio(index, audioName);
      // }

      setState(() {}); // Notify UI that video is ready
    }
  }

  Future<void> _incrementViewCountIfNeeded(String videoDocId) async {
    if (_viewedVideoIds.contains(videoDocId)) {
      // Already counted in this session, skip
      return;
    }

    final docRef =
        FirebaseFirestore.instance.collection('reels').doc(videoDocId);

    try {
      await docRef.update({
        'views': FieldValue.increment(1),
      });
      _viewedVideoIds.add(videoDocId);
    } catch (e) {
      print('Failed to increment view count for $videoDocId: $e');
    }
  }

  // Stop the audio of the previous video when swiping to the next one
  // void _stopAudioForPreviousVideo(int currentIndex) {
  //  for (var key in _audioPlayers.keys) {
  //    if (key != currentIndex) {
  //      _audioPlayers[key]?.stop(); // Stop any previous audio
  //    }
  //  }
  // }

  // Cache the video file
  Future<String?> _cacheVideo(String videoUrl) async {
    final file = await cacheManager.getSingleFile(videoUrl);
    return file.path; // Return the local file path
  }

  Future<void> _stopAllAudio() async {
    for (var player in _audioPlayers.values) {
      if (player.playing) {
        await player.stop();
      }
      await player.dispose(); // 👈 Clean up memory
    }
    _audioPlayers.clear();

    // Pause and dispose all video controllers
    for (var controller in _controllers.values) {
      if (controller.value.isPlaying) await controller.pause();
      await controller.dispose();
    }
    _controllers.clear();
  }

  @override
  void deactivate() {
    super.deactivate();
    print("deactivate() called — stopping audio immediately.");
    _stopAllAudio(); // Or _disposeMedia() if you want to clean everything
  }

  final List<String> audioFiles = [
    'images/cinematic-intro.mp3',
    'images/gospel-choir-heavenly.mp3',
    'images/prazkhanalmusic__chimera-afro-tim-clap-loop.wav',
  ];

// Play audio by searching for the audioName in audioFiles
/*   void _playAudio(int index, String audioName) async {
    // Stop previous audio if any
    if (_audioPlayers[index] != null) {
      await _audioPlayers[index]!.dispose();
    }

    final player = AudioPlayer();
    _audioPlayers[index] = player;

    try {
      // Find the full path from audioFiles list that ends with audioName
      final audioPath = audioFiles.firstWhere(
        (filePath) => filePath.endsWith(audioName),
        orElse: () => '',
      );

      if (audioPath.isEmpty) {
        print("Audio file not found for name: $audioName");
        return;
      }

      print("Playing audio from: $audioPath");

      await player.setAsset(audioPath);
      await player.setLoopMode(LoopMode.one);
      player.play();

      // Sync with video controller if any
      _controllers[index]?.addListener(() {
        if (!_controllers[index]!.value.isPlaying) {
          player.pause();
        } else if (!player.playing) {
          player.play();
        }
      });
    } catch (e) {
      print("Audio playback error: $e");
    }
  } 
  */

  // Function to cache videos in the background
  void _cacheVideosInBackground({required int startFromIndex}) async {
    for (int i = startFromIndex; i < _filteredVideos.length; i++) {
      if (_controllers.containsKey(i)) continue; // already cached

      var videoData = _filteredVideos[i].data() as Map<String, dynamic>;
      var videoUrl = videoData['reelsVideo'];

      final filePath = await _cacheVideo(videoUrl); // Cache video
      if (filePath != null) {
        final tempController = VideoPlayerController.file(File(filePath));

        try {
          await tempController.initialize();
          await tempController.setLooping(true);
          await tempController.setVolume(0);
          await tempController.dispose();
        } catch (e) {
          print('Failed to cache video at $i: $e');
        }
      }
    }
  }

  /* String formatSearchQuery(String query) {
    if (query.isEmpty) return query;
    return query[0].toUpperCase() + query.substring(1).toLowerCase();
  }

  String generateSearchText(Map<String, dynamic> data) {
    final amenities = (data['amenities'] as List?)?.join(' ') ?? '';
    final parts = [
      data['city'],
      data['country'],
      data['address'],
      data['description'],
      data['type'],
      amenities,
    ];
    return parts.whereType<String>().map((s) => s.toLowerCase()).join(' ');
  }. */

  // Function to handle search filtering based on postings data
  String formatSearchQuery(String query) {
    if (query.isEmpty) return query;
    return query[0].toUpperCase() + query.substring(1).toLowerCase();
  }

  // Function to handle search filtering based on postings data
  void _filterVideos() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredVideos = _allVideos.where((video) {
          final data = video.data() as Map<String, dynamic>;
          final premium = data['premium'] ?? 0;
          return premium > 0;
        }).toList();
      });
      return;
    }

    final queryWords =
        query.split(RegExp(r'\s+')).map((e) => e.trim()).toList();

    setState(() {
      _filteredVideos = _allVideos.where((video) {
        final data = video.data() as Map<String, dynamic>;
        final premium = data['premium'] ?? 0;

        if (premium == 0) return false;

        final List<String> keywords = (data['searchText'] as List?)
                ?.map((e) => e.toString().toLowerCase())
                .toList() ??
            [];

        return queryWords.any((word) =>
            keywords.contains(word) ||
            keywords.any((k) => k.contains(word))); // More flexible
      }).toList();
    });
  }

  @override
  void dispose() {
    // Stop and dispose all audio players
    _audioPlayers.forEach((key, player) {
      player.stop();
      player.dispose();
    });
    _audioPlayers.clear();

    // Dispose all video controllers
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    _controllers.clear();

    _pageController.dispose();

    super.dispose();
  }

  // Clear cache when refreshing
  Future<void> _clearCache() async {
    // Dispose of all controllers and audio players
    _controllers.forEach((key, controller) => controller.dispose());
    _audioPlayers.forEach((key, player) => player.dispose());

    // Clear the maps holding the controllers and audio players
    _controllers.clear();
    _audioPlayers.clear();
  }

  // Function to handle the refresh action
  Future<void> _refreshVideos() async {
    // Clear the cache first
    await _clearCache();

    // Reload videos from Firestore
    await _loadVideos();
  }

  Widget _buildNoResults() {
    return Center(
      child: Text(
        'No videos found for your search',
        style: TextStyle(fontSize: 14, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshVideos, // Trigger refresh when pulled
            child: _filteredVideos.isEmpty
                ? Center(child: _buildNoResults())
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _filteredVideos.length,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index) async {
                      // Pause previous video and audio
                      if (_controllers[_currentIndex]?.value.isPlaying ??
                          false) {
                        _controllers[_currentIndex]?.pause();
                      }
                      await _audioPlayers[_currentIndex]?.pause();

                      _currentIndex = index;

                      _incrementViewCountIfNeeded(_filteredVideos[index].id);

                      // Preload the current video
                      await _preloadVideo(index); // ✅ Wait for preload

                      // Optionally preload nearby
                      _preloadVideo(index + 1);
                      _preloadVideo(index - 1);

                      _cleanupFarControllers(index);

                      // Play the current video after ensuring it's initialized
                      final controller = _controllers[index];

                      if (controller != null) {
                        if (!controller.value.isInitialized) {
                          try {
                            await controller.initialize();
                          } catch (e) {
                            print("Failed to initialize controller: $e");
                            return;
                          }
                        }

                        var videoData = _filteredVideos[index].data()
                            as Map<String, dynamic>;
                        var premium = videoData['premium'] ?? 0;

                        if (premium == 6) {
                          controller.setVolume(1.0);
                        } else if (premium == 5) {
                          controller.setVolume(0.0);
                        } else if (premium >= 3) {
                          controller.setVolume(_isMuted ? 0.0 : 1.0);
                        } else {
                          controller.setVolume(0.0);
                        }

                        controller.play();
                      }

                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      var videoData =
                          _filteredVideos[index].data() as Map<String, dynamic>;
                      return VideoReelsItem(
                        controller: _controllers[index],
                        videoData: videoData,
                        isMuted: _isMuted,
                        documentId: _filteredVideos[index].id, // <–– NEW!
                        audioName: videoData['audioName'], // Pass audio name
                        onToggleMute: () {
                          setState(() {
                            _isMuted = !_isMuted;
                            _controllers[_currentIndex]
                                ?.setVolume(_isMuted ? 0.0 : 1.0);
                          });
                        },
                      );
                    },
                  ),
          ),

          // Top-right positioned icon button
          Positioned(
            top: 50, // adjust for status bar
            right: 16,
            child: IconButton(
              icon: Icon(Icons.home, size: 40, color: Colors.pinkAccent),
              onPressed: () async {
                await _stopAllAudio(); // ✅ ensures audio stops
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GuestHomeScreen()),
                );
              },
            ),
          ),
          // Display audio name at the top left

          if (_isSearchVisible)
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _filterVideos(); // Filter the cached videos based on the search query
                },
                style: TextStyle(
                    color: Colors.white), // Text color inside the field
                decoration: InputDecoration(
                  hintText: 'Find cots by city, state or country',
                  hintStyle: TextStyle(
                      color: Colors.white60), // Lighter color for hint text
                  filled: true,
                  fillColor: Colors.black, // Background color of the TextField
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.pinkAccent,
                        width: 2), // Pink accent border
                    borderRadius:
                        BorderRadius.circular(8), // Optional: rounded corners
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close,
                        color: Colors.white), // Close icon in white
                    onPressed: () {
                      setState(() {
                        _isSearchVisible = false;
                        _filteredVideos =
                            _allVideos; // Reset to show all videos
                      });
                    },
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16, // Position the "Ask AI" button to the right
            top: MediaQuery.of(context).size.height / 1.85 -
                30, // Center vertically
            child: GestureDetector(
              onTap: () async {
                await _stopAllAudio();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CotmindChat(), // Replace with your target screen
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // To ensure the column doesn't take up more space than needed
                crossAxisAlignment: CrossAxisAlignment
                    .center, // Align items in the middle horizontally
                children: [
                  Image.asset(
                    'images/assistant.png',
                    height: 50,
                  ),
                  //SizedBox(height: 6), // Add spacing between image and text
                  Text(
                    "Ask AI",
                    style: TextStyle(
                      color: Color(0xFFFAA111),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isSearchVisible = !_isSearchVisible;
          });
        },
        backgroundColor: Colors.black, // Set the background color to black
        child: Icon(
          _isSearchVisible ? Icons.close : Icons.search,
          color: Colors.white, // Set the icon color to white
        ),
      ),
    );
  }
}

class VideoReelsItem extends StatefulWidget {
  final VideoPlayerController? controller;
  final Map<String, dynamic> videoData;
  final bool isMuted;
  final String documentId;
  final VoidCallback onToggleMute;
  final String audioName;

  VideoReelsItem({
    required this.controller,
    required this.videoData,
    required this.isMuted,
    required this.documentId, // <–– ADD THIS
    required this.onToggleMute,
    required this.audioName,
  });

  @override
  _VideoReelsItemState createState() => _VideoReelsItemState();
}

class _VideoReelsItemState extends State<VideoReelsItem> {
  int likes = 0;
  bool liked = false;
  bool showHeart = false;
  late String uid;
  MemoryImage? displayImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    likes = widget.videoData['likes'] ?? 0;
    uid = widget.videoData['uid'];
    getImageFromStorage(uid);
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final likeRef = FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.documentId)
        .collection('likes')
        .doc(AppConstants.currentUser.id);

    final likeSnapshot = await likeRef.get();

    if (mounted) {
      setState(() {
        liked = likeSnapshot.exists;
      });
    }
  }

// Call PHP backend to send push notification
  Future<void> sendLikePushNotification(String token, String reelId) async {
    final String phpUrl = 'https://cotmade.com/fire/send_fcm2.php';

    // Compose notification title and body
    final url = Uri.parse('$phpUrl?token=$token');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('Like push notification sent');
      } else {
        print('Failed to send like push: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling PHP push backend: $e');
    }
  }

  void _toggleLike() async {
    final reelRef =
        FirebaseFirestore.instance.collection('reels').doc(widget.documentId);
    final likeRef =
        reelRef.collection('likes').doc(AppConstants.currentUser.id);

    final likeSnapshot = await likeRef.get();
    final alreadyLiked = likeSnapshot.exists;

    setState(() {
      liked = !alreadyLiked;
      likes += liked ? 1 : -1;
      showHeart = true;
    });

    if (!alreadyLiked) {
      // Add like record
      await likeRef.set({
        'userId': AppConstants.currentUser.id,
        'likedAt': DateTime.now(),
      });

      // Atomically increment or decrement the like count
      await reelRef.update({
        'likes': FieldValue.increment(liked ? 1 : -1),
      });

      if (liked) {
        try {
          // Fetch reel owner user ID from reel document
          final reelSnapshot = await reelRef.get();
          final ownerId = reelSnapshot.data()?['postingId'];

          if (ownerId != null) {
            // Fetch owner's FCM token
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(ownerId)
                .get();
            final fcmToken = userDoc.data()?['fcmToken'];

            if (fcmToken != null && fcmToken.isNotEmpty) {
              await sendLikePushNotification(fcmToken, widget.documentId);
            } else {
              print('Owner FCM token not found');
            }
          }
        } catch (e) {
          print('Error sending like notification: $e');
        }
      } else {
        // Remove like record
        await likeRef.delete();

        // Decrement like count
        await reelRef.update({
          'likes': FieldValue.increment(-1),
        });
      }

      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  void _shareVideo() async {
    setState(() => _isLoading = true);

    final caption = widget.videoData['caption'] ?? '';
    final email = widget.videoData['email'] ?? '';
    final firstName = email.split('@')[0];
    final linkUrl = 'https://cotmade.com/app?param=${widget.documentId}';

    final message = '''
    *$caption*

    👤 Posted by: *$firstName*

    🔗 View & Book here:
    $linkUrl
    ''';

    try {
      final postingId = widget.videoData['postingId'];
      final posting = PostingModel(id: postingId);
      await posting.getPostingInfoFromFirestore();

      if (posting.imageNames == null || posting.imageNames!.isEmpty) {
        Share.share(message);
        return;
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('postingImages')
          .child(postingId)
          .child(posting.imageNames!.first);
      final rawData = await ref.getData(1024 * 1024);

      if (rawData == null) {
        Share.share(message);
        return;
      }

      final original = img.decodeImage(rawData);
      if (original == null) {
        Share.share(message);
        return;
      }

      final minSize =
          original.width < original.height ? original.width : original.height;

      final square = img.copyCrop(
        original,
        x: (original.width - minSize) ~/ 2,
        y: (original.height - minSize) ~/ 2,
        width: minSize,
        height: minSize,
      );

      final thumbnail = img.copyResize(square, width: 300, height: 300);
      final jpgData = img.encodeJpg(thumbnail, quality: 85);

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/thumb_share.jpg';
      final file = File(filePath)..writeAsBytesSync(jpgData);

      await Share.shareXFiles([XFile(file.path)], text: message);
    } catch (e) {
      print('🚨 Error sharing image: $e');
      Share.share(message);
    } finally {
      // Always turn off the loader
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _pausePlayVideo() {
    if (widget.controller != null) {
      if (widget.controller!.value.isPlaying) {
        widget.controller!.pause();
      } else {
        widget.controller!.play();
      }
    }
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.report),
              title: Text('Report'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedbackScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text('Block User'),
              onTap: () {
                _blockUser();
              },
            ),
          ],
        );
      },
    );
  }

  void _blockUser() {
    Get.snackbar("Blocked", "User has been blocked.");
  }

  void _handleLink(BuildContext context, String linkUrl) async {
    if (linkUrl.startsWith('http://') || linkUrl.startsWith('https://')) {
      // Open URL in internal WebView
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: linkUrl,
            title: "",
          ),
        ),
      );
    } else {
      // Treat as WhatsApp number
      final phoneNumber = linkUrl.replaceAll(RegExp(r'[^+\d]'), '');
      final whatsappUrl = Uri.parse('https://wa.me/$phoneNumber');

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    // Extracting audioName from the videoData
    final audioName = widget.videoData['audioName'] ?? "Unknown Audio";

    return GestureDetector(
      onDoubleTap: _toggleLike,
      onLongPress: _pausePlayVideo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: widget.controller!.value.size.width,
                height: widget.controller!.value.size.height,
                child: VideoPlayer(widget.controller!),
              ),
            ),
          ),
          Positioned(
            top: 70, // Adjust position as necessary
            left: 16,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.6, // 60% of screen width
              ), // Adjust max width as needed
              child: Text(
                widget.audioName.split('.')[0],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis, // Show "..." if too long
                maxLines: 1, // Keep it to one line
                softWrap: false,
              ),
            ),
          ),
          if (showHeart) Icon(Icons.favorite, color: Colors.red, size: 100),
          Positioned(
            bottom: 60,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      int premium =
                          widget.videoData['premium'] ?? 0; // fallback if null
                      if (premium <= 3) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserProfilePage(uid: widget.videoData['uid']),
                          ),
                        );
                      } else {
                        // Do nothing or show a message
                        print('Navigation disabled for premium=4 reels');
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.videoData['email'].split('@')[0],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.videoData['caption'],
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('postings')
                              .doc(widget.videoData['postingId'])
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return Text('Error loading posting data');
                            }

                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;

                            final premium = widget.videoData['premium'] ?? 0;

                            // var review = data['reviews'] ??
                            []; // Default to an empty list if null
                            //  int numberOfReviews = review.length;
                            final price = data['price'] ?? 'unknown';
                            final city = data['city'] ?? 'Unknown City';
                            final currency = data['currency'] ?? 'unknown';
                            final country =
                                data['country'] ?? 'Unknown Country';

                            // Function to format only the price (without affecting currency)
                            String formatPrice(price) {
                              var formatter = NumberFormat('#,##0',
                                  'en_US'); // No decimals (whole number only)
                              return formatter.format(price);
                            }

                            return Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (premium != 5 && premium != 6) ...[
                                    Text(
                                      'Price: $currency ${formatPrice(price)}/night',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '$city',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '$country',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ],
                                  SizedBox(height: 8),
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('postings')
                                        .doc(widget.videoData['postingId'])
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (snapshot.hasError ||
                                          !snapshot.hasData) {
                                        return Text(
                                            'Error loading posting data');
                                      }

                                      DocumentSnapshot postingSnapshot =
                                          snapshot.data!;
                                      PostingModel cPosting = PostingModel(
                                          id: widget.videoData['postingId']);
                                      cPosting.getPostingInfoFromSnapshot(
                                          postingSnapshot);

                                      int premium =
                                          widget.videoData['premium'] ?? 0;

                                      if (premium <= 3) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ViewPostingScreen(
                                                        posting: cPosting),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 8),
                                            color: Colors.pinkAccent,
                                            child: Text(
                                              'Book Now',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else if (premium == 5 || premium == 6) {
                                        final String? linkUrl = widget
                                                .videoData[
                                            'linkUrl']; // make sure this field exists
                                        final int views =
                                            widget.videoData['views'] ??
                                                0; // Fetch views safely
                                        if (linkUrl != null &&
                                            linkUrl.isNotEmpty) {
                                          return GestureDetector(
                                            onTap: () {
                                              _handleLink(context, linkUrl);
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8, horizontal: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.pinkAccent
                                                    .withOpacity(
                                                        0.2), // 20% opacity pink
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.5),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'Visit',
                                                    style: TextStyle(
                                                      color: Colors.pinkAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  SizedBox(height: 3),
                                                  Text(
                                                    '$views views',
                                                    style: TextStyle(
                                                      color: Colors.pinkAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else {
                                          final int views =
                                              widget.videoData['views'] ?? 0;
                                          return Text(
                                            '$views views',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ); // No button if no link
                                        }
                                      } else {
                                        return SizedBox
                                            .shrink(); // No button for premium 4 or others
                                      }
                                    },
                                  ),
                                  //  SizedBox(height: 8),
                                  //   Text(
                                  //    '$numberOfReviews Reviews',
                                  //    style: TextStyle(
                                  //     color: Colors.white,
                                  //    fontSize: 16,
                                  //   ),
                                  //  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        int premium = widget.videoData['premium'] ??
                            0; // fallback if null
                        if (premium <= 3) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UserProfilePage(uid: widget.videoData['uid']),
                            ),
                          );
                        } else {
                          // Do nothing or show a message
                          print('Navigation disabled for premium=4 reels');
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.black,
                        radius: 30,
                        child: displayImage != null
                            ? CircleAvatar(
                                backgroundImage: displayImage,
                                radius: 29,
                              )
                            : Icon(
                                Icons.account_circle,
                                size: 30,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    SizedBox(height: 10),
                    IconButton(
                      icon: Icon(
                        liked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                        color: liked ? Colors.pinkAccent : Colors.white,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text('$likes', style: TextStyle(color: Colors.white)),
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.white),
                      onPressed: _shareVideo,
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.white),
                      onPressed: _showMoreOptions,
                    ),
                    Opacity(
                      opacity: 0.0,
                      child: IconButton(
                        icon: Icon(
                          Icons.volume_off,
                          color: Colors.white,
                        ),
                        onPressed: widget.onToggleMute,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
