enum DistanceDisplayUnit { automatic, kilometers, meters }

class TrainingSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool requireGpsToStart;
  final bool keepScreenAwake;
  final DistanceDisplayUnit distanceDisplayUnit;

  const TrainingSettings({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.requireGpsToStart,
    required this.keepScreenAwake,
    required this.distanceDisplayUnit,
  });

  static const TrainingSettings defaults = TrainingSettings(
    soundEnabled: true,
    vibrationEnabled: true,
    requireGpsToStart: true,
    keepScreenAwake: false,
    distanceDisplayUnit: DistanceDisplayUnit.automatic,
  );

  TrainingSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? requireGpsToStart,
    bool? keepScreenAwake,
    DistanceDisplayUnit? distanceDisplayUnit,
  }) {
    return TrainingSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      requireGpsToStart: requireGpsToStart ?? this.requireGpsToStart,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      distanceDisplayUnit: distanceDisplayUnit ?? this.distanceDisplayUnit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'requireGpsToStart': requireGpsToStart,
      'keepScreenAwake': keepScreenAwake,
      'distanceDisplayUnit': distanceDisplayUnit.name,
    };
  }

  factory TrainingSettings.fromJson(Map<String, dynamic> json) {
    final rawDistanceDisplayUnit = json['distanceDisplayUnit'];

    final distanceDisplayUnit = DistanceDisplayUnit.values.firstWhere(
      (unit) => unit.name == rawDistanceDisplayUnit,
      orElse: () => DistanceDisplayUnit.automatic,
    );

    return TrainingSettings(
      soundEnabled: json['soundEnabled'] is bool
          ? json['soundEnabled'] as bool
          : defaults.soundEnabled,
      vibrationEnabled: json['vibrationEnabled'] is bool
          ? json['vibrationEnabled'] as bool
          : defaults.vibrationEnabled,
      requireGpsToStart: json['requireGpsToStart'] is bool
          ? json['requireGpsToStart'] as bool
          : defaults.requireGpsToStart,
      keepScreenAwake: json['keepScreenAwake'] is bool
          ? json['keepScreenAwake'] as bool
          : defaults.keepScreenAwake,
      distanceDisplayUnit: distanceDisplayUnit,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TrainingSettings &&
            soundEnabled == other.soundEnabled &&
            vibrationEnabled == other.vibrationEnabled &&
            requireGpsToStart == other.requireGpsToStart &&
            keepScreenAwake == other.keepScreenAwake &&
            distanceDisplayUnit == other.distanceDisplayUnit;
  }

  @override
  int get hashCode {
    return Object.hash(
      soundEnabled,
      vibrationEnabled,
      requireGpsToStart,
      keepScreenAwake,
      distanceDisplayUnit,
    );
  }
}
