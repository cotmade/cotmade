import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cotmade/view/guestScreens/user_profile_page.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/guestScreens/feedback_screen.dart';
import 'package:flutter_cached_video_player_plus/flutter_cached_video_player_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cotmade/view/ai/cotmind_chat.dart';
import 'package:cotmade/view/guest_home_screen.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VideoReelsPage extends StatefulWidget {
  final String? reelId;
  const VideoReelsPage({this.reelId, Key? key}) : super(key: key);

  @override
  _VideoReelsPageState createState() => _VideoReelsPageState();
}

class _VideoReelsPageState extends State<VideoReelsPage> {
  late PageController _pageController;
  List<DocumentSnapshot> _videos = [];
  Map<int, CachedVideoPlayerController> _controllers = {}; // ✅ unify type
  Map<int, AudioPlayer> _audioPlayers = {};
  int _currentIndex = 0;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reels')
        .orderBy('time', descending: true)
        .get();

    setState(() {
      _videos = snapshot.docs;
    });

    if (_videos.isNotEmpty) {
      _preloadVideo(0);
    }
  }

  Future<void> _preloadVideo(int index) async {
    if (index < 0 || index >= _videos.length) return;
    if (_controllers.containsKey(index)) return;

    final data = _videos[index].data() as Map<String, dynamic>;
    final url = data['reelsVideo'];

    final controller = CachedVideoPlayerController.network(url); // ✅ always cached
    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(_isMuted ? 0 : 1);

    setState(() {
      _controllers[index] = controller;
    });

    if (index == _currentIndex) {
      controller.play();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final a in _audioPlayers.values) {
      a.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length,
              onPageChanged: (index) {
                _controllers[_currentIndex]?.pause();
                _currentIndex = index;
                _preloadVideo(index);
              },
              itemBuilder: (context, index) {
                final data = _videos[index].data() as Map<String, dynamic>;
                final controller = _controllers[index];

                if (controller == null || !controller.value.isInitialized) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: kIsWeb
                            ? VideoPlayer(controller) // ✅ plain video on web
                            : CachedVideoPlayer(controller), // ✅ cached on mobile
                      ),
                    ),
                    Positioned(
                      top: 50,
                      right: 16,
                      child: IconButton(
                        icon: Icon(
                          Icons.volume_off,
                          color: _isMuted ? Colors.red : Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isMuted = !_isMuted;
                            controller.setVolume(_isMuted ? 0 : 1);
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class VideoReelsItem extends StatefulWidget {
  final CachedVideoPlayerController? controller; // ✅ unified
  final Map<String, dynamic> videoData;
  final bool isMuted;
  final String documentId;
  final VoidCallback onToggleMute;
  final String audioName;
  final VoidCallback stopAudio;

  const VideoReelsItem({
    Key? key,
    required this.controller,
    required this.videoData,
    required this.isMuted,
    required this.documentId,
    required this.onToggleMute,
    required this.audioName,
    required this.stopAudio,
  }) : super(key: key);

  @override
  _VideoReelsItemState createState() => _VideoReelsItemState();
}

class _VideoReelsItemState extends State<VideoReelsItem> {
  int likes = 0;
  bool liked = false;
  bool showHeart = false;
  MemoryImage? displayImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    likes = widget.videoData['likes'] ?? 0;
    _checkIfLiked();
    _loadUserImage(widget.videoData['uid']);
  }

  Future<void> _checkIfLiked() async {
    final likeRef = FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.documentId)
        .collection('likes')
        .doc(AppConstants.currentUser.id);

    final likeSnapshot = await likeRef.get();
    if (mounted) setState(() => liked = likeSnapshot.exists);
  }

  Future<void> _loadUserImage(String uid) async {
    try {
      final bytes = await FirebaseStorage.instance
          .ref()
          .child("userImages")
          .child(uid)
          .child("$uid.png")
          .getData(1024 * 1024);
      if (bytes != null) setState(() => displayImage = MemoryImage(bytes));
    } catch (_) {}
  }

  void _toggleLike() async {
    final reelRef =
        FirebaseFirestore.instance.collection('reels').doc(widget.documentId);
    final likeRef =
        reelRef.collection('likes').doc(AppConstants.currentUser.id);

    final snap = await likeRef.get();
    final alreadyLiked = snap.exists;

    setState(() {
      liked = !alreadyLiked;
      likes += liked ? 1 : -1;
      showHeart = true;
    });

    if (alreadyLiked) {
      await likeRef.delete();
      await reelRef.update({'likes': FieldValue.increment(-1)});
    } else {
      await likeRef.set({
        'userId': AppConstants.currentUser.id,
        'likedAt': DateTime.now(),
      });
      await reelRef.update({'likes': FieldValue.increment(1)});
    }

    Future.delayed(const Duration(milliseconds: 500),
        () => mounted ? setState(() => showHeart = false) : null);
  }

  Future<void> _shareVideo() async {
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
      if (kIsWeb) {
        await Share.share("$caption\n\n$linkUrl");
      } else {
        Share.share(message);
      }
    } catch (e) {
      Share.share(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _pausePlayVideo() {
    if (widget.controller != null) {
      widget.controller!.value.isPlaying
          ? widget.controller!.pause()
          : widget.controller!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final videoWidget = kIsWeb
        ? VideoPlayer(widget.controller!)
        : CachedVideoPlayer(widget.controller!);

    return GestureDetector(
      onDoubleTap: _toggleLike,
      onLongPress: _pausePlayVideo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FittedBox(fit: BoxFit.cover, child: videoWidget),
          ),
          if (showHeart)
            const Icon(Icons.favorite, color: Colors.red, size: 100),
          Positioned(
            bottom: 60,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    widget.videoData['caption'] ?? '',
                    style: const TextStyle(color: Colors.white),
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
                    Text('$likes',
                        style: const TextStyle(color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: _shareVideo,
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
