import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/scan_result_model.dart';

class HomeSection extends StatefulWidget {
  const HomeSection({super.key});

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  final ScrollController _scrollController = ScrollController();
  bool _navVisible = true;
  double _previousOffset = 0.0;

  List<int> _availableYears = [];
  int? _selectedYear;
  Map<String, Map<String, int>> _monthlyAnalytics = {};

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scrollController.addListener(_onScroll);
    _loadAnalyticsData();
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
                  _buildLineGraphCard(screenSize.width),
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
    return Container(
      width: width - 42,
      height: 130,
      margin: const EdgeInsets.symmetric(horizontal: 21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.50, -0.00),
          end: Alignment(0.50, 1.00),
          colors: [Color(0xFFFFD20F), Color(0xFFFDE7B3)],
        ),
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
      child: Stack(
        children: [
          // Weather Image (centered)
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0.35, 0),
              child: SizedBox(
                width: 167,
                height: 150,
                child: Image.asset(
                  'assets/weather-clouds/sunny-cloudy.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.cloud,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Location and Date
          Positioned(
            left: 14,
            top: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCCFDE7B3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Color(0xFF2F2F2F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sapilang, Bacnotan, La Union',
                        style: GoogleFonts.sourceSansPro(
                          color: const Color(0xFF2F2F2F),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Date
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'SUNDAY\n',
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF5B532C),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '11 Nov, 2025',
                        style: GoogleFonts.sourceSansPro(
                          color: const Color(0xCC5B532C),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Temperature
          Positioned(
            right: 14,
            top: 11, // top for 29°C
            bottom: 14, // bottom for Sunny + Feels like
            child: SizedBox(
              height:
                  130 - 25, // container height minus padding, adjust if needed
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top: Temperature
                  Text(
                    '29°C',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.nunito(
                      color: const Color(0xFF5B532C),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.37,
                    ),
                  ),

                  // Bottom: Sunny + Feels like
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sunny',
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF5B532C),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 1), // reduced spacing
                      Text(
                        'Feels like 31°C',
                        style: GoogleFonts.sourceSansPro(
                          color: const Color(0xCC5B532C),
                          fontSize: 8,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Weather Warning
          Positioned(
            left: 14,
            bottom: 11,
            child: SizedBox(
              width: (width - 42) * 0.4,
              child: Text(
                'Sunny weather may compromise the Silkworm, Diseased may occur.',
                textAlign: TextAlign.justify,
                style: GoogleFonts.sourceSansPro(
                  color: const Color(0xFF5B532C),
                  fontSize: 7,
                  fontWeight: FontWeight.w400,
                ),
              ),
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

  Widget _buildLineGraphCard(double width) {
    return Container(
      width: width - 42,
      height: 163,
      margin: const EdgeInsets.symmetric(horizontal: 21),
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
      child: Center(
        child: Text(
          'Line Graph',
          textAlign: TextAlign.center,
          style: GoogleFonts.sourceSansPro(
            color: Colors.black,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
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
