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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _opacity = 1.0);
    });
  }

  Future<void> _handleGetStarted() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Friendly explanation dialog before asking for permissions
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Needed'),
        content: const Text(
          'Silkreto needs access to:\n\n'
          '• Camera — to scan silkworm images\n'
          '• Photos & Storage — to upload and save images\n\n'
          'You can change these permissions later in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) {
      setState(() => _isLoading = false);
      return;
    }

    // Request permissions
    final statuses = await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();

    // Optional: you can check if all are granted and show message if not
    statuses.values.every((status) => status.isGranted);

    // Save onboarding flag (even if permissions denied — user can grant later)
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.50, -0.00),
              end: Alignment(0.50, 1.00),
              colors: [Color(0xFF63A361), Color(0xFF253D24)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = constraints.maxWidth > 380
                  ? 380.0
                  : constraints.maxWidth;
              final containerHeight = containerWidth * (560 / 380);

              return Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    left: (constraints.maxWidth - containerWidth) / 2,
                    child: SizedBox(
                      width: containerWidth,
                      height: containerHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: containerWidth * (135 / 380),
                            height: containerWidth * (110 / 380),
                            margin: EdgeInsets.only(
                              bottom: containerHeight * (5 / 560),
                            ),
                            child: Image.asset(
                              "assets/Silkreto-Logo.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(
                              bottom: containerHeight * (5 / 560),
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
                          Container(
                            width: containerWidth * (350 / 380),
                            margin: EdgeInsets.only(
                              bottom: containerHeight * (32 / 560),
                              left: containerWidth * (15 / 380),
                              right: containerWidth * (15 / 380),
                            ),
                            child: Text(
                              'Monitor silkworm health, detect diseases early, '
                              'and improve your sericulture with AI-powered scanning.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.sourceSansPro(
                                color: Colors.white,
                                fontSize: containerWidth * (13 / 380),
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(
                              bottom: containerHeight * (60 / 560),
                            ),
                            child: GestureDetector(
                              onTap: _isLoading ? null : _handleGetStarted,
                              child: Container(
                                width: containerWidth * (323 / 380),
                                height: containerHeight * (48 / 560),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC50F),
                                  borderRadius: BorderRadius.circular(
                                    containerWidth * (15 / 380),
                                  ),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF5B532C),
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : Text(
                                          'Get Started',
                                          style: GoogleFonts.nunito(
                                            color: const Color(0xFF5B532C),
                                            fontSize:
                                                containerWidth * (17 / 380),
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
}
