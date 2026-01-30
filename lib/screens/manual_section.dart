import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ManualSection extends StatefulWidget {
  const ManualSection({super.key});

  @override
  State<ManualSection> createState() => _ManualSectionState();
}

class _ManualSectionState extends State<ManualSection> {
  final ScrollController _scrollController = ScrollController();
  bool _navVisible = true;
  double _previousOffset = 0.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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

  // ----------------------------
  // Screenshot preview (tap to zoom)
  // ----------------------------
  void _openScreenshotPreview({
    required String title,
    required String assetPath,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 22,
          ),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _missingScreenshot(title),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    top: 10,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _missingScreenshot(String title) {
    return Container(
      color: const Color(0xFF111111),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_not_supported,
            color: Colors.white70,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            'Screenshot placeholder for:\n$title',
            textAlign: TextAlign.center,
            style: GoogleFonts.sourceSansPro(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your screenshot asset later.',
            textAlign: TextAlign.center,
            style: GoogleFonts.sourceSansPro(
              color: Colors.white54,
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // UI bits
  // ----------------------------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          color: const Color(0xFF5B532C),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _manualCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> bullets,
    List<String> tips = const [],
    required String screenshotAsset,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 21),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
          // top row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0x1463A361),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x1F63A361)),
                ),
                child: Icon(icon, color: const Color(0xFF253D24), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF253D24),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            description,
            style: GoogleFonts.sourceSansPro(
              color: Colors.black.withOpacity(0.68),
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),
          _smallLabel('What you’ll see'),
          const SizedBox(height: 6),
          ...bullets.map(_bullet),

          if (tips.isNotEmpty) ...[
            const SizedBox(height: 10),
            _smallLabel('Quick tips'),
            const SizedBox(height: 6),
            ...tips.map(_bullet),
          ],

          const SizedBox(height: 12),

          // screenshot card
          GestureDetector(
            onTap: () => _openScreenshotPreview(
              title: title,
              assetPath: screenshotAsset,
            ),
            child: Container(
              width: double.infinity,
              height: 165,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7E7E7)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        screenshotAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: const Color(0xFFF3F3F3),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.image,
                                  size: 28,
                                  color: Color(0xFF8A8A8A),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to preview\n(placeholder)',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.sourceSansPro(
                                    color: const Color(0xFF777777),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Preview',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 2),
          Text(
            'Tap the screenshot to view larger.',
            style: GoogleFonts.sourceSansPro(
              color: Colors.black.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        color: const Color(0xFF5B532C),
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF63A361)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.sourceSansPro(
                color: Colors.black.withOpacity(0.64),
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // Build
  // ----------------------------
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
                  // ✅ anchored header (same as your file)
                  _buildHeader(screenSize.width),
                  const SizedBox(height: 18),

                  _sectionTitle('Manual'),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    child: Text(
                      'Quick guide for silkworm farmers. Read short descriptions per section.',
                      style: GoogleFonts.sourceSansPro(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // HOME
                  _manualCard(
                    icon: Icons.home_outlined,
                    title: 'HOME',
                    description:
                        'Summary view for weather, guidance, and monthly analytics.',
                    bullets: const [
                      'Weather forecast based on your location.',
                      'Decision support: what to improve today.',
                      'Monthly graph: Healthy vs Diseased counts.',
                      'All Months: percentage of Healthy and Diseased results.',
                    ],
                    screenshotAsset: 'assets/manual/home.png',
                  ),
                  const SizedBox(height: 14),

                  // SCAN
                  _manualCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'SCAN',
                    description:
                        'Take a square photo to detect Healthy vs Diseased silkworms.',
                    bullets: const [
                      'Camera is fixed to a square frame for consistent results.',
                      'After scanning, the app gives rearing tips based on counts.',
                      'You can save the result or retake the photo.',
                    ],
                    tips: const [
                      'Use bright lighting (avoid dark photos).',
                      'Keep the camera steady (avoid blur).',
                      'Center the silkworms inside the square frame.',
                      'Avoid strong shadows and glare.',
                    ],
                    screenshotAsset: 'assets/manual/scan.png',
                  ),
                  const SizedBox(height: 14),

                  // UPLOAD
                  _manualCard(
                    icon: Icons.cloud_upload_outlined,
                    title: 'UPLOAD',
                    description:
                        'Upload an image from your gallery for the same analysis as Scan.',
                    bullets: const [
                      'Works like Scan but uses an existing photo.',
                      'Square image is recommended for better framing.',
                      'The app still gives tips based on Healthy and Diseased counts.',
                    ],
                    tips: const [
                      'Choose a clear, well-lit photo.',
                      'Avoid images that are too far or too close.',
                      'Prefer square (1:1) image size for best results.',
                    ],
                    screenshotAsset: 'assets/manual/upload.png',
                  ),
                  const SizedBox(height: 14),

                  // HISTORY
                  _manualCard(
                    icon: Icons.history_outlined,
                    title: 'HISTORY',
                    description:
                        'Stores saved scans and uploads so you can review past results.',
                    bullets: const [
                      'View saved images with their dates and results.',
                      'Track changes across months and seasons.',
                      'Use it to compare results before/after improvements.',
                    ],
                    screenshotAsset: 'assets/manual/history.png',
                  ),

                  // placeholder for floating nav space
                  const SizedBox(height: 95),
                ],
              ),
            ),
          ),

          // ✅ floating nav (same behavior)
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

  // ---------------------------------------------------------------------------
  // ✅ EXACT HEADER FROM YOUR FILE (History)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // ✅ EXACT BOTTOM NAV FROM YOUR FILE (History) but active = 'Manual'
  // ---------------------------------------------------------------------------
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
          final isActive = item['label'] == 'Manual';

          return GestureDetector(
            onTap: () {
              final route = item['route'] as String?;
              if (route == null || route == '/manual') return;
              Navigator.pushNamed(context, route);
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
