import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share/share.dart';
import 'package:cotmade/view/guestScreens/user_profile_page.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:get/get.dart';
//import 'package:cotmade/view/unregisteredScreens/view_post_screen.dart';
import 'package:cotmade/view/guestScreens/feedback_screen.dart';
import 'package:cotmade/view/guestScreens/video_cache_manager.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cached_video_player_plus/flutter_cached_video_player_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class VideoReelsPage extends StatefulWidget {
  @override
  _VideoReelsPageState createState() => _VideoReelsPageState();
}

class _VideoReelsPageState extends State<VideoReelsPage> {
  late PageController _pageController;
  List<DocumentSnapshot> _videos = [];
  Map<int, CachedVideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _isMuted = true;

  Directory? _cacheDir;
  Set<String> _cachedVideoIds = {}; // track cached videos by ID

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initCacheDirAndLoad();
  }

  Future<void> _initCacheDirAndLoad() async {
    _cacheDir = await getApplicationDocumentsDirectory();
    await _loadVideosAndSyncCache();
  }

  /// Load videos from Firestore and sync cache folder
  Future<void> _loadVideosAndSyncCache() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reels')
        .orderBy('time', descending: true)
        .get();

    final freshVideos = snapshot.docs;
    final freshIds = freshVideos.map((doc) => doc.id).toSet();

    await _deleteRemovedCachedVideos(freshIds);

    setState(() {
      _videos = freshVideos;
    });

    await _downloadNewVideos(freshVideos);

    // Preload first few videos for smooth playback
    for (int i = 0; i < _videos.length && i < 4; i++) {
      await _initController(i);
    }
  }

  /// Delete cached files not found in Firestore anymore
  Future<void> _deleteRemovedCachedVideos(Set<String> freshIds) async {
    if (_cacheDir == null) return;

    final files = _cacheDir!.listSync();

    for (var fileEntity in files) {
      if (fileEntity is File) {
        final filename = path.basename(fileEntity.path); // e.g. "abc123.mp4"
        final videoId = path.basenameWithoutExtension(filename);
        if (!freshIds.contains(videoId)) {
          try {
            await fileEntity.delete();
            _cachedVideoIds.remove(videoId);
            print('Deleted cached video: $filename');
          } catch (e) {
            print('Failed to delete cached video $filename: $e');
          }
        } else {
          _cachedVideoIds.add(videoId);
        }
      }
    }
  }

  /// Download videos not yet cached
  Future<void> _downloadNewVideos(List<DocumentSnapshot> videos) async {
    if (_cacheDir == null) return;

    for (var doc in videos) {
      final videoId = doc.id;
      final videoData = doc.data() as Map<String, dynamic>;
      final videoUrl = videoData['reelsVideo'] as String;

      // Extract extension from URL, handle query params
      final ext = path.extension(videoUrl).split('?').first;
      final filePath = '${_cacheDir!.path}/$videoId$ext';

      if (_cachedVideoIds.contains(videoId)) continue; // Already cached

      final file = File(filePath);
      if (await file.exists()) {
        _cachedVideoIds.add(videoId);
        continue; // Exists locally
      }

      try {
        print('Downloading video $videoId...');
        final response = await http.get(Uri.parse(videoUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          _cachedVideoIds.add(videoId);
          print('Downloaded and cached video $videoId');
        } else {
          print('Failed to download video $videoId: HTTP ${response.statusCode}');
        }
      } catch (e) {
        print('Error downloading video $videoId: $e');
      }
    }
  }

  /// Initialize controller, load cached file if exists otherwise network
  Future<void> _initController(int index) async {
    if (index < 0 || index >= _videos.length) return;
    if (_controllers.containsKey(index)) return;

    var doc = _videos[index];
    var videoData = doc.data() as Map<String, dynamic>;
    var videoUrl = videoData['reelsVideo'] as String;
    var videoId = doc.id;

    File? localFile;
    if (_cacheDir != null) {
      final cachedFiles = _cacheDir!.listSync().whereType<File>();
      for (final file in cachedFiles) {
        final filename = path.basename(file.path);
        final basename = path.basenameWithoutExtension(filename);
        if (basename == videoId) {
          localFile = file;
          break;
        }
      }
    }

    CachedVideoPlayerController controller;
    if (localFile != null) {
      controller = CachedVideoPlayerController.file(localFile);
    } else {
      controller = CachedVideoPlayerController.network(videoUrl);
    }

    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(_isMuted ? 0.0 : 1.0);

    _controllers[index] = controller;

    if (index == _currentIndex) {
      Future.delayed(Duration(milliseconds: 300), () {
        controller.play();
      });
    }

    setState(() {});
  }

  void _onPageChanged(int index) async {
    _controllers[_currentIndex]?.pause();

    setState(() {
      _currentIndex = index;
    });

    if (_controllers[index] != null) {
      _controllers[index]!.play();
    } else {
      await _initController(index);
      _controllers[index]?.play();
    }

    // Preload neighbors
    for (int i = index - 3; i <= index + 3; i++) {
      if (i < 0 || i >= _videos.length) continue;
      _initController(i);
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, c) => c.dispose());
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videos.isEmpty
          ? Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              itemCount: _videos.length,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                var videoData = _videos[index].data() as Map<String, dynamic>;
                return VideoReelsItem(
                  controller: _controllers[index],
                  videoData: videoData,
                  isMuted: _isMuted,
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
    );
  }
}

class VideoReelsItem extends StatefulWidget {
  final CachedVideoPlayerController? controller;
 // final VideoPlayerController? controller;
  final Map<String, dynamic> videoData;
  final bool isMuted;
  final VoidCallback onToggleMute;

  VideoReelsItem({
    required this.controller,
    required this.videoData,
    required this.isMuted,
    required this.onToggleMute,
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

  // Show the options menu (Report and Block User)
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
                // Navigate to the Feedback page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FeedbackScreen(), // Assuming FeedbackPage is your report page
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text('Block User'),
              onTap: () {
                // Handle the Block User functionality here
                _blockUser();
              },
            ),
          ],
        );
      },
    );
  }

  // Block user logic (e.g., mark the user as blocked in Firestore)
  void _blockUser() {
    // You can add logic here to block the user (update Firestore, etc.)
    Get.snackbar("Blocked", "user has been blocked");
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

                            DocumentSnapshot postingSnapshot = snapshot.data!;
                            PostingModel cPosting =
                                PostingModel(id: widget.videoData['postingId']);
                            cPosting
                                .getPostingInfoFromSnapshot(postingSnapshot);

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ViewPostingScreen(posting: cPosting),
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
                        widget.isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                      onPressed: widget.onToggleMute,
                    ),
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
                      onPressed: _showMoreOptions, // Show the three dots menu
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
