import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/scan_result_model.dart';
import '../services/tflite_model_service.dart';

class ScanSection extends StatefulWidget {
  const ScanSection({super.key});

  @override
  State<ScanSection> createState() => _ScanSectionState();
}

class _ScanSectionState extends State<ScanSection> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Open camera automatically when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickFromCamera());
  }

  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _image = picked);
    } else {
      // If user canceled, go back
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _retake() async {
    setState(() => _image = null);
    await _pickFromCamera();
  }

  Future<void> _confirm() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (_image != null) {
      try {
        // Copy image to app documents directory
        final Directory appDir = Directory(
          '/data/user/0/com.example.silkreto/files',
        );
        if (!appDir.existsSync()) {
          appDir.createSync(recursive: true);
        }

        final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File newImage = File('${appDir.path}/$fileName');
        await File(_image!.path).copy(newImage.path);

        // Get current date and time
        final now = DateTime.now();
        final dateFormat = DateFormat('MMM dd, yyyy');
        final timeFormat = DateFormat('h:mm a');
        final scanDate = dateFormat.format(now);
        final scanTime = timeFormat.format(now);

        // Run TFLite model inference to get prediction
        final modelService = TFLiteModelService();
        final prediction = await modelService.predictFromImage(newImage.path);

        // Create scan result and save to database
        final scanResult = ScanResult(
          rawImagePath: newImage.path,
          annotatedImagePath: null,
          status: prediction.status,
          scanDate: scanDate,
          scanTime: scanTime,
          healthyCount: prediction.healthyCount,
          grasserieCount: prediction.grasserieCount,
          flacherieCount: prediction.flacherieCount,
        );

        final db = DatabaseHelper();
        await db.insertScanResult(scanResult);

        setState(() => _isProcessing = false);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScanResultScreen(imagePath: newImage.path),
            ),
          );
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving scan: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B5B95),
        title: const Text('Scan'),
      ),
      body: Center(
        child: _image == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.file(File(_image!.path), fit: BoxFit.contain),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _retake,
                            child: const Text('Retake'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _confirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B5B95),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('OK'),
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
}

class ScanResultScreen extends StatelessWidget {
  final String? imagePath;
  const ScanResultScreen({super.key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      body: Center(
        child: imagePath == null
            ? const Text('No image')
            : Column(
                children: [
                  Expanded(
                    child: Image.file(File(imagePath!), fit: BoxFit.contain),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Scan saved',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
