import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeIn,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Maintain exact 380x560 ratio or scale proportionally
              final double containerWidth = constraints.maxWidth > 380
                  ? 380
                  : constraints.maxWidth;
              final double containerHeight = containerWidth * (560 / 380);

              return Container(
                width: containerWidth,
                height: containerHeight,
                clipBehavior: Clip.antiAlias,
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
                child: Stack(
                  children: [
                    // Description Text
                    Positioned(
                      left: containerWidth * (36 / 380),
                      top: containerHeight * (393 / 560),
                      child: SizedBox(
                        width: containerWidth * (307 / 380),
                        height: containerHeight * (45 / 560),
                        child: Text(
                          'Lorem ipsum dolor sit amet consectetur adipiscing elit. Dolor sit amet consectetur adipiscing elit quisque faucibus.Lorem ipsum dolor sit amet consectetur adipiscing elit.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: containerWidth * (12 / 380),
                            fontFamily: 'Source Sans Pro',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),

                    // Get Started Button Background
                    Positioned(
                      left: containerWidth * (30 / 380),
                      top: containerHeight * (478 / 560),
                      child: GestureDetector(
                        onTap: _completeOnboarding,
                        child: Container(
                          width: containerWidth * (323 / 380),
                          height: containerHeight * (40 / 560),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFFC50F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                containerWidth * (10 / 380),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Get Started Button Text
                    Positioned(
                      left: containerWidth * (148 / 380),
                      top: containerHeight * (487 / 560),
                      child: GestureDetector(
                        onTap: _completeOnboarding,
                        child: Text(
                          'Get Started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF5B532C),
                            fontSize: containerWidth * (16 / 380),
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Title Text
                    Positioned(
                      left: containerWidth * (98 / 380),
                      top: containerHeight * (349 / 560),
                      child: SizedBox(
                        width:
                            containerWidth - (containerWidth * (98 / 380) * 2),
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
                    ),

                    // Image Container
                    Positioned(
                      left: containerWidth * (122 / 380),
                      top: containerHeight * (228 / 560),
                      child: Container(
                        width: containerWidth * (135 / 380),
                        height: containerWidth * (135 / 380),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage("assets/Silkreto-Logo.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
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
