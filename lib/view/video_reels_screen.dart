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
import 'package:cotmade/view/ai/cotmind_services.dart';
import 'package:cotmade/view/ai/cotmind_chat_page.dart';

class VideoReelsPage extends StatefulWidget {
  @override
  _VideoReelsPageState createState() => _VideoReelsPageState();
}

class _VideoReelsPageState extends State<VideoReelsPage> {
  late PageController _pageController;
  List<DocumentSnapshot> _allVideos = []; // Store all videos in memory as cache
  List<DocumentSnapshot> _filteredVideos = [];
  Map<int, VideoPlayerController> _controllers = {};
  Map<int, AudioPlayer> _audioPlayers = {};
  int _currentIndex = 0;
  bool _isMuted = true;
  bool _isSearchVisible = false;
  TextEditingController _searchController = TextEditingController();
  Set<String> _viewedVideoIds = {};
  final cacheManager = DefaultCacheManager(); // Cache manager for videos
  String _locationHint = '';
  String _displayedHint = '';
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadVideos(); // Load videos from Firestore initially
    _initializeCotmind();
  }

  Future<void> _initializeCotmind() async {
    await CotmindService.loadDynamicSynonyms();
  }

  // Function to load videos from Firestore and cache them locally
  Future<void> _loadVideos() async {
    FirebaseFirestore.instance
        .collection('reels')
        .orderBy('time', descending: true)
        .get()
        .then((snapshot) {
      _allVideos = snapshot.docs;
      _filteredVideos = _allVideos;

      setState(() {}); // Show UI immediately

      // Preload first 4 videos in parallel
      for (int i = 0; i <= 3 && i < _filteredVideos.length; i++) {
        _preloadVideo(i);
      }

      // Cache rest in background
      _cacheVideosInBackground(startFromIndex: 4);
    });
  }

  // Function to preload videos from the cacheimages
  void _preloadVideo(int index) async {
    if (index < 0 ||
        index >= _filteredVideos.length ||
        _controllers.containsKey(index)) return;

    var videoData = _filteredVideos[index].data() as Map<String, dynamic>;
    var videoUrl = videoData['reelsVideo'];
    var audioName = videoData['audioName'];
    var premium = videoData['premium'] ?? 0; // ✅ Get premium from reels doc

    final filePath = await _cacheVideo(videoUrl); // Cache video
    if (filePath != null) {
      final controller = VideoPlayerController.file(File(filePath));
      _controllers[index] = controller;

      await controller.initialize();
      controller.setLooping(true);
      // ✅ Volume control based on premium
      if (controller.value.isInitialized) {
        // Ensure volume is set based on premium and mute status
        if (premium >= 3) {
          controller.setVolume(
              1.0); // Play the original video sound, but respect mute status
        } else {
          controller
              .setVolume(0.0); // Mute video sound when premium is less than 3
        }

        // Play the video
        controller.play();
      }

      // controller.setVolume(0.0); // Muting video sound
      // Stop previous audio if any
      //  _stopAudioForPreviousVideo(index);

      // Play the audio from the assets
      // Play the audio from the assets
      if (premium < 3 && audioName != null && audioName.isNotEmpty) {
        //   _playAudio(index, audioName);
      }

      setState(() {});

      if (index == _currentIndex) {
        Future.delayed(Duration(milliseconds: 300), () {
          controller.play();
        });
      }

      // Add listener to stop audio when video ends
      //   controller.addListener(() {
      //    if (!controller.value.isPlaying) {
      // Stop the audio when the video finishes
      //      _audioPlayers[index]?.stop();
      //    }
      //  });

      // Add another listener to paus audio when video pauses
      //  controller.addListener(() {
      //   if (controller.value.position == controller.value.duration) {
      //     _audioPlayers[index]?.stop();
    }
    //  });
    //  }
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

      print("Play audio from: $audioPath");

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

  String formatSearchQuery(String query) {
    if (query.isEmpty) return query;
    return query[0].toUpperCase() + query.substring(1).toLowerCase();
  }

  // Function to handle search filtering based on postings data
  Future<void> _filterVideos() async {
    String rawQuery = _searchController.text.trim();

    if (rawQuery.isEmpty) {
      setState(() {
        _filteredVideos = _allVideos;
        _locationHint = '';
        _displayedHint = '';
      });
      return;
    }

    String queryText = formatSearchQuery(rawQuery);

    // Log search + normalize inputs
    await CotmindService.logSearch(queryText);

    final normalizedCity = await CotmindService.normalizeCity(queryText);
    final normalizedCountry = await CotmindService.normalizeCountry(queryText);

    // Try to get city tip first; fallback to country
    String hint = await CotmindService.getTip(normalizedCity, isCity: true);

    // Optional fallback if city tip is not meaningful
    if (hint.trim().isEmpty || hint.contains("No tips")) {
      hint = await CotmindService.getTip(normalizedCountry, isCity: false);
    }

    // Show hint if it changed
    if (_locationHint != hint) {
      setState(() {
        _locationHint = hint;
        _displayedHint = '';
      });
      _startTypewriterEffect();
    }

    // Get matching postings
    final cityPostings = await FirebaseFirestore.instance
        .collection('postings')
        .where('city', isEqualTo: normalizedCity)
        .get();

    final countryPostings = await FirebaseFirestore.instance
        .collection('postings')
        .where('country', isEqualTo: normalizedCountry)
        .get();

    final matchingPostingIds = <String>{};
    for (var doc in cityPostings.docs) matchingPostingIds.add(doc.id);
    for (var doc in countryPostings.docs) matchingPostingIds.add(doc.id);

    // Filter video list based on matching postings
    setState(() {
      _filteredVideos = _allVideos.where((video) {
        final data = video.data() as Map<String, dynamic>;
        return matchingPostingIds.contains(data['postingId']);
      }).toList();
    });
  }

  void _startTypewriterEffect() {
    _typewriterTimer?.cancel();
    int i = 0;
    const prefix = '⎔'; // Cotmind's logo/icon
    _displayedHint = prefix; // start with logo

    _typewriterTimer = Timer.periodic(Duration(milliseconds: 40), (timer) {
      if (i < _locationHint.length) {
        setState(() {
          _displayedHint += _locationHint[i];
        });
        i++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
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
      body: Stack(children: [
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
                    if (_controllers[_currentIndex]?.value.isPlaying ?? false) {
                      _controllers[_currentIndex]?.pause();
                    }
                    await _audioPlayers[_currentIndex]?.pause();

                    _currentIndex = index;

                    _incrementViewCountIfNeeded(_filteredVideos[index].id);

                    // Preload the current video (if not preloaded)
                    _preloadVideo(index);

                    // Play the current video
                    final controller = _controllers[index];
                    if (controller != null && controller.value.isInitialized) {
                      // ✅ Set the volume based on premium and _isMuted
                      var videoData =
                          _filteredVideos[index].data() as Map<String, dynamic>;
                      var premium = videoData['premium'] ??
                          0; // Get premium from the video data

                      if (premium >= 3) {
                        // Premium users can hear audio, so adjust based on mute status
                        controller
                            .setVolume(1.0); // Set volume based on _isMuted
                      } else {
                        // Non-premium users: Always mute
                        controller.setVolume(0.0);
                      }

                      // Play the current video
                      controller.play();
                    }

                    // Play audio for the current video
                    final videoData =
                        _filteredVideos[index].data() as Map<String, dynamic>;
                    //  _playAudio(index, videoData['audioName']);

                    setState(() {}); // To update UI if needed
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

        // SearchBar + Hint combined in one Column
        if (_isSearchVisible)
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔍 Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _filterVideos();
                  },
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'location...',
                    hintStyle: TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.black,
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.pinkAccent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = false;
                          _searchController.clear();
                          _filteredVideos = _allVideos;
                          _locationHint = '';
                          _displayedHint = '';
                        });
                      },
                    ),
                  ),
                ),

                // 💡 Hint text just below the search bar
                if (_searchController.text.trim().isNotEmpty &&
                    _displayedHint.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Text(
                      _displayedHint,
                      style: TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          )
      ]),
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

  @override
  void initState() {
    super.initState();
    likes = widget.videoData['likes'] ?? 0;
    uid = widget.videoData['uid'];
    getImageFromStorage(uid);
  }

  void _toggleLike() async {
    final reelRef =
        FirebaseFirestore.instance.collection('reels').doc(widget.documentId);

    setState(() {
      liked = !liked;
      likes += liked ? 1 : -1;
      showHeart = true;
    });

    // Atomically increment or decrement the like count
    await reelRef.update({
      'likes': FieldValue.increment(liked ? 1 : -1),
    });

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        showHeart = false;
      });
    });
  }

  void _shareVideo() {
    Share.share('Check out this video: ${widget.videoData['reelsVideo']}');
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

                                      return GestureDetector(
                                        onTap: () async {
                                          if (premium <= 3) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ViewPostingScreen(
                                                        posting: cPosting),
                                              ),
                                            );
                                          } else {
                                            print(
                                                'Navigation disabled for premium=4 reels');
                                          }
                                        },
                                        child: premium <= 3
                                            ? Container(
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
                                              )
                                            : SizedBox
                                                .shrink(), // Empty widget if premium > 3
                                      );
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CotmindChatPage()),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 25,
                          child: Text(
                            '⎔',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )),
                    // SizedBox(height: 1),
                    Container(
                      width: 48, // Wider than the text
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      color: Colors.black, // Background color
                      child: Text(
                        'ask AI',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
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
