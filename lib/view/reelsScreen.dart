import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:visibility_detector/visibility_detector.dart';

class Reel {
  final String id;
  final String firstName;
  final String caption;
  final String reelsvideo;
  final int like;

  Reel({
    required this.id,
    required this.firstName,
    required this.caption,
    required this.reelsvideo,
    required this.like,
  });
}

class ReelScreen extends StatefulWidget {
  const ReelScreen({Key? key}) : super(key: key);

  @override
  _ReelScreenState createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen> {
  final List<Reel> reels = [];
  bool _isLoading = true;
  bool isError = false;
  final CacheManager _cacheManager =
      DefaultCacheManager(); // Initialize CacheManager

  @override
  void initState() {
    super.initState();
    _fetchReels();
  }

  Future<void> _fetchReels() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reels')
          .orderBy('timestamp')
          .limit(10)
          .get();

      List<Reel> fetchedReels = snapshot.docs.map((doc) {
        return Reel(
          id: doc.id,
          caption: doc['caption'],
          firstName: doc['firstName'],
          reelsvideo: doc['reelsvideo'],
          like: doc['like'],
        );
      }).toList();

      setState(() {
        _isLoading = false;
        reels.addAll(fetchedReels);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        isError = true;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching reels: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reels')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : isError
              ? Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isError = false;
                        _fetchReels();
                      });
                    },
                    child: Text('Retry'),
                  ),
                )
              : ListView.builder(
                  itemCount: reels.length,
                  itemBuilder: (context, index) {
                    // Pass the CacheManager to each ReelCard
                    return ReelCard(
                        reel: reels[index], cacheManager: _cacheManager);
                  },
                ),
    );
  }
}

class ReelCard extends StatefulWidget {
  final Reel reel;
  final CacheManager cacheManager; // Add cacheManager parameter

  const ReelCard({Key? key, required this.reel, required this.cacheManager})
      : super(key: key);

  @override
  _ReelCardState createState() => _ReelCardState();
}

class _ReelCardState extends State<ReelCard> {
  late VideoPlayerController _controller;
  bool isLiked = false;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Check if video is cached
      final file =
          await widget.cacheManager.getSingleFile(widget.reel.reelsvideo);

      // Initialize video player
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});
        });
    } catch (e) {
      setState(() {
        isError = true;
      });
    }
  }

  void _likeReel() async {
    try {
      await FirebaseFirestore.instance
          .collection('reels')
          .doc(widget.reel.id)
          .update({
        'likes': widget.reel.like + (isLiked ? -1 : 1),
      });
      setState(() {
        isLiked = !isLiked;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error liking reel: $e')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.reel.id),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5 && !_controller.value.isPlaying) {
          _controller.play();
        } else if (info.visibleFraction == 0) {
          _controller.pause();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Player Widget
              if (_controller.value.isInitialized)
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              else
                Center(child: CircularProgressIndicator()),

              // Caption and User Info
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reel.firstName,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 5),
                    Text(
                      widget.reel.caption,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "${widget.reel.like} like",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Like Button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: _likeReel,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isLiked ? Colors.red : Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.white : Colors.black,
                        ),
                        SizedBox(width: 8),
                        Text(
                          isLiked ? 'Liked' : 'Like',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isLiked ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
