import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:cotmade/view/splash_screen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isFirstTime = true;
  int _currentIndex = 0; // Index to track current image/text
  late Timer _timer;

  // List of primary texts and images
  final List<String> _texts = [
    'Welcome to CotMade',
    'Siyakwamukela eCotMade',
    'Akwaaba kɔ CotMade',
  ];

  final List<String> _images = [
    'images/nig.png', // First image
    'images/South_Africa.png', // Second image
    'images/ghanapng.png', // Third image
  ];

  // Secondary list of texts
  final List<String> _secondaryTexts = [
    'Experience home away from home',
    'Zizwele ekhaya ngaphandle kwekhaya',
    'Bɔkɔɔ a ɛda ho sɛ ofie',
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _startChangeContentTimer();
  }

  // Start the timer to change the content every 2 seconds
  void _startChangeContentTimer() {
    _timer = Timer.periodic(Duration(seconds: 2), _changeContent);
  }

  // Change content (text and image) on each timer tick
  void _changeContent(Timer timer) {
    setState(() {
      _currentIndex =
          (_currentIndex + 1) % _texts.length; // Loop back to the first index
    });
  }

  Future<void> _checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      setState(() {
        _isFirstTime = true;
      });
    } else {
      setState(() {
        _isFirstTime = false;
      });
    }
  }

  Future<void> _markOnboardingComplete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFirstTime', false);
    setState(() {
      _isFirstTime = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isFirstTime ? _buildOnboardingContent() : SplashScreen(),
    );
  }

  Widget _buildOnboardingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Static image centered on the screen
          SizedBox(
            height: 40,
          ),
          Center(
            child: Image.asset(
              'images/onboard.png',
              fit: BoxFit.contain,
              height: MediaQuery.of(context).size.height * 0.5,
            ).animate().fadeIn().scale().move(
                  delay: 800.ms,
                  duration: 600.ms,
                ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.asset(
                  _images[_currentIndex], // Dynamically change the image
                  width: 40,
                  height: 30,
                ),
              ),
              SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _texts[_currentIndex], // Alternating texts
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          // Welcome message (using the primary list or secondary list)

          SizedBox(height: 20),
          Text(
            _secondaryTexts[_currentIndex],
            style: TextStyle(fontSize: 16),
          ),
          Spacer(), // Push the button to the bottom
          // Start button at the bottom
          Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 55,
                    width: MediaQuery.of(context).size.width *
                        0.3, // 30% of the screen width (adjust as needed)
                    child: ElevatedButton(
                      onPressed: _markOnboardingComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.black, // Button background color
                        foregroundColor: Colors.white, // Text color
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ))),
        ],
      ),
    );
  }
}
