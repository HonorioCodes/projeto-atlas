class WeightRecord {
  final String id;
  final double weightKg;
  final DateTime recordedAt;

  const WeightRecord({
    required this.id,
    required this.weightKg,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weightKg': weightKg,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] as String? ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
