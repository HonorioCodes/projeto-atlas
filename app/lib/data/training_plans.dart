import '../models/training_week_model.dart';
import '../models/workout_model.dart';
import '../models/workout_step_model.dart';

String _durationLabel(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  if (seconds == 0) {
    return '$minutes minutos';
  }

  return '$minutes min ${seconds}s';
}

String _intervalLabel(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;

  if (minutes == 0) {
    return '$remainingSeconds segundos';
  }

  if (remainingSeconds == 0) {
    return minutes == 1
        ? '1 minuto'
        : '$minutes minutos';
  }

  return '$minutes min e ${remainingSeconds}s';
}

WorkoutModel _steadyWalkingWorkout({
  required String title,
  required int warmUpMinutes,
  required int walkingMinutes,
  required int coolDownMinutes,
}) {
  final totalMinutes =
      warmUpMinutes + walkingMinutes + coolDownMinutes;

  return WorkoutModel(
    title: title,
    duration: '$totalMinutes minutos',
    description:
        '$warmUpMinutes min leves, '
        '$walkingMinutes min de caminhada e '
        '$coolDownMinutes min leves.',
    steps: [
      WorkoutStepModel(
        title: 'Aquecimento',
        instruction:
            'Caminhe devagar e prepare o corpo para o treino.',
        durationSeconds: warmUpMinutes * 60,
      ),
      WorkoutStepModel(
        title: 'Caminhada',
        instruction:
            'Mantenha um ritmo confortável e constante.',
        durationSeconds: walkingMinutes * 60,
      ),
      WorkoutStepModel(
        title: 'Desaceleração',
        instruction:
            'Diminua o ritmo gradualmente até finalizar.',
        durationSeconds: coolDownMinutes * 60,
      ),
    ],
  );
}

WorkoutModel _alternatingWalkingWorkout({
  required String title,
  required int warmUpMinutes,
  required int repetitions,
  required int comfortableMinutes,
  required int fasterMinutes,
  required int coolDownMinutes,
}) {
  final totalMinutes =
      warmUpMinutes +
      repetitions *
          (comfortableMinutes + fasterMinutes) +
      coolDownMinutes;

  final steps = <WorkoutStepModel>[
    WorkoutStepModel(
      title: 'Aquecimento',
      instruction:
          'Caminhe devagar e prepare o corpo.',
      durationSeconds: warmUpMinutes * 60,
    ),
  ];

  for (
    var repetition = 1;
    repetition <= repetitions;
    repetition++
  ) {
    steps.add(
      WorkoutStepModel(
        title: 'Ritmo confortável $repetition/$repetitions',
        instruction:
            'Caminhe em um ritmo que permita conversar.',
        durationSeconds: comfortableMinutes * 60,
      ),
    );

    steps.add(
      WorkoutStepModel(
        title: 'Ritmo acelerado $repetition/$repetitions',
        instruction:
            'Aumente o ritmo sem precisar correr.',
        durationSeconds: fasterMinutes * 60,
      ),
    );
  }

  steps.add(
    WorkoutStepModel(
      title: 'Desaceleração',
      instruction:
          'Diminua o ritmo gradualmente.',
      durationSeconds: coolDownMinutes * 60,
    ),
  );

  return WorkoutModel(
    title: title,
    duration: '$totalMinutes minutos',
    description:
        'Após o aquecimento, alterne '
        '$comfortableMinutes min em ritmo confortável '
        'com $fasterMinutes min em ritmo acelerado.',
    steps: steps,
  );
}

WorkoutModel _runWalkWorkout({
  required String title,
  required int warmUpSeconds,
  required int repetitions,
  required int runningSeconds,
  required int walkingSeconds,
  required int coolDownSeconds,
  String? additionalInstruction,
}) {
  final totalSeconds =
      warmUpSeconds +
      repetitions *
          (runningSeconds + walkingSeconds) +
      coolDownSeconds;

  final steps = <WorkoutStepModel>[
    WorkoutStepModel(
      title: 'Aquecimento',
      instruction:
          'Caminhe devagar antes de iniciar os intervalos.',
      durationSeconds: warmUpSeconds,
    ),
  ];

  for (
    var repetition = 1;
    repetition <= repetitions;
    repetition++
  ) {
    steps.add(
      WorkoutStepModel(
        title: 'Trote $repetition/$repetitions',
        instruction:
            'Trote devagar. Não tente correr em velocidade máxima.',
        durationSeconds: runningSeconds,
      ),
    );

    steps.add(
      WorkoutStepModel(
        title: 'Recuperação $repetition/$repetitions',
        instruction:
            'Caminhe e recupere a respiração.',
        durationSeconds: walkingSeconds,
      ),
    );
  }

  steps.add(
    WorkoutStepModel(
      title: 'Desaceleração',
      instruction:
          'Caminhe devagar para finalizar o treino.',
      durationSeconds: coolDownSeconds,
    ),
  );

  final description =
      '${warmUpSeconds ~/ 60} min caminhando, '
      '$repetitions repetições de '
      '${_intervalLabel(runningSeconds)} trotando e '
      '${_intervalLabel(walkingSeconds)} caminhando.'
      '${additionalInstruction == null ? '' : ' $additionalInstruction'}';

  return WorkoutModel(
    title: title,
    duration: _durationLabel(totalSeconds),
    description: description,
    steps: steps,
  );
}

final List<TrainingWeekModel> walkingTrainingWeeks = [
  TrainingWeekModel(
    number: 1,
    workouts: [
      _steadyWalkingWorkout(
        title: 'Treino 1',
        warmUpMinutes: 5,
        walkingMinutes: 20,
        coolDownMinutes: 5,
      ),
      _steadyWalkingWorkout(
        title: 'Treino 2',
        warmUpMinutes: 5,
        walkingMinutes: 25,
        coolDownMinutes: 5,
      ),
      _steadyWalkingWorkout(
        title: 'Treino 3',
        warmUpMinutes: 5,
        walkingMinutes: 30,
        coolDownMinutes: 5,
      ),
    ],
  ),
  TrainingWeekModel(
    number: 2,
    workouts: [
      _steadyWalkingWorkout(
        title: 'Treino 1',
        warmUpMinutes: 5,
        walkingMinutes: 25,
        coolDownMinutes: 5,
      ),
      _steadyWalkingWorkout(
        title: 'Treino 2',
        warmUpMinutes: 5,
        walkingMinutes: 30,
        coolDownMinutes: 5,
      ),
      _steadyWalkingWorkout(
        title: 'Treino 3',
        warmUpMinutes: 5,
        walkingMinutes: 35,
        coolDownMinutes: 5,
      ),
    ],
  ),
  TrainingWeekModel(
    number: 3,
    workouts: [
      _steadyWalkingWorkout(
        title: 'Treino 1',
        warmUpMinutes: 5,
        walkingMinutes: 30,
        coolDownMinutes: 5,
      ),
      _alternatingWalkingWorkout(
        title: 'Treino 2',
        warmUpMinutes: 5,
        repetitions: 5,
        comfortableMinutes: 5,
        fasterMinutes: 2,
        coolDownMinutes: 5,
      ),
      _steadyWalkingWorkout(
        title: 'Treino 3',
        warmUpMinutes: 5,
        walkingMinutes: 40,
        coolDownMinutes: 5,
      ),
    ],
  ),
  TrainingWeekModel(
    number: 4,
    workouts: [
      _steadyWalkingWorkout(
        title: 'Treino 1',
        warmUpMinutes: 5,
        walkingMinutes: 35,
        coolDownMinutes: 5,
      ),
      _alternatingWalkingWorkout(
        title: 'Treino 2',
        warmUpMinutes: 5,
        repetitions: 5,
        comfortableMinutes: 6,
        fasterMinutes: 2,
        coolDownMinutes: 5,
      ),
      _steadyWalkingWorkout(
        title: 'Treino 3',
        warmUpMinutes: 5,
        walkingMinutes: 45,
        coolDownMinutes: 5,
      ),
    ],
  ),
];

final List<TrainingWeekModel> couchTo5KTrainingWeeks = [
  TrainingWeekModel(
    number: 1,
    workouts: [
      _runWalkWorkout(
        title: 'Treino 1',
        warmUpSeconds: 300,
        repetitions: 6,
        runningSeconds: 60,
        walkingSeconds: 120,
        coolDownSeconds: 360,
      ),
      _runWalkWorkout(
        title: 'Treino 2',
        warmUpSeconds: 300,
        repetitions: 6,
        runningSeconds: 60,
        walkingSeconds: 120,
        coolDownSeconds: 360,
        additionalInstruction:
            'Mantenha um trote confortável.',
      ),
      _runWalkWorkout(
        title: 'Treino 3',
        warmUpSeconds: 300,
        repetitions: 7,
        runningSeconds: 60,
        walkingSeconds: 120,
        coolDownSeconds: 360,
      ),
    ],
  ),
  TrainingWeekModel(
    number: 2,
    workouts: [
      _runWalkWorkout(
        title: 'Treino 1',
        warmUpSeconds: 300,
        repetitions: 6,
        runningSeconds: 90,
        walkingSeconds: 120,
        coolDownSeconds: 300,
      ),
      _runWalkWorkout(
        title: 'Treino 2',
        warmUpSeconds: 300,
        repetitions: 6,
        runningSeconds: 90,
        walkingSeconds: 120,
        coolDownSeconds: 300,
        additionalInstruction:
            'Mantenha a respiração controlada.',
      ),
      _runWalkWorkout(
        title: 'Treino 3',
        warmUpSeconds: 300,
        repetitions: 7,
        runningSeconds: 90,
        walkingSeconds: 120,
        coolDownSeconds: 330,
      ),
    ],
  ),
  TrainingWeekModel(
    number: 3,
    workouts: [
      _runWalkWorkout(
        title: 'Treino 1',
        warmUpSeconds: 300,
        repetitions: 6,
        runningSeconds: 120,
        walkingSeconds: 120,
        coolDownSeconds: 300,
      ),
      _runWalkWorkout(
        title: 'Treino 2',
        warmUpSeconds: 300,
        repetitions: 6,
        runningSeconds: 120,
        walkingSeconds: 120,
        coolDownSeconds: 300,
        additionalInstruction:
            'Priorize um trote leve e constante.',
      ),
      _runWalkWorkout(
        title: 'Treino 3',
        warmUpSeconds: 300,
        repetitions: 7,
        runningSeconds: 120,
        walkingSeconds: 120,
        coolDownSeconds: 300,
      ),
    ],
  ),
  TrainingWeekModel(
    number: 4,
    workouts: [
      _runWalkWorkout(
        title: 'Treino 1',
        warmUpSeconds: 300,
        repetitions: 5,
        runningSeconds: 180,
        walkingSeconds: 120,
        coolDownSeconds: 300,
      ),
      _runWalkWorkout(
        title: 'Treino 2',
        warmUpSeconds: 300,
        repetitions: 5,
        runningSeconds: 180,
        walkingSeconds: 120,
        coolDownSeconds: 300,
        additionalInstruction:
            'Não busque velocidade. Priorize completar o tempo.',
      ),
      _runWalkWorkout(
        title: 'Treino 3',
        warmUpSeconds: 300,
        repetitions: 6,
        runningSeconds: 180,
        walkingSeconds: 120,
        coolDownSeconds: 300,
      ),
    ],
  ),
];