class WorkoutSessionRecord {
  final String id;
  final String workoutTitle;
  final DateTime completedAt;
  final int elapsedSeconds;
  final int plannedSeconds;
  final bool completedManually;
  final double distanceMeters;
  final int validGpsPointCount;

  const WorkoutSessionRecord({
    required this.id,
    required this.workoutTitle,
    required this.completedAt,
    required this.elapsedSeconds,
    required this.plannedSeconds,
    required this.completedManually,
    this.distanceMeters = 0,
    this.validGpsPointCount = 0,
  });

  double? get averageSpeedKmPerHour {
    if (elapsedSeconds <= 0 || distanceMeters <= 0) {
      return null;
    }

    final distanceKilometers = distanceMeters / 1000;
    final elapsedHours = elapsedSeconds / 3600;

    return distanceKilometers / elapsedHours;
  }

  int? get averagePaceSecondsPerKm {
    if (elapsedSeconds <= 0 || distanceMeters <= 0) {
      return null;
    }

    final distanceKilometers = distanceMeters / 1000;

    return (elapsedSeconds / distanceKilometers).round();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutTitle': workoutTitle,
      'completedAt': completedAt.toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
      'plannedSeconds': plannedSeconds,
      'completedManually': completedManually,
      'distanceMeters': distanceMeters,
      'validGpsPointCount': validGpsPointCount,
    };
  }

  factory WorkoutSessionRecord.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionRecord(
      id: json['id'] as String? ?? '',
      workoutTitle: json['workoutTitle'] as String? ?? 'Treino',
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      plannedSeconds: (json['plannedSeconds'] as num?)?.toInt() ?? 0,
      completedManually: json['completedManually'] as bool? ?? false,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      validGpsPointCount: (json['validGpsPointCount'] as num?)?.toInt() ?? 0,
    );
  }
}
