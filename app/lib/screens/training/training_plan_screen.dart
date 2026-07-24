import 'package:flutter/material.dart';

import '../../models/training_week_model.dart';
import '../../models/workout_model.dart';
import '../../services/plan_storage_service.dart';
import '../../services/workout_progress_service.dart';
import '../charts/progress_charts_screen.dart';
import '../history/workout_history_screen.dart';
import '../location/location_setup_screen.dart';
import '../plans/plans_screen.dart';
import '../profile/profile_screen.dart';
import '../weight/weight_progress_screen.dart';
import '../workout/workout_detail_screen.dart';

enum _EvolutionMenuAction { weight, statistics, charts }

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
  State<TrainingPlanScreen> createState() {
    return _TrainingPlanScreenState();
  }
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  final WorkoutProgressService _progressService = WorkoutProgressService();

  late List<bool> _completedWorkouts;

  bool _isLoading = true;

  int get _workoutCount {
    return widget.weeks.fold<int>(0, (total, week) {
      return total + week.workouts.length;
    });
  }

  int get _completedCount {
    return _completedWorkouts.where((workout) => workout).length;
  }

  double get _progress {
    if (_workoutCount == 0) {
      return 0;
    }

    return _completedCount / _workoutCount;
  }

  int get _currentWeekIndex {
    for (var weekIndex = 0; weekIndex < widget.weeks.length; weekIndex++) {
      final isUnlocked = _isWeekUnlocked(weekIndex);

      final isCompleted = _isWeekCompleted(weekIndex);

      if (isUnlocked && !isCompleted) {
        return weekIndex;
      }
    }

    return widget.weeks.length - 1;
  }

  @override
  void initState() {
    super.initState();

    _completedWorkouts = List<bool>.filled(_workoutCount, false);

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

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ProfileScreen(selectedPlanTitle: widget.title);
        },
      ),
    );
  }

  Future<void> _openLocationSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const LocationSetupScreen();
        },
      ),
    );
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const WorkoutHistoryScreen();
        },
      ),
    );
  }

  Future<void> _openWeightProgress() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const WeightProgressScreen();
        },
      ),
    );
  }

  Future<void> _openProgressCharts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const ProgressChartsScreen();
        },
      ),
    );
  }

  Future<void> _handleEvolutionMenu(_EvolutionMenuAction action) {
    switch (action) {
      case _EvolutionMenuAction.weight:
        return _openWeightProgress();

      case _EvolutionMenuAction.statistics:
        return _openHistory();

      case _EvolutionMenuAction.charts:
        return _openProgressCharts();
    }
  }

  Future<void> _updateWorkout(int index, bool isCompleted) async {
    setState(() {
      _completedWorkouts[index] = isCompleted;
    });

    await _progressService.saveProgress(widget.planId, _completedWorkouts);
  }

  Future<void> _openWorkoutDetails({
    required int index,
    required WorkoutModel workout,
    required bool isUnlocked,
  }) async {
    if (!isUnlocked) {
      return;
    }

    final newStatus = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) {
          return WorkoutDetailScreen(
            workout: workout,
            isCompleted: _completedWorkouts[index],
          );
        },
      ),
    );

    if (newStatus == null || newStatus == _completedWorkouts[index]) {
      return;
    }

    await _updateWorkout(index, newStatus);
  }

  Future<void> _changePlan() async {
    await PlanStorageService().deleteSelectedPlan();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) {
          return const PlansScreen();
        },
      ),
      (route) => false,
    );
  }

  int _getWeekStartIndex(int weekIndex) {
    var startIndex = 0;

    for (var index = 0; index < weekIndex; index++) {
      startIndex += widget.weeks[index].workouts.length;
    }

    return startIndex;
  }

  bool _isWeekUnlocked(int weekIndex) {
    if (weekIndex == 0) {
      return true;
    }

    final previousWeekIndex = weekIndex - 1;

    final previousWeek = widget.weeks[previousWeekIndex];

    final previousWeekStartIndex = _getWeekStartIndex(previousWeekIndex);

    final previousWeekEndIndex =
        previousWeekStartIndex + previousWeek.workouts.length;

    return _completedWorkouts
        .sublist(previousWeekStartIndex, previousWeekEndIndex)
        .every((workout) => workout);
  }

  bool _isWeekCompleted(int weekIndex) {
    final week = widget.weeks[weekIndex];

    final startIndex = _getWeekStartIndex(weekIndex);

    final endIndex = startIndex + week.workouts.length;

    return _completedWorkouts
        .sublist(startIndex, endIndex)
        .every((workout) => workout);
  }

  Widget _buildWorkoutCard({
    required int index,
    required WorkoutModel workout,
    required bool isUnlocked,
  }) {
    return Opacity(
      opacity: isUnlocked ? 1 : 0.55,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          onTap: isUnlocked
              ? () {
                  _openWorkoutDetails(
                    index: index,
                    workout: workout,
                    isUnlocked: isUnlocked,
                  );
                }
              : null,
          leading: Icon(
            isUnlocked ? Icons.directions_walk : Icons.lock_outline,
          ),
          title: Text(workout.title),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${workout.duration}\n'
              '${workout.description}',
            ),
          ),
          isThreeLine: true,
          trailing: isUnlocked
              ? Checkbox(
                  value: _completedWorkouts[index],
                  onChanged: (value) {
                    _updateWorkout(index, value ?? false);
                  },
                )
              : null,
        ),
      ),
    );
  }

  List<Widget> _buildWeeks(BuildContext context) {
    final widgets = <Widget>[];

    var workoutIndex = 0;

    for (var weekIndex = 0; weekIndex < widget.weeks.length; weekIndex++) {
      final week = widget.weeks[weekIndex];

      final isUnlocked = _isWeekUnlocked(weekIndex);

      final isCompleted = _isWeekCompleted(weekIndex);

      final isCurrent =
          isUnlocked && !isCompleted && weekIndex == _currentWeekIndex;

      final firstIndex = workoutIndex;

      final lastIndex = firstIndex + week.workouts.length;

      final completedInWeek = _completedWorkouts
          .sublist(firstIndex, lastIndex)
          .where((workout) => workout)
          .length;

      widgets.add(
        Row(
          children: [
            Expanded(
              child: Text(
                week.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (!isUnlocked)
              const Chip(
                avatar: Icon(Icons.lock_outline, size: 18),
                label: Text('Bloqueada'),
              )
            else if (isCompleted)
              const Chip(
                avatar: Icon(Icons.check_circle_outline, size: 18),
                label: Text('Concluída'),
              )
            else if (isCurrent)
              const Chip(
                avatar: Icon(Icons.play_circle_outline, size: 18),
                label: Text('Atual'),
              ),
          ],
        ),
      );

      widgets.add(const SizedBox(height: 8));

      if (isUnlocked) {
        widgets.add(
          Text(
            '$completedInWeek de '
            '${week.workouts.length} '
            'treinos concluídos',
          ),
        );
      } else {
        widgets.add(
          const Text(
            'Conclua a semana anterior '
            'para liberar.',
          ),
        );
      }

      widgets.add(const SizedBox(height: 12));

      for (final workout in week.workouts) {
        widgets.add(
          _buildWorkoutCard(
            index: workoutIndex,
            workout: workout,
            isUnlocked: isUnlocked,
          ),
        );

        workoutIndex++;
      }

      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  PopupMenuItem<_EvolutionMenuAction> _buildEvolutionMenuItem({
    required _EvolutionMenuAction value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<_EvolutionMenuAction>(
      value: value,
      child: Row(
        children: [Icon(icon), const SizedBox(width: 12), Text(label)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline),
            tooltip: 'Meu perfil',
          ),
          IconButton(
            onPressed: _openLocationSetup,
            icon: const Icon(Icons.gps_fixed),
            tooltip: 'Configurar GPS',
          ),
          PopupMenuButton<_EvolutionMenuAction>(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Evolução',
            onSelected: _handleEvolutionMenu,
            itemBuilder: (context) {
              return [
                _buildEvolutionMenuItem(
                  value: _EvolutionMenuAction.weight,
                  icon: Icons.monitor_weight_outlined,
                  label: 'Evolução do peso',
                ),
                _buildEvolutionMenuItem(
                  value: _EvolutionMenuAction.statistics,
                  icon: Icons.analytics_outlined,
                  label: 'Estatísticas',
                ),
                _buildEvolutionMenuItem(
                  value: _EvolutionMenuAction.charts,
                  icon: Icons.show_chart,
                  label: 'Gráficos',
                ),
              ];
            },
          ),
          IconButton(
            onPressed: _changePlan,
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Trocar plano',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Progresso geral'),
                const SizedBox(height: 8),
                Text(
                  '$_completedCount de '
                  '$_workoutCount '
                  'treinos concluídos',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 24),
                ..._buildWeeks(context),
              ],
            ),
    );
  }
}
