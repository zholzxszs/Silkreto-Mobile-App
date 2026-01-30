import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _startAnimation();
    _navigateToHome();
  }

  void _startAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  Future<void> _navigateToHome() async {
    // Give time for logo fade-in + pleasant short wait
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Smooth fade + slight scale transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.92;
          const end = 1.0;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var scaleAnimation = animation.drive(tween);

          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
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
              final containerWidth = constraints.maxWidth > 380.0
                  ? 380.0
                  : constraints.maxWidth;
              final containerHeight = containerWidth * (560 / 380);

              return Center(
                child: SizedBox(
                  width: containerWidth,
                  height: containerHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
}
