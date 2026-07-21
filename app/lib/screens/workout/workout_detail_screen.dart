import 'package:flutter/material.dart';

import '../../models/workout_model.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutModel workout;
  final bool isCompleted;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workout.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.timer_outlined,
                size: 32,
              ),
              title: const Text('Duração estimada'),
              subtitle: Text(workout.duration),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Como será o treino',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            workout.description,
            style: Theme.of(context)
                .textTheme
                .bodyLarge,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(
                !isCompleted,
              );
            },
            icon: Icon(
              isCompleted
                  ? Icons.undo
                  : Icons.check_circle_outline,
            ),
            label: Text(
              isCompleted
                  ? 'Marcar como pendente'
                  : 'Marcar como concluído',
            ),
          ),
        ],
      ),
    );
  }
}