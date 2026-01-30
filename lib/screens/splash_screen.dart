import 'package:flutter/material.dart';
import 'package:silkreto/screens/home_screen.dart';

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
    _runSplashSequence();
  }

  Future<void> _runSplashSequence() async {
    // Fade IN (slower)
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _opacity = 1.0);

    // Hold (longer, calmer)
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;

    // Fade OUT (gentler)
    setState(() => _opacity = 0.0);

    // Wait for fade-out
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (_, animation, __, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );

          final slide =
              Tween<Offset>(
                begin: const Offset(0, 0.035), // smaller movement = smoother
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/silkreto-logo-bg.jpg'),
              fit: BoxFit.fitHeight, // ✅ less "zoom" than cover
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}
