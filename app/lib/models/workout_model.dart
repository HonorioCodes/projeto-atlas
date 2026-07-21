import 'workout_step_model.dart';

class WorkoutModel {
  final String title;
  final String duration;
  final String description;
  final List<WorkoutStepModel> steps;

  const WorkoutModel({
    required this.title,
    required this.duration,
    required this.description,
    this.steps = const [],
  });
}