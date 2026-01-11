import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  XFile? _file;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickFromGallery());
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _file = picked);
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _retake() async {
    setState(() => _file = null);
    await _pickFromGallery();
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (_file != null) {
      try {
        // Copy image to app documents directory
        final Directory appDir = Directory(
          '/data/user/0/com.example.silkreto/files',
        );
        if (!appDir.existsSync()) {
          appDir.createSync(recursive: true);
        }

        final fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File newImage = File('${appDir.path}/$fileName');
        await File(_file!.path).copy(newImage.path);

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

        setState(() => _uploading = false);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UploadResultScreen(filePath: newImage.path),
            ),
          );
        }
      } catch (e) {
        setState(() => _uploading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B5B95),
        title: const Text('Upload'),
      ),
      body: Center(
        child: _file == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.file(File(_file!.path), fit: BoxFit.contain),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _retake,
                            child: const Text('Choose Again'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _uploading ? null : _upload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B5B95),
                            ),
                            child: _uploading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Upload'),
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

class UploadResultScreen extends StatelessWidget {
  final String? filePath;
  const UploadResultScreen({super.key, this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Result'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      body: Center(
        child: filePath == null
            ? const Text('No file')
            : Column(
                children: [
                  Expanded(
                    child: Image.file(File(filePath!), fit: BoxFit.contain),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Upload complete',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
