import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cotmade/view/data/firestor.dart';
import 'package:cotmade/view/data/image_cached.dart';
import 'package:cotmade/view/widgets/like_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReelsItem extends StatefulWidget {
  final snapshot;
  const ReelsItem(this.snapshot, {super.key});

  @override
  _ReelsItemState createState() => _ReelsItemState();
}

class _ReelsItemState extends State<ReelsItem> {
  late VideoPlayerController controller;
  bool play = true;
  bool isAnimating = false;
  String user = '';
  bool isVisible = false; // Track visibility
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser!.uid;
    // Initialize the video controller
    controller = VideoPlayerController.network(widget.snapshot['reelsvideo'])
      ..initialize().then((value) {
        setState(() {
          controller.setLooping(true); // Loop the video
          controller.setVolume(1); // Set volume to 1
          if (isVisible) {
            controller.play(); // Play video if it's visible
          }
        });
      });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose(); // Dispose the video controller
  }

  // Play or pause the video depending on the current state
  void _togglePlayPause() {
    setState(() {
      play = !play;
      if (play) {
        controller.play();
      } else {
        controller.pause();
      }
    });
  }

  // Double-tap to like the video
  void _onDoubleTap() {
    Firebase_Firestor().like(
        like: widget.snapshot['like'],
        type: 'reels',
        uid: user,
        postId: widget.snapshot['postId']);
    setState(() {
      isAnimating = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.snapshot['postId']), // Ensure uniqueness
      onVisibilityChanged: (info) {
        // If more than 50% of the video is visible, start playing
        if (info.visibleFraction > 0.5) {
          if (!isVisible) {
            setState(() {
              isVisible = true;
            });
            controller.play();
          }
        } else {
          if (isVisible) {
            setState(() {
              isVisible = false;
            });
            controller.pause();
          }
        }
      },
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          GestureDetector(
            onDoubleTap: _onDoubleTap, // Double-tap to like
            onTap: _togglePlayPause, // Tap to play/pause
            child: Container(
              width: double.infinity,
              height: 812.h,
              child: VideoPlayer(controller),
            ),
          ),
          if (!play)
            Center(
              child: CircleAvatar(
                backgroundColor: Colors.white30,
                radius: 35.r,
                child: Icon(
                  Icons.play_arrow,
                  size: 35.w,
                  color: Colors.white,
                ),
              ),
            ),
          Center(
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              opacity: isAnimating ? 1 : 0,
              child: LikeAnimation(
                child: Icon(
                  Icons.favorite,
                  size: 100.w,
                  color: Colors.pinkAccent,
                ),
                isAnimating: isAnimating,
                duration: Duration(milliseconds: 400),
                iconlike: false,
                End: () {
                  setState(() {
                    isAnimating = false;
                  });
                },
              ),
            ),
          ),
          Positioned(
            top: 430.h,
            right: 15.w,
            child: Column(
              children: [
                LikeAnimation(
                  child: IconButton(
                    onPressed: () {
                      Firebase_Firestor().like(
                          like: widget.snapshot['like'],
                          type: 'reels',
                          uid: user,
                          postId: widget.snapshot['postId']);
                    },
                    icon: Icon(
                      widget.snapshot['like'].contains(user)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.snapshot['like'].contains(user)
                          ? Colors.red
                          : Colors.white,
                      size: 24.w,
                    ),
                  ),
                  isAnimating: widget.snapshot['like'].contains(user),
                ),
                SizedBox(height: 3.h),
                Text(
                  widget.snapshot['like'].length.toString(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40.h,
            left: 10.w,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        height: 35.h,
                        width: 35.w,
                        child: CachedImage(widget.snapshot['profileImage']),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      widget.snapshot['firstName'],
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Container(
                      alignment: Alignment.center,
                      width: 60.w,
                      height: 25.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: Text(
                        'Follow',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  widget.snapshot['caption'],
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
