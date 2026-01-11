import 'package:flutter/material.dart';
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

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (mounted) {
      if (hasSeenOnboarding) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/getStarted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final containerWidth = screenSize.width > 380 ? 380.0 : screenSize.width;
    final containerHeight = containerWidth * (560 / 380);

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
              colors: const [
                Color(0xFF63A361), // #63A361
                Color(0xFF253D24), // #253D24
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: containerWidth,
              height: containerHeight,
              child: Stack(
                children: [
                  // Logo Image
                  Positioned(
                    left: containerWidth * (122 / 380),
                    top: containerHeight * (230 / 560),
                    child: Container(
                      width: containerWidth * (135 / 380),
                      height: containerWidth * (135 / 380),
                      child: Image.asset(
                        'assets/Silkreto-Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // SILKRETO Text
                  Positioned(
                    left: 0,
                    right: 0,
                    top: containerHeight * (380 / 560),
                    child: Text(
                      'SILKRETO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: containerWidth * (32 / 380),
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        letterSpacing: containerWidth * (3.20 / 380),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
