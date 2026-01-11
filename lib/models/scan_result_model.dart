class ScanResult {
  final int? id;
  final String rawImagePath;
  final String? annotatedImagePath;
  final String status; // 'Healthy', 'Grasserie', 'Flacherie'
  final String scanDate;
  final String scanTime;
  final int healthyCount;
  final int grasserieCount;
  final int flacherieCount;
  final DateTime? createdAt;

  ScanResult({
    this.id,
    required this.rawImagePath,
    this.annotatedImagePath,
    required this.status,
    required this.scanDate,
    required this.scanTime,
    this.healthyCount = 0,
    this.grasserieCount = 0,
    this.flacherieCount = 0,
    this.createdAt,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'raw_image_path': rawImagePath,
      'annotated_image_path': annotatedImagePath,
      'status': status,
      'scan_date': scanDate,
      'scan_time': scanTime,
      'healthy_count': healthyCount,
      'grasserie_count': grasserieCount,
      'flacherie_count': flacherieCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Convert from map for database
  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'] as int?,
      rawImagePath: map['raw_image_path'] as String,
      annotatedImagePath: map['annotated_image_path'] as String?,
      status: map['status'] as String,
      scanDate: map['scan_date'] as String,
      scanTime: map['scan_time'] as String,
      healthyCount: map['healthy_count'] as int? ?? 0,
      grasserieCount: map['grasserie_count'] as int? ?? 0,
      flacherieCount: map['flacherie_count'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  // Copy with method for updating fields
  ScanResult copyWith({
    int? id,
    String? rawImagePath,
    String? annotatedImagePath,
    String? status,
    String? scanDate,
    String? scanTime,
    int? healthyCount,
    int? grasserieCount,
    int? flacherieCount,
    DateTime? createdAt,
  }) {
    return ScanResult(
      id: id ?? this.id,
      rawImagePath: rawImagePath ?? this.rawImagePath,
      annotatedImagePath: annotatedImagePath ?? this.annotatedImagePath,
      status: status ?? this.status,
      scanDate: scanDate ?? this.scanDate,
      scanTime: scanTime ?? this.scanTime,
      healthyCount: healthyCount ?? this.healthyCount,
      grasserieCount: grasserieCount ?? this.grasserieCount,
      flacherieCount: flacherieCount ?? this.flacherieCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ScanResult(id: $id, status: $status, date: $scanDate, time: $scanTime, healthy: $healthyCount, grasserie: $grasserieCount, flacherie: $flacherieCount)';
  }
}
