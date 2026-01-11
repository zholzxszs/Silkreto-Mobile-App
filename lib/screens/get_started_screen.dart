import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  int _currentPage = 0;
  late PageController _pageController;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to SILKRETO',
      description: 'Organize your fashion like never before',
      image: Icons.checkroom,
      backgroundColor: const Color(0xFF6B5B95),
    ),
    OnboardingPage(
      title: 'Manage Your Style',
      description: 'Create outfits, track trends, and express yourself',
      image: Icons.palette,
      backgroundColor: const Color(0xFF8B7BA8),
    ),
    OnboardingPage(
      title: 'Get Started Now',
      description: 'Begin your journey to the perfect wardrobe',
      image: Icons.star,
      backgroundColor: const Color(0xFF6B5B95),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            return _buildOnboardingPage(_pages[index]);
          },
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Container(
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
          // Description Text
          Positioned(
            left: 36,
            top: 393,
            child: SizedBox(
              width: 307,
              height: 45,
              child: Text(
                page.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Source Sans Pro',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          // Get Started Button Background
          Positioned(
            left: 30,
            top: 478,
            child: Container(
              width: 323,
              height: 40,
              decoration: ShapeDecoration(
                color: const Color(0xFFFFC50F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // Get Started Button Text
          Positioned(
            left: 148,
            top: 487,
            child: GestureDetector(
              onTap: () {
                if (_currentPage == _pages.length - 1) {
                  _completeOnboarding();
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: const Text(
                'Get Started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5B532C),
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Title Text
          Positioned(
            left: 98,
            top: 349,
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                letterSpacing: 3.20,
              ),
            ),
          ),
          // Image Container
          Positioned(
            left: 122,
            top: 228,
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
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData image;
  final Color backgroundColor;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.backgroundColor,
  });
}
