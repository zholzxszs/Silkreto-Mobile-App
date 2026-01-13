import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  double _previousOffset = 0.0;
  List<ScanResult> _allScanResults = [];
  List<ScanResult> _filteredScanResults = [];
  List<int> _availableYears = [];
  int? _selectedYear;
  String? _selectedMonth;

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
    _scrollController.addListener(_onScroll);
    _loadScanResults();
  }

  void _loadScanResults() async {
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

    years.sort((a, b) => b.compareTo(a)); // Sort descending

    final now = DateTime.now();

    setState(() {
      _allScanResults = results;
      _availableYears = years;

      // Set initial selected year to current year if available, otherwise latest
      if (years.contains(now.year)) {
        _selectedYear = now.year;
      } else if (years.isNotEmpty) {
        _selectedYear = years.first;
      }

      // Set initial selected month to current month
      _selectedMonth = _months[now.month - 1];

      _filterResults();
    });
  }

  void _filterResults() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    if (_selectedYear == null) {
      _filteredScanResults = _allScanResults;
    } else {
      _filteredScanResults = _allScanResults.where((r) {
        try {
          final date = dateFormat.parse(r.scanDate);
          final yearMatches = date.year == _selectedYear;
          final monthMatches =
              _selectedMonth == null ||
              (date.month) == (_months.indexOf(_selectedMonth!) + 1);
          return yearMatches && monthMatches;
        } catch (e) {
          return false;
        }
      }).toList();
    }
    setState(() {});
  }

  // ────────────────────────────────────────────────
  //  Modified: Added confirmation dialog before delete
  // ────────────────────────────────────────────────
  Future<void> _deleteScanResult(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text(
          'Are you sure you want to delete this record?\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper().deleteScanResult(id);
      _loadScanResults(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Scan record deleted')));
      }
    }
  }

  void _showImagePreview(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(imagePath)),
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(screenWidth),
              _buildFilters(),
              _buildHistoryList(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 35 + 60),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _navVisible
                ? MediaQuery.of(context).padding.bottom + 35
                : -100,
            left: 42,
            right: 42,
            child: _buildBottomNavigation(screenWidth),
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

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, right: 20, left: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildMonthDropdown(),
          const SizedBox(width: 8),
          _buildYearDropdown(),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: _selectedMonth,
        hint: Text('Month', style: GoogleFonts.nunito(fontSize: 12)),
        underline: const SizedBox(),
        isDense: true,
        items: _months.map((String month) {
          return DropdownMenuItem<String>(
            value: month,
            child: Text(month, style: GoogleFonts.nunito(fontSize: 12)),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedMonth = newValue;
            _filterResults();
          });
        },
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          setState(() {
            _selectedYear = newValue;
            _filterResults();
          });
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_filteredScanResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No scans found for the selected period.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _filteredScanResults.length,
      itemBuilder: (context, index) =>
          _buildHistoryCard(context, _filteredScanResults[index]),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ScanResult scanResult) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.50, 1.00),
          end: Alignment(0.50, -0.00),
          colors: [const Color(0xFF253D24), const Color(0xFF63A361)],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () => _showImagePreview(context, scanResult.rawImagePath),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFD9D9D9),
                image: File(scanResult.rawImagePath).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(scanResult.rawImagePath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !File(scanResult.rawImagePath).existsSync()
                  ? const Icon(Icons.image_not_supported, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${scanResult.scanDate} at ${scanResult.scanTime}',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: 24, // Constrain height
                      width: 24, // Constrain width
                      child: IconButton(
                        padding: EdgeInsets.zero, // Remove default padding
                        iconSize: 20, // Adjust icon size
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteScanResult(scanResult.id!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCountChip(
                      'Healthy: ${scanResult.healthyCount}',
                      const Color(0xFF4CAF50),
                      Colors.white,
                    ),
                    const SizedBox(width: 8),
                    _buildCountChip(
                      'Grasserie: ${scanResult.grasserieCount}',
                      const Color(0xFFF44336),
                      Colors.white,
                    ),
                    const SizedBox(width: 8),
                    _buildCountChip(
                      'Flacherie: ${scanResult.flacherieCount}',
                      const Color(0xFF9C27B0),
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildCountChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
          final isActive = item['label'] == 'History';
          return GestureDetector(
            onTap: () {
              final route = item['route'] as String?;
              if (route == null || route == '/history') return;

              // Basic navigation
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
