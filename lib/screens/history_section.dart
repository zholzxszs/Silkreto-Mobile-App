import 'dart:io';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/scan_result_model.dart';

class HistorySection extends StatefulWidget {
  const HistorySection({super.key});

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  final ScrollController _scrollController = ScrollController();
  bool _navVisible = true;
  int _selectedIndex = 3;
  double _previousOffset = 0.0;
  late Future<List<ScanResult>> _scanResults;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadScanResults();
  }

  void _loadScanResults() {
    _scanResults = DatabaseHelper().getAllScanResults();
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (index == 1) {
      Navigator.of(context).pushNamed('/scan');
    } else if (index == 2) {
      Navigator.of(context).pushNamed('/upload');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFF6B5B95),
                expandedHeight: size.height * 0.12,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('History'),
                  centerTitle: true,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                sliver: FutureBuilder<List<ScanResult>>(
                  future: _scanResults,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(child: Text('Error: ${snapshot.error}')),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(child: Text('No scans yet')),
                      );
                    }
                    final results = snapshot.data!;
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildHistoryCard(context, results[index]),
                        childCount: results.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating bottom navigation rectangle
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _navVisible ? Offset.zero : const Offset(0, 1.2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _navVisible ? 1 : 0,
                child: Center(
                  child: Container(
                    width: size.width * (size.width > 600 ? 0.6 : 0.95),
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _navItem(Icons.home_outlined, 'Home', 0),
                        _navItem(Icons.qr_code_scanner, 'Scan', 1),
                        _navItem(Icons.cloud_upload_outlined, 'Upload', 2),
                        _navItem(Icons.history, 'History', 3),
                        _navItem(Icons.menu_book, 'Manual', 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;
    final color = selected ? const Color(0xFF6B5B95) : Colors.grey[600];
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onItemTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ScanResult scanResult) {
    final size = MediaQuery.of(context).size;
    final status = scanResult.status;
    final statusColor = _getStatusColor(status);
    final statusBg = _getStatusBgColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Image thumbnail - tappable to show preview
            GestureDetector(
              onTap: () => _showImagePreview(context, scanResult),
              child: Container(
                width: size.width * 0.22,
                height: size.width * 0.22,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Stack(
                  children: [
                    File(scanResult.rawImagePath).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.file(
                              File(scanResult.rawImagePath),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B5B95),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.zoom_in,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Date
                  Text(
                    scanResult.scanDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Time
                  Text(
                    scanResult.scanTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, ScanResult scanResult) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          children: [
            // Full-screen preview
            Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B5B95),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Annotated Image - ${scanResult.status}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Image preview
                  Container(
                    color: Colors.grey[900],
                    padding: const EdgeInsets.all(12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        child: Stack(
                          children: [
                            File(scanResult.rawImagePath).existsSync()
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(scanResult.rawImagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 80,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer with info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${scanResult.status}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${scanResult.scanDate} • ${scanResult.scanTime}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text(
                            'Got it',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B5B95),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Grasserie':
        return const Color(0xFF2E7D32); // Modern deep green
      case 'Flacherie':
        return const Color(0xFFE65100); // Modern deep orange
      case 'Healthy':
        return const Color(0xFF1565C0); // Modern deep blue
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Grasserie':
        return const Color(0xFF2E7D32).withOpacity(0.12); // Light green bg
      case 'Flacherie':
        return const Color(0xFFE65100).withOpacity(0.12); // Light orange bg
      case 'Healthy':
        return const Color(0xFF1565C0).withOpacity(0.12); // Light blue bg
      default:
        return Colors.grey.withOpacity(0.12);
    }
  }
}

// Custom painter for annotation visualization
class AnnotationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw some example annotation boxes to simulate annotated image
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.2,
        size.width * 0.3,
        size.height * 0.25,
      ),
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.4),
      size.width * 0.12,
      paint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.6,
        size.width * 0.35,
        size.height * 0.3,
      ),
      paint,
    );

    // Draw center crosshair
    final crossPaint = Paint()
      ..color = Colors.amber.withOpacity(0.7)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2 - 15, size.height / 2),
      Offset(size.width / 2 + 15, size.height / 2),
      crossPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 - 15),
      Offset(size.width / 2, size.height / 2 + 15),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
