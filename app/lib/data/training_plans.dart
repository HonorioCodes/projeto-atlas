import '../models/training_week_model.dart';
import '../models/workout_model.dart';

const List<TrainingWeekModel> walkingTrainingWeeks = [
  TrainingWeekModel(
    number: 1,
    workouts: [
      WorkoutModel(
        title: 'Treino 1',
        duration: '30 minutos',
        description:
            '5 min leves, 20 min de caminhada e 5 min leves.',
      ),
      WorkoutModel(
        title: 'Treino 2',
        duration: '35 minutos',
        description:
            '5 min leves, 25 min de caminhada e 5 min leves.',
      ),
      WorkoutModel(
        title: 'Treino 3',
        duration: '40 minutos',
        description:
            '5 min leves, 30 min de caminhada e 5 min leves.',
      ),
    ],
  ),
];

const List<TrainingWeekModel> couchTo5KTrainingWeeks = [
  TrainingWeekModel(
    number: 1,
    workouts: [
      WorkoutModel(
        title: 'Treino 1',
        duration: '29 minutos',
        description:
            '5 min caminhando, 6 repetições de 1 min trotando e 2 min caminhando, finalizando com 6 min leves.',
      ),
      WorkoutModel(
        title: 'Treino 2',
        duration: '29 minutos',
        description:
            'Repita o Treino 1 em ritmo confortável, sem correr em velocidade máxima.',
      ),
      WorkoutModel(
        title: 'Treino 3',
        duration: '32 minutos',
        description:
            '5 min caminhando, 7 repetições de 1 min trotando e 2 min caminhando, finalizando com 6 min leves.',
      ),
    ],
  ),
];