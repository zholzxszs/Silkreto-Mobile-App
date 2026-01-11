import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/get_started_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_section.dart';
import 'screens/upload_section.dart';
import 'screens/history_section.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SILKRETO',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B5B95)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/getStarted': (context) => const GetStartedScreen(),
        '/home': (context) => const HomeScreen(),
        '/scan': (context) => const ScanSection(),
        '/upload': (context) => const UploadSection(),
        '/history': (context) => const HistorySection(),
      },
    );
  }
}
