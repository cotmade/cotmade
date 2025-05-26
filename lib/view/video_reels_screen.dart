import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share/share.dart';
import 'package:cotmade/view/guestScreens/user_profile_page.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/guestScreens/feedback_screen.dart';
import 'package:cotmade/view/guestScreens/video_cache_manager.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cached_video_player_plus/flutter_cached_video_player_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:audioplayers/audioplayers.dart';

class VideoReelsPage extends StatefulWidget {
  @override
  _VideoReelsPageState createState() => _VideoReelsPageState();
}

class _VideoReelsPageState extends State<VideoReelsPage> {
  late PageController _pageController;
  List<DocumentSnapshot> _allVideos = []; // Store all videos in memory as cache
  List<DocumentSnapshot> _filteredVideos = [];
  Map<int, CachedVideoPlayerController> _controllers = {};
  Map<int, AudioPlayer> _audioPlayers = {};
  int _currentIndex = 0;
  bool _isMuted = true;
  bool _isSearchVisible = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadVideos(); // Load videos from Firestore initially
  }

  // Function to load videos from Firestore and cache them locally
  Future<void> _loadVideos() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reels')
        .orderBy('time', descending: true)
        .get();

    setState(() {
      _allVideos = snapshot.docs; // Cache all videos locally
      _filteredVideos = _allVideos; // Initially, show all videos
    });

    // Preload first 4 videos from the cache
    for (int i = 0; i <= 3 && i < _filteredVideos.length; i++) {
      _preloadVideo(i);
    }

    // Start background caching for the rest of the videos
    _cacheVideosInBackground(startFromIndex: 4);
  }

  // Function to preload videos from the cache
  void _preloadVideo(int index) async {
    if (index < 0 ||
        index >= _filteredVideos.length ||
        _controllers.containsKey(index)) return;

    var videoData = _filteredVideos[index].data() as Map<String, dynamic>;
    var videoUrl = videoData['reelsVideo'];
    var audioName = videoData['audioName'];

    final controller = CachedVideoPlayerController.network(videoUrl);
    _controllers[index] = controller;

    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(0.0); // Muting video sound

    // Play the audio from the assets
    _playAudio(index, audioName);

    setState(() {});

    if (index == _currentIndex) {
      Future.delayed(Duration(milliseconds: 300), () {
        controller.play();
      });
    }
    // Add listener to stop audio when video ends
    controller.addListener(() {
      if (!controller.value.isPlaying) {
        // Stop the audio when the video finishes
        _audioPlayers[index]?.stop();
      }
    });

    // Add another listener to pause audio when video pauses
    controller.addListener(() {
      if (controller.value.position == controller.value.duration) {
        _audioPlayers[index]?.stop();
      }
    });
  }

  // Play audio from assets
  void _playAudio(int index, String audioName) {
    AudioPlayer audioPlayer = AudioPlayer();
    _audioPlayers[index] = audioPlayer;

    // Load and play the audio from assets
    audioPlayer.play(AssetSource('audio/$audioName'));

    // Sync the audio to stop when the video ends
    _controllers[index]?.addListener(() {
      if (!_controllers[index]!.value.isPlaying) {
        _audioPlayers[index]?.stop(); // Stop audio when the video ends
      }

      // Ensure the audio stops at the right point
      if (_controllers[index]!.value.position ==
          _controllers[index]!.value.duration) {
        _audioPlayers[index]?.stop();
      }
    });
  }

  // Function to cache videos in the background
  void _cacheVideosInBackground({required int startFromIndex}) async {
    for (int i = startFromIndex; i < _filteredVideos.length; i++) {
      if (_controllers.containsKey(i)) continue; // already cached

      var videoData = _filteredVideos[i].data() as Map<String, dynamic>;
      var videoUrl = videoData['reelsVideo'];

      final tempController = CachedVideoPlayerController.network(videoUrl);

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

  String formatSearchQuery(String query) {
    if (query.isEmpty) return query;
    return query[0].toUpperCase() + query.substring(1).toLowerCase();
  }

  // Function to handle search filtering based on postings data
  Future<void> _filterVideos() async {
    String queryText = formatSearchQuery(_searchController.text);
    if (queryText.isEmpty) {
      setState(() {
        _filteredVideos = _allVideos; // Show all videos if query is empty
      });
      return;
    }

    // Step 1: Query the postings collection to get matching postingIds based on country, city, or address
    QuerySnapshot postingsSnapshot = await FirebaseFirestore.instance
        .collection('postings')
        .where('country', isGreaterThanOrEqualTo: queryText)
        .where('country', isLessThanOrEqualTo: queryText + '\uf8ff')
        .get();

    // Step 2: Get all matching postingIds from the postings collection
    List<String> matchingPostingIds = [];
    postingsSnapshot.docs.forEach((doc) {
      var data = doc.data() as Map<String, dynamic>;
      matchingPostingIds.add(data['id']);
    });

    // Step 3: Filter the cached videos based on the matching postingIds
    setState(() {
      _filteredVideos = _allVideos.where((video) {
        var videoData = video.data() as Map<String, dynamic>;
        return matchingPostingIds.contains(videoData['postingId']);
      }).toList();
    });
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _audioPlayers.forEach((key, player) => player.dispose());
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadVideos, // Trigger refresh when pulled
            child: _filteredVideos.isEmpty
                ? Center(child: CircularProgressIndicator())
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _filteredVideos.length,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index) {
                      _currentIndex = index;
                      _preloadVideo(index); // Preload the current video
                    },
                    itemBuilder: (context, index) {
                      var videoData =
                          _filteredVideos[index].data() as Map<String, dynamic>;
                      return VideoReelsItem(
                        controller: _controllers[index],
                        videoData: videoData,
                        isMuted: _isMuted,
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
                  hintText: 'Search...',
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
  final CachedVideoPlayerController? controller;
  final Map<String, dynamic> videoData;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final String audioName;

  VideoReelsItem({
    required this.controller,
    required this.videoData,
    required this.isMuted,
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

  @override
  void initState() {
    super.initState();
    likes = widget.videoData['likes'] ?? 0;
  }

  void _toggleLike() async {
    final reelRef = FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.videoData['id']);

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
    Get.snackbar("Blocked", "User has been blocked");
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

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
                child: CachedVideoPlayer(widget.controller!),
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserProfilePage(uid: widget.videoData['uid']),
                      ),
                    ),
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

                            final city = data['city'] ?? 'Unknown City';
                            final country =
                                data['country'] ?? 'Unknown Country';

                            return Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$city\n $country',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ViewPostingScreen(
                                                  posting: PostingModel(
                                                      id: widget.videoData[
                                                          'postingId'])),
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
                                  ),
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
                    IconButton(
                      icon: Icon(
                        widget.isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                      onPressed: widget.onToggleMute,
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
