import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/scan_result_model.dart';
import 'dart:ui' as ui;

class HomeSection extends StatefulWidget {
  const HomeSection({super.key});

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

Color _locationChipBg(int weatherCode) {
  // Soft translucent versions of your weather themes
  if (weatherCode == 0) return const Color(0x33FFD20F); // clear (yellow tint)
  if (weatherCode == 1 || weatherCode == 2)
    return const Color(0x33B8D4E8); // partly cloudy
  if (weatherCode == 3) return const Color(0x339BA8B8); // cloudy
  if (weatherCode == 45 || weatherCode == 48)
    return const Color(0x338B9BA8); // fog
  if (weatherCode >= 51 && weatherCode <= 67)
    return const Color(0x335B7A95); // rain
  if (weatherCode >= 71 && weatherCode <= 86)
    return const Color(0x33B8D4E8); // snow
  if (weatherCode >= 95) return const Color(0x334A5F7A); // thunderstorm
  return const Color(0x33FFD20F);
}

Color _locationChipBorder(int weatherCode) {
  if (weatherCode >= 51 && weatherCode <= 67) return const Color(0x335B7A95);
  if (weatherCode >= 95) return const Color(0x334A5F7A);
  return const Color(0x335B532C);
}

Color _locationChipTextColor(int weatherCode) {
  // darker text on bright skies, white text on dark storms/rain
  if ((weatherCode >= 51 && weatherCode <= 67) || weatherCode >= 95) {
    return Colors.white.withOpacity(0.95);
  }
  return const Color(0xFF2F2F2F);
}

class _MonthBars {
  final int monthIndex;
  final String monthLabel;
  final int healthy;
  final int diseased;

  _MonthBars({
    required this.monthIndex,
    required this.monthLabel,
    required this.healthy,
    required this.diseased,
  });
}

Widget _miniLegendDot({required Color color, required String label}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.black.withOpacity(0.65),
        ),
      ),
    ],
  );
}

class _GroupedBarChartPainter extends CustomPainter {
  final List<_MonthBars> points;
  final int maxValue;
  final double t; // animation 0..1

  _GroupedBarChartPainter({
    required this.points,
    required this.maxValue,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Layout
    final paddingTop = 6.0;
    final paddingBottom = 8.0;
    final paddingH = 4.0;

    final chartHeight = size.height - paddingTop - paddingBottom;
    final chartWidth = size.width - paddingH * 2;

    final origin = Offset(paddingH, paddingTop);

    // Subtle grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFEFEFEF)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = origin.dy + chartHeight * (i / 4);
      canvas.drawLine(
        Offset(origin.dx, y),
        Offset(origin.dx + chartWidth, y),
        gridPaint,
      );
    }

    // Bars
    final groupW = chartWidth / points.length;
    final barW = (groupW * 0.22).clamp(6.0, 14.0); // responsive
    final gap = (groupW * 0.10).clamp(3.0, 10.0);

    final healthyPaint = Paint()..color = const Color(0xFF66A060);
    final diseasedPaint = Paint()..color = const Color(0xFFE84A4A);

    // Text painters (reused)
    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );

    TextStyle labelInside(Color color) => TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      shadows: const [
        Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1)),
      ],
    );

    TextStyle labelAbove(Color color) =>
        TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900);

    for (int i = 0; i < points.length; i++) {
      final p = points[i];

      final baseX = origin.dx + groupW * i + (groupW / 2);
      final healthyX = baseX - gap / 2 - barW;
      final diseasedX = baseX + gap / 2;

      final hVal = p.healthy.toDouble();
      final dVal = p.diseased.toDouble();

      final hH = (hVal / maxValue) * chartHeight * t;
      final dH = (dVal / maxValue) * chartHeight * t;

      final r = Radius.circular(barW); // rounded top

      final hRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(healthyX, origin.dy + chartHeight - hH, barW, hH),
        topLeft: r,
        topRight: r,
      );

      final dRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(diseasedX, origin.dy + chartHeight - dH, barW, dH),
        topLeft: r,
        topRight: r,
      );

      // draw bars
      canvas.drawRRect(hRect, healthyPaint);
      canvas.drawRRect(dRect, diseasedPaint);

      // draw labels ONLY when animation is far enough so it doesn't jitter
      final showLabels = t > 0.75;

      if (showLabels) {
        // Healthy label
        _drawValueOnBar(
          canvas: canvas,
          tp: tp,
          value: p.healthy,
          barX: healthyX,
          barW: barW,
          barTopY: origin.dy + chartHeight - hH,
          barHeight: hH,
          insideStyle: labelInside(const Color(0xFF66A060)),
          aboveStyle: labelAbove(const Color(0xFF66A060)),
        );

        // Diseased label
        _drawValueOnBar(
          canvas: canvas,
          tp: tp,
          value: p.diseased,
          barX: diseasedX,
          barW: barW,
          barTopY: origin.dy + chartHeight - dH,
          barHeight: dH,
          insideStyle: labelInside(const Color(0xFFE84A4A)),
          aboveStyle: labelAbove(const Color(0xFFE84A4A)),
        );
      }
    }
  }

  void _drawValueOnBar({
    required Canvas canvas,
    required TextPainter tp,
    required int value,
    required double barX,
    required double barW,
    required double barTopY,
    required double barHeight,
    required TextStyle insideStyle,
    required TextStyle aboveStyle,
  }) {
    if (value <= 0) return; // don't show 0 labels

    final text = value.toString();

    // Decide whether to put label inside or above based on height
    // If bar is tall enough: inside near top; else above the bar
    const insidePadding = 4.0;
    const abovePadding = 3.0;

    // measure text
    tp.text = TextSpan(text: text, style: insideStyle);
    tp.layout(minWidth: 0, maxWidth: barW + 20);

    final canFitInside = barHeight >= (tp.height + 10);

    if (canFitInside) {
      // inside (white) near top area
      final dx = barX + (barW - tp.width) / 2;
      final dy = barTopY + insidePadding; // slightly below rounded top
      tp.paint(canvas, Offset(dx, dy));
    } else {
      // above (colored)
      tp.text = TextSpan(text: text, style: aboveStyle);
      tp.layout(minWidth: 0, maxWidth: barW + 20);

      final dx = barX + (barW - tp.width) / 2;
      final dy = (barTopY - tp.height - abovePadding).clamp(
        0.0,
        double.infinity,
      );
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _GroupedBarChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.t != t;
  }
}

class _WeatherSnapshot {
  final String locationLabel;
  final DateTime observedAt;
  final double temperatureC;
  final double apparentC;
  final int humidityPct;
  final double windKph;
  final int weatherCode;

  _WeatherSnapshot({
    required this.locationLabel,
    required this.observedAt,
    required this.temperatureC,
    required this.apparentC,
    required this.humidityPct,
    required this.windKph,
    required this.weatherCode,
  });
}

class _HomeSectionState extends State<HomeSection> {
  final ScrollController _scrollController = ScrollController();
  bool _navVisible = true;
  double _previousOffset = 0.0;

  // Weather state (current location)
  bool _weatherLoading = true;
  String? _weatherError;
  _WeatherSnapshot? _weather;

  List<int> _availableYears = [];
  int? _selectedYear;
  Map<String, Map<String, int>> _monthlyAnalytics = {};

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndLoadData();
    });
  }

  Future<void> _checkPermissionsAndLoadData() async {
    // Check if permissions dialog has been shown before
    final prefs = await SharedPreferences.getInstance();
    final hasShownDialog = prefs.getBool('permissions_dialog_shown') ?? false;

    // Check all permissions first
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;

    // Only show dialog once if permissions are denied and dialog hasn't been shown
    if (!hasShownDialog &&
        (cameraStatus.isDenied ||
            locationStatus.isDenied ||
            storageStatus.isDenied ||
            photosStatus.isDenied)) {
      await _showPermissionsDialog();
      // Mark dialog as shown
      await prefs.setBool('permissions_dialog_shown', true);
    }

    // Request all permissions
    await Permission.camera.request();
    await Permission.location.request();
    await Permission.storage.request();
    await Permission.photos.request();

    _loadWeather();
    _loadAnalyticsData();
  }

  Future<void> _showPermissionsDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Permissions Required',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5B532C),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SILKRETO needs the following permissions to function properly:',
                  style: GoogleFonts.sourceSansPro(
                    fontSize: 14,
                    color: const Color(0xFF5B532C),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPermissionItem(
                  Icons.camera_alt,
                  'Camera',
                  'To scan silkworm images for disease detection',
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  Icons.location_on,
                  'Location',
                  'To show local weather conditions for rearing guidance',
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  Icons.folder,
                  'Storage',
                  'To save scan results and access uploaded images',
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  Icons.photo_library,
                  'Photos',
                  'To access and upload images from your gallery',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Open app settings if permissions are permanently denied
                final cameraStatus = await Permission.camera.status;
                final locationStatus = await Permission.location.status;
                final storageStatus = await Permission.storage.status;
                final photosStatus = await Permission.photos.status;

                if (cameraStatus.isPermanentlyDenied ||
                    locationStatus.isPermanentlyDenied ||
                    storageStatus.isPermanentlyDenied ||
                    photosStatus.isPermanentlyDenied) {
                  await AppSettings.openAppSettings();
                }
              },
              child: Text(
                'Open Settings',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF63A361),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF63A361),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: const Color(0xFF63A361)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5B532C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.sourceSansPro(
                  fontSize: 12,
                  color: const Color(0xCC5B532C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadAnalyticsData() async {
    final results = await DatabaseHelper().getAllScanResults();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final years = results
        .map((r) {
          try {
            return dateFormat.parse(r.scanDate).year;
          } catch (e) {
            return null;
          }
        })
        .where((y) => y != null)
        .cast<int>()
        .toSet()
        .toList();

    years.sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    setState(() {
      _availableYears = years;
      if (years.contains(now.year)) {
        _selectedYear = now.year;
      } else if (years.isNotEmpty) {
        _selectedYear = years.first;
      }
      _processDataForYear(_selectedYear, results);
    });
  }

  // ---- Weather (API + current location) ----
  Future<void> _loadWeather() async {
    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });

    try {
      final pos = await _getCurrentPosition();
      final locationLabel = await _reverseGeocode(pos.latitude, pos.longitude);

      final snapshot = await _fetchWeather(
        pos.latitude,
        pos.longitude,
        locationLabel,
      );

      if (!mounted) return;
      setState(() {
        _weather = snapshot;
        _weatherLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherError = e.toString();
        _weatherLoading = false;
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: const Duration(seconds: 10),
    );
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return 'Current location';
      final p = placemarks.first;

      // Keep it short and friendly (City, Province/State)
      final parts = <String>[];
      if ((p.locality ?? '').trim().isNotEmpty) parts.add(p.locality!.trim());
      if ((p.administrativeArea ?? '').trim().isNotEmpty) {
        parts.add(p.administrativeArea!.trim());
      }
      if (parts.isEmpty && (p.subAdministrativeArea ?? '').trim().isNotEmpty) {
        parts.add(p.subAdministrativeArea!.trim());
      }
      return parts.isEmpty ? 'Current location' : parts.join(', ');
    } catch (_) {
      return 'Current location';
    }
  }

  Future<_WeatherSnapshot> _fetchWeather(
    double lat,
    double lon,
    String locationLabel,
  ) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code'
      '&timezone=auto',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Weather API error (${res.statusCode}).');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final current = (json['current'] as Map<String, dynamic>?);
    if (current == null) {
      throw Exception('Weather data unavailable.');
    }

    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final apparent =
        (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
    final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final code = (current['weather_code'] as num?)?.toInt() ?? 0;

    // time is ISO string
    final timeStr =
        (current['time'] as String?) ?? DateTime.now().toIso8601String();
    final observedAt = DateTime.tryParse(timeStr) ?? DateTime.now();

    return _WeatherSnapshot(
      locationLabel: locationLabel,
      observedAt: observedAt,
      temperatureC: temp,
      apparentC: apparent,
      humidityPct: humidity,
      windKph: wind,
      weatherCode: code,
    );
  }

  String _conditionLabel(int code) {
    // Open-Meteo weather codes: https://open-meteo.com/en/docs
    if (code == 0) return 'Clear';
    if (code == 1 || code == 2) return 'Partly cloudy';
    if (code == 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if (code == 51 || code == 53 || code == 55) return 'Drizzle';
    if (code == 61 || code == 63 || code == 65) return 'Rain';
    if (code == 66 || code == 67) return 'Freezing rain';
    if (code == 71 || code == 73 || code == 75) return 'Snow';
    if (code == 77) return 'Snow grains';
    if (code == 80 || code == 81 || code == 82) return 'Rain showers';
    if (code == 85 || code == 86) return 'Snow showers';
    if (code == 95) return 'Thunderstorm';
    if (code == 96 || code == 99) return 'Thunderstorm';
    return 'Weather';
  }

  LinearGradient _getWeatherGradient(int weatherCode) {
    // Clear
    if (weatherCode == 0) {
      return const LinearGradient(
        begin: Alignment(0.50, -0.00),
        end: Alignment(0.50, 1.00),
        colors: [Color(0xFFFFD20F), Color(0xFFFDE7B3)],
      );
    }
    // Partly cloudy
    if (weatherCode == 1 || weatherCode == 2) {
      return const LinearGradient(
        begin: Alignment(0.50, -0.00),
        end: Alignment(0.50, 1.00),
        colors: [Color(0xFFB8D4E8), Color(0xFFE8F1F8)],
      );
    }
    // Cloudy
    if (weatherCode == 3) {
      return const LinearGradient(
        begin: Alignment(0.50, -0.00),
        end: Alignment(0.50, 1.00),
        colors: [Color(0xFF9BA8B8), Color(0xFFD4DFE8)],
      );
    }
    // Fog
    if (weatherCode == 45 || weatherCode == 48) {
      return const LinearGradient(
        begin: Alignment(0.50, -0.00),
        end: Alignment(0.50, 1.00),
        colors: [Color(0xFF8B9BA8), Color(0xFFC5D0DC)],
      );
    }
    // Drizzle/Rain
    if (weatherCode >= 51 && weatherCode <= 67) {
      return const LinearGradient(
        begin: Alignment(0.50, -0.00),
        end: Alignment(0.50, 1.00),
        colors: [Color(0xFF5B7A95), Color(0xFFA8C5DC)],
      );
    }
    // Snow
    if (weatherCode >= 71 && weatherCode <= 86) {
      return const LinearGradient(
        begin: Alignment(0.50, -0.00),
        end: Alignment(0.50, 1.00),
        colors: [Color(0xFFB8D4E8), Color(0xFFF0F5FF)],
      );
    }
    // Thunderstorm
    if (weatherCode >= 95) {
      return const LinearGradient(
        begin: Alignment(0.50, -0.00),
        end: Alignment(0.50, 1.00),
        colors: [Color(0xFF4A5F7A), Color(0xFF7A8FA0)],
      );
    }
    // Default
    return const LinearGradient(
      begin: Alignment(0.50, -0.00),
      end: Alignment(0.50, 1.00),
      colors: [Color(0xFFFFD20F), Color(0xFFFDE7B3)],
    );
  }

  String _briefDecisionSupport(_WeatherSnapshot w) {
    final hot = w.temperatureC >= 30 || w.apparentC >= 31;
    final humid = w.humidityPct >= 75;
    final windy = w.windKph >= 20;

    if (hot && humid) {
      return 'High heat & humidity: High disease risk. Improve ventilation and reduce stocking density.';
    }
    if (hot) {
      return 'High temperature: Risk of heat stress. Increase ventilation.';
    }
    if (humid) {
      return 'High humidity: Risk of fungal disease. Reduce moisture buildup.';
    }
    if (windy) {
      return 'Strong wind: Draft risk. Strengthen enclosure sealing, minimize direct airflow, and monitor temperature stability closely.';
    }
    return 'Optimal conditions: Maintain temperature, humidity, and cleanliness.';
  }

  void _processDataForYear(int? year, List<ScanResult> allResults) {
    if (year == null) return;

    final dateFormat = DateFormat('MMM dd, yyyy');
    final yearlyResults = allResults.where((r) {
      try {
        return dateFormat.parse(r.scanDate).year == year;
      } catch (e) {
        return false;
      }
    }).toList();

    final analytics = <String, Map<String, int>>{};
    for (var result in yearlyResults) {
      try {
        final date = dateFormat.parse(result.scanDate);
        final monthName = _months[date.month - 1];

        if (!analytics.containsKey(monthName)) {
          analytics[monthName] = {'healthy': 0, 'diseased': 0};
        }

        analytics[monthName]!['healthy'] =
            (analytics[monthName]!['healthy'] ?? 0) + result.healthyCount;
        analytics[monthName]!['diseased'] =
            (analytics[monthName]!['diseased'] ?? 0) + result.diseasedCount;
      } catch (e) {
        // Ignore records with parsing errors
      }
    }

    setState(() {
      _monthlyAnalytics = analytics;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    const threshold = 6.0;
    if (offset - _previousOffset > threshold && _navVisible) {
      setState(() => _navVisible = false);
    } else if (_previousOffset - offset > threshold && !_navVisible) {
      setState(() => _navVisible = true);
    }
    _previousOffset = offset;
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Container(
              width: screenSize.width,
              constraints: BoxConstraints(minHeight: screenSize.height),
              padding: EdgeInsets.zero,
              decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Bar
                  _buildHeader(screenSize.width),
                  const SizedBox(height: 28),

                  // Weather Card
                  _buildWeatherCard(screenSize.width),
                  const SizedBox(height: 30),

                  // Explore Section
                  _buildSectionTitle('Explore'),
                  const SizedBox(height: 12),

                  // Explore Cards Grid
                  _buildExploreGrid(screenSize.width),
                  const SizedBox(height: 40),

                  // Analytics Section
                  _buildSectionTitle('Analytics'),
                  const SizedBox(height: 12),

                  // Year Dropdown
                  _buildYearDropdown(screenSize.width),
                  const SizedBox(height: 12),

                  // Line Graph Card
                  _buildBarGraphCard(screenSize.width),
                  const SizedBox(height: 40),

                  // All Months Section - Updated
                  _buildAllMonthsSection(screenSize.width),

                  // Placeholder for floating nav space
                  const SizedBox(height: 95),
                ],
              ),
            ),
          ),
          // Floating Bottom Navigation - UPDATED
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _navVisible
                ? MediaQuery.of(context).padding.bottom + 35
                : -100,
            left: 42,
            right: 42,
            child: _buildBottomNavigation(screenSize.width),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double width) {
    return Container(
      width: width,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.50, 0.00),
          end: Alignment(0.50, 1.00),
          colors: [Color(0xFF63A361), Color(0xFF253D24)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x3F000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // SILKRETO Title
          Text(
            'SILKRETO',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.90,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(double width) {
    final w = _weather;
    final gradient = w != null
        ? _getWeatherGradient(w.weatherCode)
        : const LinearGradient(
            begin: Alignment(0.50, -0.00),
            end: Alignment(0.50, 1.00),
            colors: [Color(0xFFFFD20F), Color(0xFFFDE7B3)],
          );

    return Container(
      width: width - 42,
      margin: const EdgeInsets.symmetric(horizontal: 21),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0x26000000),
            blurRadius: 12,
            offset: const Offset(4, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: _weatherLoading
            ? _buildWeatherSkeleton()
            : (_weatherError != null && w == null)
            ? _buildWeatherError()
            : _buildWeatherContent(width, w!),
      ),
    );
  }

  Widget _buildWeatherSkeleton() {
    Widget bar({double w = double.infinity, double h = 10}) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0x66FFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(w: 170, h: 18),
              const SizedBox(height: 8),
              bar(w: 120, h: 10),
              const SizedBox(height: 16),
              bar(w: 220, h: 10),
              const SizedBox(height: 6),
              bar(w: 200, h: 10),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            bar(w: 70, h: 34),
            const SizedBox(height: 10),
            bar(w: 80, h: 12),
            const SizedBox(height: 6),
            bar(w: 90, h: 10),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherError() {
    return Row(
      children: [
        const Icon(Icons.cloud_off, color: Color(0xFF5B532C)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Weather unavailable. Turn on location and try again.',
            style: GoogleFonts.sourceSansPro(
              color: const Color(0xFF5B532C),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        TextButton(
          onPressed: _loadWeather,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF5B532C),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          child: Text(
            'Retry',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherContent(double width, _WeatherSnapshot w) {
    final day = DateFormat('EEEE').format(w.observedAt).toUpperCase();
    final date = DateFormat('dd MMM, yyyy').format(w.observedAt);
    final temp = '${w.temperatureC.round()}°C';
    final feels = 'Feels like ${w.apparentC.round()}°C';
    final cond = _conditionLabel(w.weatherCode);
    final chipBg = _locationChipBg(w.weatherCode);
    final chipBorder = _locationChipBorder(w.weatherCode);
    final chipText = _locationChipTextColor(w.weatherCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location chip
        // Location chip (DYNAMIC
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: chipBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 14, color: chipText),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(
                  w.locationLabel,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sourceSansPro(
                    color: chipText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Two-column layout: Left (Date, Humidity, Wind) | Right (Temperature)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Date, Humidity, Wind
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$day\n',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF5B532C),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: date,
                          style: GoogleFonts.sourceSansPro(
                            color: const Color(0xCC5B532C),
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Humidity and Wind in same row
                  Row(
                    children: [
                      _miniPill(
                        icon: Icons.water_drop,
                        label: '${w.humidityPct}% humidity',
                        small: true,
                      ),
                      const SizedBox(width: 8),
                      _miniPill(
                        icon: Icons.air,
                        label: '${w.windKph.round()} km/h wind',
                        small: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Right Column: Temperature, Condition, Feels like
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  temp,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF5B532C),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 18),
                // Grouped: Condition and Feels like
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      cond,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF5B532C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 0),
                    Text(
                      feels,
                      style: GoogleFonts.sourceSansPro(
                        color: const Color(0xCC5B532C),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Decision support with background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x25E8D4C4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1A5B532C), width: 0.5),
          ),
          child: Text(
            _briefDecisionSupport(w),
            textAlign: TextAlign.justify,
            style: GoogleFonts.sourceSansPro(
              color: const Color(0xFF5B532C),
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniPill({
    required IconData icon,
    required String label,
    bool small = false,
  }) {
    final fontSize = small ? 9.0 : 10.5;
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final iconSize = small ? 12.0 : 14.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x225B532C)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: const Color(0xFF5B532C)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.sourceSansPro(
              color: const Color(0xFF5B532C),
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          color: const Color(0xFF5B532C),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildExploreGrid(double width) {
    final cardWidth = (width - 63) / 4;
    final exploreItems = [
      {
        'icon': 'assets/Explore/Diseases.png',
        'label': 'Diseases',
        'w': 20.0,
        'h': 21.0,
      },
      {
        'icon': 'assets/Explore/Symptoms.png',
        'label': 'Symptoms',
        'w': 23.0,
        'h': 21.0,
      },
      {
        'icon': 'assets/Explore/Prevention.png',
        'label': 'Prevention',
        'w': 17.0,
        'h': 21.0,
      },
      {
        'icon': 'assets/Explore/Rearing.png',
        'label': 'Rearing',
        'w': 21.0,
        'h': 21.0,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: exploreItems.map<Widget>((item) {
          return SizedBox(
            width: cardWidth,
            child: Column(
              children: [
                // Card with icon and label inside
                Container(
                  width: cardWidth,
                  height: cardWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x3F000000),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: item['w'] as double,
                        height: item['h'] as double,
                        child: Image.asset(
                          item['icon'] as String,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              size: 20,
                              color: const Color(0xFF5B532C),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sourceSansPro(
                          color: const Color(0xFF5B532C),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildYearDropdown(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<int>(
            value: _selectedYear,
            hint: Text('Year', style: GoogleFonts.nunito(fontSize: 12)),
            underline: const SizedBox(),
            isDense: true,
            items: _availableYears.map((int year) {
              return DropdownMenuItem<int>(
                value: year,
                child: Text(
                  year.toString(),
                  style: GoogleFonts.nunito(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedYear = newValue;
                  _loadAnalyticsData(); // Reload and re-process data for the new year
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarGraphCard(double width) {
    // only months with data
    final monthsWithData =
        _monthlyAnalytics.entries.where((e) {
          final healthy = e.value['healthy'] ?? 0;
          final diseased = e.value['diseased'] ?? 0;
          return (healthy + diseased) > 0;
        }).toList()..sort(
          (a, b) => _months.indexOf(a.key).compareTo(_months.indexOf(b.key)),
        );

    if (monthsWithData.isEmpty) {
      return Container(
        width: width - 42,
        height: 190,
        margin: const EdgeInsets.symmetric(horizontal: 21),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAEAEA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No analytics data yet.',
            style: GoogleFonts.sourceSansPro(
              fontSize: 13,
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Build chart points
    final points = monthsWithData.map((e) {
      final mIndex = _months.indexOf(e.key); // 0..11
      final healthy = e.value['healthy'] ?? 0;
      final diseased = e.value['diseased'] ?? 0;
      final short = e.key.substring(0, 3); // Jan, Feb...
      return _MonthBars(
        monthIndex: mIndex,
        monthLabel: short,
        healthy: healthy,
        diseased: diseased,
      );
    }).toList();

    final maxValue = points
        .map((p) => (p.healthy > p.diseased ? p.healthy : p.diseased))
        .fold<int>(0, (prev, v) => v > prev ? v : prev);

    return Container(
      width: width - 42,
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 21),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                'Monthly Counts',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF253D24),
                ),
              ),
              const Spacer(),
              _miniLegendDot(color: const Color(0xFF66A060), label: 'Healthy'),
              const SizedBox(width: 10),
              _miniLegendDot(color: const Color(0xFFE84A4A), label: 'Diseased'),
            ],
          ),
          const SizedBox(height: 12),

          // Chart (animated)
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                return CustomPaint(
                  painter: _GroupedBarChartPainter(
                    points: points,
                    maxValue: maxValue <= 0 ? 1 : maxValue,
                    t: t,
                  ),
                  child: Container(),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // X labels row
          SizedBox(
            height: 18,
            child: Row(
              children: points.map((p) {
                return Expanded(
                  child: Center(
                    child: Text(
                      p.monthLabel,
                      style: GoogleFonts.sourceSansPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.55),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllMonthsSection(double width) {
    final cardWidth = width - 42;
    final sortedMonths = _monthlyAnalytics.keys.toList()
      ..sort((a, b) => _months.indexOf(b).compareTo(_months.indexOf(a)));

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Months',
            style: GoogleFonts.nunito(
              color: const Color(0xFF5B532C),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildLegendRow(),
          const SizedBox(height: 8),
          if (sortedMonths.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text('No scan data for the selected year.'),
              ),
            )
          else
            Column(
              children: sortedMonths.map<Widget>((monthName) {
                final data = _monthlyAnalytics[monthName]!;
                final total = data['healthy']! + data['diseased']!;
                final healthyPercent = total > 0
                    ? (data['healthy']! * 100 / total).round()
                    : 0;
                final diseasedPercent = total > 0
                    ? (data['diseased']! * 100 / total).round()
                    : 0;

                return Column(
                  children: [
                    _buildMonthCard(
                      monthName,
                      healthyPercent,
                      diseasedPercent,
                      cardWidth,
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLegendRow() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildLollipopLegendItem('Healthy', const Color(0xFF66A060)),
          const SizedBox(width: 14),
          _buildLollipopLegendItem('Diseased', const Color(0xFFE84A4A)),
        ],
      ),
    );
  }

  Widget _buildLollipopLegendItem(String text, Color color) {
    return Row(
      children: [
        // Lollipop visualization
        SizedBox(
          width: 20,
          height: 15,
          child: Stack(
            children: [
              // Horizontal line
              Positioned(
                left: 0,
                top: 6, // Center vertically
                child: Container(
                  width: 15,
                  height: 2,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // Text label - CHANGED font size from 8 to 14
        Text(
          text,
          style: GoogleFonts.nunito(
            color: color,
            fontSize: 12, // CHANGED: 8 to 14
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(
    String month,
    int healthy,
    int diseased,
    double width,
  ) {
    return Container(
      width: width,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0x3F000000),
            blurRadius: 10,
            offset: const Offset(4, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Month Name - CHANGED font size from 12 to 14
          Text(
            month,
            style: GoogleFonts.nunito(
              color: const Color(0xFF5B532C),
              fontSize: 14, // CHANGED: 12 to 14
              fontWeight: FontWeight.w700,
            ),
          ),

          // Percentages Row (centered on bars)
          // Percentages Row (centered on bars)
          SizedBox(
            height: 20,
            child: Stack(
              children: [
                // Healthy percentage
                Positioned(
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      // Healthy segment space
                      Expanded(
                        flex: healthy,
                        child: Center(
                          child: Text(
                            '$healthy%',
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF66A060),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2),
                      // Diseased segment space
                      Expanded(
                        flex: diseased,
                        child: Center(
                          child: Text(
                            '$diseased%',
                            style: GoogleFonts.nunito(
                              color: const Color(0xFFE84A4A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bars
          Row(
            children: [
              Expanded(
                flex: healthy,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66A060),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: diseased,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE84A4A),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(double width) {
    final navItems = [
      {'icon': Icons.home_outlined, 'label': 'Home', 'route': '/home'},
      {'icon': Icons.camera_alt_outlined, 'label': 'Scan', 'route': '/scan'},
      {
        'icon': Icons.cloud_upload_outlined,
        'label': 'Upload',
        'route': '/upload',
      },
      {'icon': Icons.history_outlined, 'label': 'History', 'route': '/history'},
      {'icon': Icons.menu_book_outlined, 'label': 'Manual', 'route': '/manual'},
    ];

    void _handleNavigation(String route) {
      Navigator.pushNamed(context, route);
    }

    return Container(
      width: width - 84,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.50, 0.00),
          end: Alignment(0.50, 1.00),
          colors: [Color(0xFFFFC50F), Color(0xFF997609)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: navItems.asMap().entries.map<Widget>((entry) {
          final item = entry.value;
          final isActive = item['label'] == 'Home';
          return GestureDetector(
            onTap: () {
              _handleNavigation(item['route'] as String);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 24,
                    color: isActive
                        ? const Color(0xFF2F2F2F)
                        : const Color(0xFF504926),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: GoogleFonts.nunito(
                      color: isActive
                          ? const Color(0xFF2F2F2F)
                          : const Color(0xFF504926),
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
