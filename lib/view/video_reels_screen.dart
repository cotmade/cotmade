import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:share/share.dart';
import 'package:cotmade/view/guestScreens/user_profile_page.dart';

class VideoReelsPage extends StatefulWidget {
  @override
  _VideoReelsPageState createState() => _VideoReelsPageState();
}

class _VideoReelsPageState extends State<VideoReelsPage> {
  late PageController _pageController;
  List<DocumentSnapshot> _videos = [];
  Map<int, FlickManager> _controllers = {};
  int _currentIndex = 0;
  bool _isMuted = false;

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
      _preloadVideo(0);
      if (_videos.length > 1) _preloadVideo(1);
    }
  }

  void _preloadVideo(int index) {
    if (index < 0 || index >= _videos.length) return;
    if (!_controllers.containsKey(index)) {
      var videoData = _videos[index].data() as Map<String, dynamic>;
      var videoUrl = videoData['reelsVideo'];

      _controllers[index] = FlickManager(
        videoPlayerController: VideoPlayerController.network(videoUrl)
          ..setLooping(true)
          ..initialize().then((_) {
            if (_isMuted) {
              _controllers[index]
                  ?.flickVideoManager
                  ?.videoPlayerController
                  ?.setVolume(0.0);
            }
            setState(() {});
          }),
      );
    }
  }

  void _onPageChanged(int index) {
    if (_controllers.containsKey(_currentIndex)) {
      _controllers[_currentIndex]?.flickControlManager?.pause();
    }

    setState(() {
      _currentIndex = index;
    });

    if (_controllers.containsKey(index)) {
      _controllers[index]?.flickControlManager?.play();
    } else {
      _preloadVideo(index);
    }

    if (index < _videos.length - 1) _preloadVideo(index + 1);
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
                  flickManager: _controllers[index],
                  videoData: videoData,
                  isMuted: _isMuted,
                  onToggleMute: () {
                    setState(() {
                      _isMuted = !_isMuted;
                      _controllers[_currentIndex]
                          ?.flickVideoManager
                          ?.videoPlayerController
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
  final FlickManager? flickManager;
  final Map<String, dynamic> videoData;
  final bool isMuted;
  final VoidCallback onToggleMute;

  VideoReelsItem({
    required this.flickManager,
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
    var controller =
        widget.flickManager?.flickVideoManager?.videoPlayerController;
    if (controller != null) {
      if (controller.value.isPlaying) {
        widget.flickManager?.flickControlManager?.pause();
      } else {
        widget.flickManager?.flickControlManager?.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flickManager == null) {
      return Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onDoubleTap: _toggleLike,
      onLongPress: _pausePlayVideo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FlickVideoPlayer(flickManager: widget.flickManager!),
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
                                UserProfilePage(uid: widget.videoData['uid']))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.videoData['email'].split('@')[0],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                        SizedBox(height: 8),
                        Text(widget.videoData['caption'],
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                        icon: Icon(
                            widget.isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white),
                        onPressed: widget.onToggleMute),
                    IconButton(
                        icon: Icon(
                            liked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                            color: liked ? Colors.blue : Colors.white),
                        onPressed: _toggleLike),
                    Text('$likes', style: TextStyle(color: Colors.white)),
                    IconButton(
                        icon: Icon(Icons.share, color: Colors.white),
                        onPressed: _shareVideo),
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
