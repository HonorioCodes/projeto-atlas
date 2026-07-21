class WorkoutSessionRecord {
  final String id;
  final String workoutTitle;
  final DateTime completedAt;
  final int elapsedSeconds;
  final int plannedSeconds;
  final bool completedManually;

  const WorkoutSessionRecord({
    required this.id,
    required this.workoutTitle,
    required this.completedAt,
    required this.elapsedSeconds,
    required this.plannedSeconds,
    required this.completedManually,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutTitle': workoutTitle,
      'completedAt': completedAt.toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
      'plannedSeconds': plannedSeconds,
      'completedManually': completedManually,
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
    );
  }
}
