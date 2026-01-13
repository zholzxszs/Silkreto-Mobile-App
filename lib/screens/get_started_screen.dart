import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  Future<void> _requestPermissions() async {
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }

    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }

    if (await Permission.camera.isGranted && await Permission.storage.isGranted) {
      _completeOnboarding();
    } else {
      // Handle the case where the user denies the permissions
      // You can show a dialog explaining why the permissions are needed
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF63A361),
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeIn,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(0.50, -0.00),
              end: const Alignment(0.50, 1.00),
              colors: const [Color(0xFF63A361), Color(0xFF253D24)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = constraints.maxWidth > 380.0
                  ? 380.0
                  : constraints.maxWidth;
              final containerHeight = containerWidth * (560 / 380);

              return Stack(
                children: [
                  // Position at bottom
                  Positioned(
                    bottom: 0,
                    left: (constraints.maxWidth - containerWidth) / 2,
                    child: SizedBox(
                      width: containerWidth,
                      height: containerHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Logo with spacing
                          Container(
                            width: containerWidth * (135 / 380),
                            height: containerWidth * (110 / 380),
                            margin: EdgeInsets.only(
                              bottom:
                                  containerHeight * (5 / 560), // Added spacing
                            ),
                            child: Image.asset(
                              "assets/Silkreto-Logo.png",
                              fit: BoxFit.contain,
                            ),
                          ),

                          // Title with spacing
                          Container(
                            margin: EdgeInsets.only(
                              bottom:
                                  containerHeight * (5 / 560), // Added spacing
                            ),
                            child: Text(
                              'SILKRETO',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: containerWidth * (32 / 380),
                                fontWeight: FontWeight.w900,
                                letterSpacing: containerWidth * (3.20 / 380),
                              ),
                            ),
                          ),

                          // Description with better spacing
                          Container(
                            width: containerWidth * (350 / 380),
                            margin: EdgeInsets.only(
                              bottom: containerHeight * (32 / 560),
                              left: containerWidth * (15 / 380),
                              right: containerWidth * (15 / 380),
                            ),
                            child: Text(
                              'Lorem ipsum dolor sit amet consectetur adipiscing elit. Dolor sit amet consectetur adipiscing elit quisque faucibus.Lorem ipsum dolor sit amet consectetur adipiscing elit.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.sourceSansPro(
                                color: Colors.white,
                                fontSize:
                                    containerWidth *
                                    (13 / 380), // Slightly larger
                                fontWeight: FontWeight.w400,
                                height: 1.4, // Better line spacing
                              ),
                            ),
                          ),

                          // Button with spacing
                          Container(
                            margin: EdgeInsets.only(
                              bottom:
                                  containerHeight *
                                  (60 / 560), // Added bottom spacing
                            ),
                            child: GestureDetector(
                              onTap: _requestPermissions,
                              child: Container(
                                width: containerWidth * (323 / 380),
                                height:
                                    containerHeight *
                                    (48 / 560), // Slightly taller
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC50F),
                                  borderRadius: BorderRadius.circular(
                                    containerWidth *
                                        (15 / 380), // Slightly more rounded
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Get Started',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF5B532C),
                                      fontSize:
                                          containerWidth *
                                          (17 / 380), // Slightly larger
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
