import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:share/share.dart';
import 'package:cotmade/view/guestScreens/user_profile_page.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/unregisteredScreens/view_post_screen.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/unregisteredScreens/userprofile_screen.dart';
import 'package:cotmade/view/login_screen.dart';

class ViewVideoScreen extends StatefulWidget {
  @override
  _ViewVideoScreenState createState() => _ViewVideoScreenState();
}

class _ViewVideoScreenState extends State<ViewVideoScreen> {
  late PageController _pageController;
  List<DocumentSnapshot> _videos = [];
  Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reels')
        .orderBy('time', descending: true)
        .get();

    setState(() {
      _videos = snapshot.docs;
    });

    if (_videos.isNotEmpty) {
      for (int i = 0; i <= 3 && i < _videos.length; i++) {
        _preloadVideo(i);
      }
    }
  }

  void _preloadVideo(int index) {
    if (index < 0 || index >= _videos.length || _controllers.containsKey(index))
      return;

    var videoData = _videos[index].data() as Map<String, dynamic>;
    var videoUrl = videoData['reelsVideo'];

    final controller = VideoPlayerController.network(videoUrl);
    _controllers[index] = controller;

    controller.setLooping(true);
    controller.setVolume(_isMuted ? 0.0 : 1.0);

    controller.initialize().then((_) {
      setState(() {});
      if (index == _currentIndex) {
        Future.delayed(Duration(milliseconds: 300), () {
          controller.play();
        });
      }
    });
  }

  void _onPageChanged(int index) {
    _controllers[_currentIndex]?.pause();

    setState(() {
      _currentIndex = index;
    });

    _controllers[index]?.play();

    for (int i = index - 3; i <= index + 3; i++) {
      if (i == index) continue;
      _preloadVideo(i);
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
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
  final VideoPlayerController? controller;
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
    setState(() {
      liked = !liked;
      likes += liked ? 1 : -1;
      showHeart = true;
    });
    await FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.videoData['id'])
        .update({'likes': likes});
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
                        LoginScreen(), // Assuming FeedbackPage is your report page
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
    Get.snackbar("Login", "kindly login to block this user");
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
                child: VideoPlayer(widget.controller!),
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
                            UserProfilePagee(uid: widget.videoData['uid']),
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
                                        ViewPostScreen(posting: cPosting),
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
