import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Replace with your actual home screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _navigateToNextScreen();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (mounted) {
      if (hasSeenOnboarding) {
        // User has seen onboarding, go to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // New user, show get started screen
        Navigator.of(context).pushReplacementNamed('/getStarted');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: 380,
            height: 560,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0.50, -0.00),
                end: const Alignment(0.50, 1.00),
                colors: [const Color(0xFF63A361), const Color(0xFF253D24)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 98,
                  top: 319,
                  child: Text(
                    'SILKRETO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.20,
                    ),
                  ),
                ),
                Positioned(
                  left: 122,
                  top: 198,
                  child: Container(
                    width: 135,
                    height: 135,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage("https://placehold.co/135x135"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
