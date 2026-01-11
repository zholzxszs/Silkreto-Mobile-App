import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeSection extends StatefulWidget {
  const HomeSection({super.key});

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  final ScrollController _scrollController = ScrollController();
  bool _navVisible = true;
  double _previousOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.of(context).pushNamed('/scan');
    } else if (index == 2) {
      Navigator.of(context).pushNamed('/upload');
    } else if (index == 3) {
      Navigator.of(context).pushNamed('/history');
    } else if (index == 0) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 380;
    final contentWidth = isSmallScreen ? screenSize.width * 0.95 : 380.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Center(
          child: Container(
            width: contentWidth,
            constraints: BoxConstraints(minHeight: screenSize.height),
            padding: const EdgeInsets.symmetric(horizontal: 0),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Bar
                _buildHeader(contentWidth),
                const SizedBox(height: 28),

                // Weather Card
                _buildWeatherCard(contentWidth),
                const SizedBox(height: 30),

                // Explore Section
                _buildSectionTitle('Explore'),
                const SizedBox(height: 12),

                // Explore Cards Grid
                _buildExploreGrid(contentWidth),
                const SizedBox(height: 40),

                // Analytics Section
                _buildSectionTitle('Analytics'),
                const SizedBox(height: 12),

                // Year Dropdown
                _buildYearDropdown(contentWidth),
                const SizedBox(height: 12),

                // Line Graph Card
                _buildLineGraphCard(contentWidth),
                const SizedBox(height: 40),

                // All Months Section
                _buildSectionTitle('All Months'),
                const SizedBox(height: 12),

                // Month Cards
                _buildMonthCard('November', 60, 35, 5, contentWidth),
                const SizedBox(height: 12),
                _buildMonthCard('October', 60, 35, 5, contentWidth),
                const SizedBox(height: 12),
                _buildMonthCard('September', 60, 35, 5, contentWidth),
                const SizedBox(height: 12),
                _buildMonthCard('August', 60, 35, 5, contentWidth),
                const SizedBox(height: 60),

                // Bottom Navigation
                _buildBottomNavigation(contentWidth),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double width) {
    return Container(
      width: width,
      height: 55,
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
          // Profile Avatar
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/Silkreto-Logo.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          // SILKRETO Title
          Text(
            'SILKRETO',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.90,
            ),
          ),
          const Spacer(),
          // Notification Icon
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 16),
            child: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(double width) {
    return Container(
      width: width - 42,
      height: 125,
      margin: EdgeInsets.symmetric(horizontal: width * 0.055),
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
          // Weather Image
          Positioned(
            left: (width - 42) * 0.4,
            top: 14,
            child: SizedBox(
              width: 107,
              height: 90,
              child: Image.asset(
                'assets/Silkreto-Logo.png',
                fit: BoxFit.contain,
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
                          fontSize: 8,
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
                          fontSize: 8,
                          fontWeight: FontWeight.w300,
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
            top: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Sunny',
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF5B532C),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const TextSpan(text: '     '),
                      TextSpan(
                        text: 'Feels like 31°C',
                        style: GoogleFonts.sourceSansPro(
                          color: const Color(0xCC5B532C),
                          fontSize: 8,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),

          // Weather Warning
          Positioned(
            left: 14,
            bottom: 11,
            child: SizedBox(
              width: (width - 42) * 0.3,
              child: Text(
                'Sunny weather may compromise the Silkworm, Grasserie and Flacherie diseases may occur.',
                textAlign: TextAlign.justify,
                style: GoogleFonts.sourceSansPro(
                  color: const Color(0xFF5B532C),
                  fontSize: 6,
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
      {'icon': Icons.help_outline, 'label': 'Diseases'},
      {'icon': Icons.warning_amber, 'label': 'Symptoms'},
      {'icon': Icons.shield, 'label': 'Prevention'},
      {'icon': Icons.eco, 'label': 'Rearing'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: exploreItems.map((item) {
          return SizedBox(
            width: cardWidth,
            child: Column(
              children: [
                // Card
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
                  child: Icon(
                    item['icon'] as IconData,
                    size: cardWidth * 0.3,
                    color: const Color(0xFF5B532C),
                  ),
                ),
                const SizedBox(height: 8),
                // Label
                Text(
                  item['label'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sourceSansPro(
                    color: const Color(0xFF5B532C),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
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
          width: 60,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Text(
                '2025',
                style: GoogleFonts.nunito(
                  color: const Color(0xFF5B532C),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: Color(0xFF5B532C),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineGraphCard(double width) {
    return Container(
      width: width - 42,
      height: 163,
      margin: EdgeInsets.symmetric(horizontal: width * 0.055),
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

  Widget _buildMonthCard(
    String month,
    int healthy,
    int npv,
    int flacherie,
    double width,
  ) {
    final cardWidth = width - 42;
    return Container(
      width: cardWidth,
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: width * 0.055),
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
      child: Stack(
        children: [
          // Month Name
          Positioned(
            left: 12,
            top: 10,
            child: Text(
              month,
              style: GoogleFonts.nunito(
                color: const Color(0xFF5B532C),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Bars
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Row(
              children: [
                // Healthy Bar
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
                // NPV Bar
                Expanded(
                  flex: npv,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE84A4A),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // Flacherie Bar
                Expanded(
                  flex: flacherie,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB05CC5),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Percentage Labels
          Positioned(
            left: 12,
            bottom: 20,
            child: _buildPercentageLabel('$healthy%', const Color(0xFF66A060)),
          ),
          Positioned(
            left: 12 + (cardWidth - 24) * (healthy / 100),
            bottom: 20,
            child: _buildPercentageLabel('$npv%', const Color(0xFFE84A4A)),
          ),
          Positioned(
            right: 12,
            bottom: 20,
            child: _buildPercentageLabel(
              '$flacherie%',
              const Color(0xFFB05CC5),
            ),
          ),

          // Legend
          Positioned(
            right: 12,
            top: 10,
            child: Row(
              children: [
                _buildLegendItem('Healthy', const Color(0xFF66A060)),
                const SizedBox(width: 8),
                _buildLegendItem('NPV', const Color(0xFFE84A4A)),
                const SizedBox(width: 8),
                _buildLegendItem('Flacherie', const Color(0xFFB05CC5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        color: color,
        fontSize: 6,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.nunito(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(double width) {
    final navItems = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.camera_alt, 'label': 'Scan'},
      {'icon': Icons.cloud_upload, 'label': 'Upload'},
      {'icon': Icons.history, 'label': 'History'},
      {'icon': Icons.menu_book, 'label': 'Manual'},
    ];

    return Container(
      width: width * 0.67,
      height: 34,
      margin: EdgeInsets.symmetric(horizontal: width * 0.165),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.50, 0.00),
          end: Alignment(0.50, 1.00),
          colors: [Color(0xFFFFC50F), Color(0xFF997609)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return GestureDetector(
            onTap: () => _onItemTapped(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 18,
                  color: const Color(0xFF504926),
                ),
                const SizedBox(height: 2),
                Text(
                  item['label'] as String,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF504926),
                    fontSize: 6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
