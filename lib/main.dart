import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_section.dart';
import 'screens/upload_section.dart';
import 'screens/history_section.dart';

void main() {
  // Optional: lock orientation early (many apps do this)
  WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SILKRETO',
      debugShowCheckedModeBanner: false, // ← usually turned off in production
      // Theme - you can make this more complete
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B5B95),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Nunito', // ← if you're using Google Fonts everywhere
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6B5B95),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),

      // Optional: dark theme support (can be toggled later)
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B5B95),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      themeMode: ThemeMode.light, // or ThemeMode.system / ThemeMode.dark
      // Initial route instead of home → more flexible
      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/scan': (context) => const ScanSection(),
        '/upload': (context) => const UploadSection(),
        '/history': (context) => const HistorySection(),
      },

      // Good practice: handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text(
                '404 - Route not found\n\n${settings.name}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
