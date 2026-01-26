// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteModelService {
  static final TFLiteModelService _instance = TFLiteModelService._internal();
  factory TFLiteModelService() => _instance;
  TFLiteModelService._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Model signature:
  // Input:  (1, 640, 640, 3) float32
  // Output: (1, 6, 8400) float32
  static const int _inW = 640;
  static const int _inH = 640;
  static const int _inC = 3;

  static const int _numCandidates = 8400;
  static const int _numOutputs = 6; // cx, cy, w, h + 2 class scores
  static const int _numClasses = 2;

  static const double _normDiv = 255.0;

  // Configurable thresholds + labels (NOT final, so we can update them)
  double confThreshold = 0.5;
  double iouThreshold = 0.5;
  List<String> labels = const ['Healthy', 'Diseased'];

  bool get isInitialized => _isInitialized;

  Future<void> initializeModel({
    String assetPath = 'assets/model/best_float32.tflite',
    int threads = 4,
    double? confThreshold,
    double? iouThreshold,
    List<String>? labels,
  }) async {
    try {
      final options = InterpreterOptions()..threads = threads;
      _interpreter = await Interpreter.fromAsset(assetPath, options: options);
      _isInitialized = true;

      // Apply overrides if provided
      if (confThreshold != null) this.confThreshold = confThreshold;
      if (iouThreshold != null) this.iouThreshold = iouThreshold;
      if (labels != null) this.labels = labels;

      // ignore: avoid_print
      print('TFLite Model initialized: $assetPath');
    } catch (e) {
      _isInitialized = false;
      _interpreter = null;
      // ignore: avoid_print
      print('Error initializing TFLite model: $e');
      rethrow;
    }
  }

  Future<void> ensureInitialized({
    String assetPath = 'assets/model/best_float32.tflite',
    int threads = 4,
  }) async {
    if (_isInitialized && _interpreter != null) return;
    await initializeModel(assetPath: assetPath, threads: threads);
  }

  /// imagePath can be:
  /// - file path: /storage/.../photo.jpg
  /// - OR asset path: assets/images/photo.jpg
  Future<ModelPrediction> predictFromImage(String imagePath) async {
    if (!_isInitialized || _interpreter == null) {
      return ModelPrediction.empty();
    }

    try {
      // 1) Preprocess to flat Float32List [H*W*C]
      final Float32List inputFlat = await _preprocessToFloat32(imagePath);

      // 2) Convert to 4D nested list [1][H][W][C] (no reshape needed)
      final input4d = _to4D(inputFlat);

      // 3) Output buffer: [1][6][8400]
      final output = List.generate(
        1,
        (_) =>
            List.generate(_numOutputs, (_) => List.filled(_numCandidates, 0.0)),
      );

      // 4) Run inference
      _interpreter!.run(input4d, output);

      // 5) Postprocess
      final detections = _postprocess(output);

      // 6) Count Healthy vs Diseased
      int healthy = 0;
      int diseased = 0;
      double bestScore = 0.0;

      for (final d in detections) {
        if (d.classId == 0) {
          healthy++;
        } else {
          diseased++;
        }
        bestScore = max(bestScore, d.score);
      }

      String status;
      if (detections.isEmpty) {
        status = 'Unknown';
      } else if (diseased > 0) {
        status = 'Diseased';
      } else {
        status = 'Healthy';
      }

      return ModelPrediction(
        status: status,
        confidence: bestScore,
        healthyCount: healthy,
        diseasedCount: diseased,
        detections: detections,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error running model inference: $e');
      return ModelPrediction.empty();
    }
  }

  /// Decode + resize + normalize RGB to 0..1
  Future<Float32List> _preprocessToFloat32(String imagePath) async {
    Uint8List bytes;

    if (imagePath.startsWith('assets/')) {
      final bd = await rootBundle.load(imagePath);
      bytes = bd.buffer.asUint8List();
    } else {
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw Exception('Image not found: $imagePath');
      }
      bytes = file.readAsBytesSync();
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Failed to decode image');

    final resized = img.copyResize(decoded, width: _inW, height: _inH);

    final input = Float32List(_inW * _inH * _inC);
    int idx = 0;

    for (int y = 0; y < _inH; y++) {
      for (int x = 0; x < _inW; x++) {
        final px = resized.getPixel(x, y);

        // Most compatible across image versions:
        // px.r/px.g/px.b can be int or num depending on version
        input[idx++] = (px.r).toDouble() / _normDiv;
        input[idx++] = (px.g).toDouble() / _normDiv;
        input[idx++] = (px.b).toDouble() / _normDiv;
      }
    }

    return input;
  }

  /// Convert flat NHWC [H*W*C] -> nested [1][H][W][C]
  List<List<List<List<double>>>> _to4D(Float32List flat) {
    final input = List.generate(
      1,
      (_) => List.generate(
        _inH,
        (_) => List.generate(_inW, (_) => List.filled(_inC, 0.0)),
      ),
    );

    int idx = 0;
    for (int y = 0; y < _inH; y++) {
      for (int x = 0; x < _inW; x++) {
        input[0][y][x][0] = flat[idx++]; // R
        input[0][y][x][1] = flat[idx++]; // G
        input[0][y][x][2] = flat[idx++]; // B
      }
    }
    return input;
  }

  /// Output format assumed:
  /// [cx, cy, w, h, score0, score1] length 8400 each
  List<Detection> _postprocess(List<List<List<double>>> output) {
    final ch = output[0];

    if (ch.length != _numOutputs || ch[0].length != _numCandidates) {
      throw Exception(
        'Unexpected output shape: [${ch.length}][${ch[0].length}]',
      );
    }

    final cxArr = ch[0];
    final cyArr = ch[1];
    final wArr = ch[2];
    final hArr = ch[3];
    final c0 = ch[4];
    final c1 = ch[5];

    final raw = <Detection>[];

    for (int i = 0; i < _numCandidates; i++) {
      final s0 = c0[i];
      final s1 = c1[i];

      final classId = (s0 > s1) ? 1 : 0;
      final score = (classId == 1) ? s0 : s1;

      if (score < confThreshold) continue;

      final cx = cxArr[i];
      final cy = cyArr[i];
      final w = wArr[i];
      final h = hArr[i];

      // center -> corners
      final x1 = cx - w / 2.0;
      final y1 = cy - h / 2.0;
      final x2 = cx + w / 2.0;
      final y2 = cy + h / 2.0;

      raw.add(
        Detection(
          classId: classId,
          score: score,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
        ),
      );
    }

    // NMS per class
    final results = <Detection>[];
    for (int cls = 0; cls < _numClasses; cls++) {
      final clsDet = raw.where((d) => d.classId == cls).toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      results.addAll(_nms(clsDet, iouThreshold));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  List<Detection> _nms(List<Detection> dets, double iouThr) {
    final kept = <Detection>[];
    final suppressed = List<bool>.filled(dets.length, false);

    for (int i = 0; i < dets.length; i++) {
      if (suppressed[i]) continue;

      final a = dets[i];
      kept.add(a);

      for (int j = i + 1; j < dets.length; j++) {
        if (suppressed[j]) continue;

        final b = dets[j];
        if (_iou(a, b) >= iouThr) suppressed[j] = true;
      }
    }

    return kept;
  }

  double _iou(Detection a, Detection b) {
    final interX1 = max(a.x1, b.x1);
    final interY1 = max(a.y1, b.y1);
    final interX2 = min(a.x2, b.x2);
    final interY2 = min(a.y2, b.y2);

    final interW = max(0.0, interX2 - interX1);
    final interH = max(0.0, interY2 - interY1);
    final interArea = interW * interH;

    final areaA = max(0.0, a.x2 - a.x1) * max(0.0, a.y2 - a.y1);
    final areaB = max(0.0, b.x2 - b.x1) * max(0.0, b.y2 - b.y1);

    final union = areaA + areaB - interArea;
    if (union <= 0) return 0.0;
    return interArea / union;
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

class Detection {
  final int classId;
  final double score;
  final double x1, y1, x2, y2;

  Detection({
    required this.classId,
    required this.score,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  @override
  String toString() =>
      'Detection(classId=$classId, score=${score.toStringAsFixed(3)}, box=[$x1,$y1,$x2,$y2])';
}

class ModelPrediction {
  final String status; // Healthy / Diseased / Unknown
  final double confidence;
  final int healthyCount;
  final int diseasedCount;
  final List<Detection> detections;

  ModelPrediction({
    required this.status,
    required this.confidence,
    required this.healthyCount,
    required this.diseasedCount,
    required this.detections,
  });

  factory ModelPrediction.empty() => ModelPrediction(
    status: 'Unknown',
    confidence: 0.0,
    healthyCount: 0,
    diseasedCount: 0,
    detections: const [],
  );

  @override
  String toString() =>
      'ModelPrediction(status=$status, conf=${confidence.toStringAsFixed(3)}, healthy=$healthyCount, diseased=$diseasedCount, detections=${detections.length})';
}
