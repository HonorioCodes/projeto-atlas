class UserModel {
  final String name;
  final DateTime birthDate;
  final String sex;
  final double height;
  final double currentWeight;
  final double? targetWeight;
  final String mainGoal;

  const UserModel({
    required this.name,
    required this.birthDate,
    required this.sex,
    required this.height,
    required this.currentWeight,
    this.targetWeight,
    required this.mainGoal,
  });

  int get age {
    final today = DateTime.now();

    var calculatedAge = today.year - birthDate.year;

    final birthdayHasNotOccurredYet =
        today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day);

    if (birthdayHasNotOccurredYet) {
      calculatedAge--;
    }

    return calculatedAge;
  }

  double get bmi {
    final heightInMeters = height / 100;

    if (heightInMeters <= 0) {
      return 0;
    }

    return currentWeight / (heightInMeters * heightInMeters);
  }

  String get bmiClassification {
    final value = bmi;

    if (value < 18.5) {
      return 'Abaixo do peso';
    }

    if (value < 25) {
      return 'Peso normal';
    }

    if (value < 30) {
      return 'Sobrepeso';
    }

    if (value < 35) {
      return 'Obesidade grau I';
    }

    if (value < 40) {
      return 'Obesidade grau II';
    }

    return 'Obesidade grau III';
  }

  UserModel copyWith({
    String? name,
    DateTime? birthDate,
    String? sex,
    double? height,
    double? currentWeight,
    double? targetWeight,
    String? mainGoal,
  }) {
    return UserModel(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      height: height ?? this.height,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      mainGoal: mainGoal ?? this.mainGoal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'sex': sex,
      'height': height,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'mainGoal': mainGoal,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] as String? ?? '',
      birthDate:
          DateTime.tryParse(map['birthDate'] as String? ?? '') ??
          DateTime.now(),
      sex: map['sex'] as String? ?? '',
      height: (map['height'] as num?)?.toDouble() ?? 0,
      currentWeight: (map['currentWeight'] as num?)?.toDouble() ?? 0,
      targetWeight: map['targetWeight'] == null
          ? null
          : (map['targetWeight'] as num).toDouble(),
      mainGoal: map['mainGoal'] as String? ?? '',
    );
  }
}
