import 'package:flutter/material.dart';

import '../../models/training_week_model.dart';
import '../../models/workout_model.dart';
import '../../services/plan_storage_service.dart';
import '../../services/workout_progress_service.dart';
import '../plans/plans_screen.dart';

class TrainingPlanScreen extends StatefulWidget {
  final String planId;
  final String title;
  final List<TrainingWeekModel> weeks;

  const TrainingPlanScreen({
    super.key,
    required this.planId,
    required this.title,
    required this.weeks,
  });

  @override
  State<TrainingPlanScreen> createState() =>
      _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  final WorkoutProgressService _progressService =
      WorkoutProgressService();

  late List<bool> _completedWorkouts;
  bool _isLoading = true;

  int get _workoutCount {
    return widget.weeks.fold<int>(
      0,
      (total, week) => total + week.workouts.length,
    );
  }

  int get _completedCount {
    return _completedWorkouts
        .where((workout) => workout)
        .length;
  }

  double get _progress {
    if (_workoutCount == 0) {
      return 0;
    }

    return _completedCount / _workoutCount;
  }

  @override
  void initState() {
    super.initState();

    _completedWorkouts = List<bool>.filled(
      _workoutCount,
      false,
    );

    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await _progressService.loadProgress(
      widget.planId,
      _workoutCount,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _completedWorkouts = progress;
      _isLoading = false;
    });
  }

  Future<void> _updateWorkout(
    int index,
    bool isCompleted,
  ) async {
    setState(() {
      _completedWorkouts[index] = isCompleted;
    });

    await _progressService.saveProgress(
      widget.planId,
      _completedWorkouts,
    );
  }

  Future<void> _changePlan() async {
    await PlanStorageService().deleteSelectedPlan();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const PlansScreen(),
      ),
      (route) => false,
    );
  }

  Widget _buildWorkoutCard({
    required int index,
    required WorkoutModel workout,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: _completedWorkouts[index],
        onChanged: (value) {
          _updateWorkout(
            index,
            value ?? false,
          );
        },
        title: Text(workout.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${workout.duration}\n${workout.description}',
          ),
        ),
        isThreeLine: true,
        controlAffinity:
            ListTileControlAffinity.trailing,
      ),
    );
  }

  List<Widget> _buildWeeks(BuildContext context) {
    final widgets = <Widget>[];
    var workoutIndex = 0;

    for (final week in widget.weeks) {
      final firstIndex = workoutIndex;
      final lastIndex =
          firstIndex + week.workouts.length;

      final completedInWeek = _completedWorkouts
          .sublist(firstIndex, lastIndex)
          .where((workout) => workout)
          .length;

      widgets.add(
        Text(
          week.title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall,
        ),
      );

      widgets.add(const SizedBox(height: 8));

      widgets.add(
        Text(
          '$completedInWeek de '
          '${week.workouts.length} treinos concluídos',
        ),
      );

      widgets.add(const SizedBox(height: 12));

      for (final workout in week.workouts) {
        widgets.add(
          _buildWorkoutCard(
            index: workoutIndex,
            workout: workout,
          ),
        );

        workoutIndex++;
      }

      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _changePlan,
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Trocar plano',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Progresso geral'),
                const SizedBox(height: 8),
                Text(
                  '$_completedCount de '
                  '$_workoutCount treinos concluídos',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                const SizedBox(height: 24),
                ..._buildWeeks(context),
              ],
            ),
    );
  }
}