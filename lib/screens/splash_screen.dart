import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _navigateToNextScreen();
  }

  void _startAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/getStarted');
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

              return Center(
                child: Container(
                  width: containerWidth,
                  height: containerHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo centered
                      Container(
                        width: containerWidth * (135 / 380),
                        height: containerWidth * (110 / 380),
                        margin: EdgeInsets.only(
                          bottom: containerHeight * (15 / 560),
                        ),
                        child: Image.asset(
                          'assets/Silkreto-Logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Title centered
                      Text(
                        'SILKRETO',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: containerWidth * (32 / 380),
                          fontWeight: FontWeight.w900,
                          letterSpacing: containerWidth * (3.20 / 380),
                        ),
                      ),
                    ],
                  ),
                ),
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
