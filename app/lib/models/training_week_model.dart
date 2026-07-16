import 'workout_model.dart';

class TrainingWeekModel {
  final int number;
  final List<WorkoutModel> workouts;

  const TrainingWeekModel({
    required this.number,
    required this.workouts,
  });

  String get title => 'Semana $number';
}