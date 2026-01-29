import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/scan_result_model.dart';
import '../services/tflite_model_service.dart';

class UploadSection extends StatefulWidget {
  const UploadSection({super.key});

  @override
  State<UploadSection> createState() => _UploadSectionState();
}

class _UploadSectionState extends State<UploadSection> {
  final ImagePicker _picker = ImagePicker();

  XFile? _image;

  bool _isProcessing = false; // analyzing
  bool _isSaving = false;

  int? healthyCount;
  int? diseasedCount;

  // YOLO detections for bounding boxes
  List<Detection> _detections = const [];
  ModelPrediction? _lastPrediction;

  // Floating nav behavior
  final ScrollController _scrollController = ScrollController();
  bool _navVisible = true;
  double _previousOffset = 0.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scrollController.addListener(_onScroll);

    // Auto open gallery when screen loads (init model first to reduce delay)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await TFLiteModelService().ensureInitialized();
      } catch (_) {}
      await _pickFromGallery();
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

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery, // ✅ gallery
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        setState(() {
          _isProcessing = true;
          _image = picked;
          healthyCount = null;
          diseasedCount = null;
          _detections = const [];
          _lastPrediction = null;
        });

        // ✅ let UI paint overlay first
        await Future.delayed(const Duration(milliseconds: 16));

        await _analyzeCurrentImage();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gallery error: $e')));
    }
  }

  /// ✅ This is the key fix: show "Analyzing..." FIRST, then yield 1 frame.
  Future<void> _analyzeCurrentImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
      healthyCount = null;
      diseasedCount = null;
      _detections = const [];
      _lastPrediction = null;
    });

    // ✅ allow Flutter to render overlay before heavy decode/inference
    await Future.delayed(const Duration(milliseconds: 16));

    try {
      final modelService = TFLiteModelService();
      await modelService.ensureInitialized();

      final prediction = await modelService.predictFromImage(_image!.path);

      if (!mounted) return;
      setState(() {
        healthyCount = prediction.healthyCount;
        diseasedCount = prediction.diseasedCount;
        _detections = prediction.detections;
        _lastPrediction = prediction;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Analyze error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildPreviewWithBoxes() {
    if (_image == null) return const SizedBox.shrink();

    // Draw on fixed 640x640 then scale/crop together with the image
    return Stack(
      children: [
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: 640,
              height: 640,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(File(_image!.path), fit: BoxFit.fill),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: YoloBoxPainter(
                          detections: _detections,
                          labels: const ['Healthy', 'Diseased'],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ✅ Overlay badge
        if (_isProcessing || _isSaving)
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isProcessing ? 'Analyzing...' : 'Saving...',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _reupload() async {
    setState(() => _image = null);
    await _pickFromGallery();
  }

  Future<void> _confirmAndSave() async {
    if (_image == null) return;

    setState(() => _isSaving = true);

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newImage = File('${appDir.path}/$fileName');
      await File(_image!.path).copy(newImage.path);

      final now = DateTime.now();
      final dateFormat = DateFormat('MMM dd, yyyy');
      final timeFormat = DateFormat('h:mm a');

      // Use last prediction (avoid re-inference)
      ModelPrediction prediction = _lastPrediction ?? ModelPrediction.empty();
      if (prediction.status == 'Unknown') {
        final modelService = TFLiteModelService();
        await modelService.ensureInitialized();
        prediction = await modelService.predictFromImage(newImage.path);
      }

      if (mounted) {
        setState(() {
          healthyCount = prediction.healthyCount;
          diseasedCount = prediction.diseasedCount;
          _detections = prediction.detections;
          _lastPrediction = prediction;
        });
      }

      // Create annotated image with boxes
      String? annotatedImagePath;
      if (prediction.detections.isNotEmpty) {
        final bytes = File(newImage.path).readAsBytesSync();
        final image = img.decodeImage(bytes);
        if (image != null) {
          final canvas = img.Image.from(image);

          for (final d in prediction.detections) {
            final color = d.classId == 0
                ? img.ColorRgb8(102, 166, 96)
                : img.ColorRgb8(228, 74, 74);

            // auto detect normalized coords
            final isNorm =
                d.x1.abs() <= 1.5 &&
                d.y1.abs() <= 1.5 &&
                d.x2.abs() <= 1.5 &&
                d.y2.abs() <= 1.5;

            final x1 =
                (isNorm ? d.x1 * image.width : d.x1 / 640.0 * image.width)
                    .toInt()
                    .clamp(0, image.width - 1);
            final y1 =
                (isNorm ? d.y1 * image.height : d.y1 / 640.0 * image.height)
                    .toInt()
                    .clamp(0, image.height - 1);
            final x2 =
                (isNorm ? d.x2 * image.width : d.x2 / 640.0 * image.width)
                    .toInt()
                    .clamp(0, image.width - 1);
            final y2 =
                (isNorm ? d.y2 * image.height : d.y2 / 640.0 * image.height)
                    .toInt()
                    .clamp(0, image.height - 1);

            img.drawRect(
              canvas,
              x1: x1,
              y1: y1,
              x2: x2,
              y2: y2,
              color: color,
              thickness: 3,
            );
          }

          final annotatedFileName =
              'annotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final annotatedPath = '${appDir.path}/$annotatedFileName';
          File(annotatedPath).writeAsBytesSync(img.encodeJpg(canvas));
          annotatedImagePath = annotatedPath;
        }
      }

      final scanResult = ScanResult(
        rawImagePath: newImage.path,
        annotatedImagePath: annotatedImagePath,
        status: prediction.status,
        scanDate: dateFormat.format(now),
        scanTime: timeFormat.format(now),
        healthyCount: prediction.healthyCount,
        diseasedCount: prediction.diseasedCount,
      );

      await DatabaseHelper().insertScanResult(scanResult);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload saved successfully')),
        );
      }

      // Reset
      if (mounted) {
        setState(() {
          _image = null;
          healthyCount = null;
          diseasedCount = null;
          _detections = const [];
          _lastPrediction = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(
                        minHeight: 280,
                        maxHeight: 280,
                      ),
                      height: 280,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _image == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No image selected',
                                    style: GoogleFonts.nunito(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _pickFromGallery,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF63A361),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Select Image'),
                                  ),
                                ],
                              ),
                            )
                          : _buildPreviewWithBoxes(),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'Healthy: ${healthyCount ?? 0}',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF66A060),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Diseased: ${diseasedCount ?? 0}',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFE84A4A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (_image != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _isProcessing ? null : _reupload,
                            child: Container(
                              width: 130,
                              height: 44,
                              decoration: ShapeDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment(0.50, 0.00),
                                  end: Alignment(0.50, 1.00),
                                  colors: [
                                    Color(0xFFE84A4A),
                                    Color(0xFF822929),
                                  ],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x3F000000),
                                    blurRadius: 10,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Reupload',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: _isSaving ? null : _confirmAndSave,
                            child: Container(
                              width: 130,
                              height: 44,
                              decoration: ShapeDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment(0.50, 1.00),
                                  end: Alignment(0.50, 0.00),
                                  colors: [
                                    Color(0xFF253D24),
                                    Color(0xFF488646),
                                  ],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x3F000000),
                                    blurRadius: 10,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'Save',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 14),

                    _buildDecisionSupportCard(),

                    const SizedBox(height: 160),
                  ],
                ),
              ),
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

  Widget _buildDecisionSupportCard() {
    final int? hRaw = healthyCount;
    final int? dRaw = diseasedCount;

    // Show only AFTER analysis produces counts.
    if (hRaw == null && dRaw == null) {
      return const SizedBox.shrink();
    }

    final int h = hRaw ?? 0;
    final int d = dRaw ?? 0;
    final int total = h + d;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final double ratio = d / total;

    String riskLabel;
    String headline;
    List<String> tips;

    // Dynamic pill background color (soft + modern).
    Color pillBg;
    Color pillFg;

    if (d == 0) {
      riskLabel = 'LOW RISK';
      pillBg = const Color(0xFF2E7D32); // strong green
      pillFg = Colors.white;
      headline =
          'Many signs look healthy so far. Keep conditions steady and consistent.';
      tips = const [
        'Clean trays/tools daily and remove leftover leaves and waste.',
        'Feed fresh, dry leaves; avoid wet or wilted leaves.',
        'Keep airflow gentle and stable; avoid sudden changes.',
        'Avoid overcrowding as larvae grow—give them space.',
        'Check daily and note anything unusual early.',
      ];
    } else if (ratio < 0.10) {
      riskLabel = 'MILD RISK';
      pillBg = const Color(0xFF00796B); // strong teal
      pillFg = Colors.white;
      headline =
          'Many are healthy, but a few look diseased. Small changes now can help prevent spread.';
      tips = const [
        'Separate weak/diseased-looking worms if possible.',
        'Wipe/clean rearing area and tools before each feeding.',
        'Keep leaves clean and dry; avoid overfeeding.',
        'Reduce crowding and improve gentle ventilation.',
        'Monitor twice daily for any rapid changes.',
      ];
    } else if (ratio < 0.25) {
      riskLabel = 'MODERATE RISK';
      pillBg = const Color(0xFFF57C00); // strong orange
      pillFg = Colors.white;
      headline =
          'Many show possible disease signs. Focus on cleanliness, spacing, and stable conditions.';
      tips = const [
        'Isolate suspected diseased worms and dispose waste carefully.',
        'Clean trays more often and keep bedding dry.',
        'Feed smaller portions more frequently to avoid spoilage.',
        'Improve airflow (no strong drafts) and avoid sudden temperature swings.',
        'Record what you changed so you can see what helps.',
      ];
    } else {
      riskLabel = 'HIGH RISK';
      pillBg = const Color(0xFFC62828); // strong red (similar to Reupload)
      pillFg = Colors.white;
      headline =
          'Many appear diseased. Prioritize isolation, sanitation, and a stable environment to reduce losses.';
      tips = const [
        'Separate diseased worms immediately and clean the area thoroughly.',
        'Remove spoiled leaves/waste promptly; keep trays dry.',
        'Avoid crowding—spread worms into more trays if possible.',
        'Keep temperature/humidity steady and ensure gentle airflow.',
        'Consider restarting with healthier stock if the batch continues to worsen.',
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Silkworm / Nature icon (low saturation)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF447042),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.grass_rounded, // closest clean silkworm/nature vibe
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Text(
                  'TIPS & RECOMMENDATIONS',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              // Risk pill (NO ICON)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: pillBg, // green-tuned outside
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  riskLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: pillFg,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// HEADLINE (NO ICON)
          Text(
            headline,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 14),

          /// TIPS LIST
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Soft green check
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF63A361),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> _InfoCard({
    required String title,
    required String subtitle,
    required String severityLabel,
    List<String> bullets = const [],
    required dynamic scheme,
  }) async {
    // Dynamic background color based on severity
    Color bgColor;
    Color textColor;
    if (severityLabel == 'Low risk') {
      bgColor = const Color(0xFFC8E6C9); // Light green
      textColor = const Color(0xFF1B5E20);
    } else if (severityLabel == 'Mild risk') {
      bgColor = const Color(0xFFFFF9C4); // Light yellow
      textColor = const Color(0xFF664D03);
    } else if (severityLabel == 'Moderate risk') {
      bgColor = const Color(0xFFFFE0B2); // Light orange
      textColor = const Color(0xFF663C00);
    } else {
      bgColor = const Color(0xFFFFCDD2); // Light red
      textColor = const Color(0xFFC62828);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bgColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  severityLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              height: 1.35,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final b in bullets) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        height: 1.35,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
          if (bullets.isNotEmpty)
            Text(
              'Note: These are general, non-expert tips—not a medical diagnosis.',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(double width) {
    return Container(
      width: width,
      height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.50, 0.00),
          end: Alignment(0.50, 1.00),
          colors: [Color(0xFF63A361), Color(0xFF253D24)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
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
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 26,
            ),
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
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: navItems.map((item) {
          final isActive = item['label'] == 'Upload';
          return GestureDetector(
            onTap: () {
              final route = item['route'] as String?;
              if (route == null || route == '/upload') return;
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

class YoloBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final List<String> labels;

  YoloBoxPainter({required this.detections, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // auto-detect normalized boxes (0..1) vs pixel boxes (0..640)
    final bool isNormalized = detections.every(
      (d) =>
          d.x1.abs() <= 1.5 &&
          d.y1.abs() <= 1.5 &&
          d.x2.abs() <= 1.5 &&
          d.y2.abs() <= 1.5,
    );

    for (final d in detections) {
      paint.color = (d.classId == 0)
          ? const Color(0xFF66A060)
          : const Color(0xFFE84A4A);

      double x1 = d.x1, y1 = d.y1, x2 = d.x2, y2 = d.y2;

      if (isNormalized) {
        x1 *= size.width;
        x2 *= size.width;
        y1 *= size.height;
        y2 *= size.height;
      } else {
        x1 = x1 / 640.0 * size.width;
        x2 = x2 / 640.0 * size.width;
        y1 = y1 / 640.0 * size.height;
        y2 = y2 / 640.0 * size.height;
      }

      final rect = Rect.fromLTRB(
        x1.clamp(0.0, size.width),
        y1.clamp(0.0, size.height),
        x2.clamp(0.0, size.width),
        y2.clamp(0.0, size.height),
      );

      canvas.drawRect(rect, paint);

      final label = (d.classId >= 0 && d.classId < labels.length)
          ? labels[d.classId]
          : 'Class ${d.classId}';
      final text = '$label ${(d.score * 100).toStringAsFixed(1)}%';

      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: paint.color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          backgroundColor: const Color(0xAAFFFFFF),
        ),
      );
      textPainter.layout();

      final textOffset = Offset(
        rect.left,
        max(0, rect.top - textPainter.height),
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant YoloBoxPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
