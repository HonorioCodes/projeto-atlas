import 'package:flutter/material.dart';

import '../../services/plan_storage_service.dart';
import '../plans/plans_screen.dart';

class WalkingPlanScreen extends StatefulWidget {
  const WalkingPlanScreen({super.key});

  @override
  State<WalkingPlanScreen> createState() =>
      _WalkingPlanScreenState();
}

class _WalkingPlanScreenState
    extends State<WalkingPlanScreen> {
  final List<bool> _completedWorkouts = [
    false,
    false,
    false,
  ];

  double get _progress {
    final completed = _completedWorkouts
        .where((workout) => workout)
        .length;

    return completed / _completedWorkouts.length;
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
    required String title,
    required String duration,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: _completedWorkouts[index],
        onChanged: (value) {
          setState(() {
            _completedWorkouts[index] = value ?? false;
          });
        },
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$duration\n$description',
          ),
        ),
        isThreeLine: true,
        controlAffinity:
            ListTileControlAffinity.trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedWorkouts
        .where((workout) => workout)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caminhada para Iniciantes'),
        actions: [
          IconButton(
            onPressed: _changePlan,
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Trocar plano',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Semana 1',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '$completed de 3 treinos concluídos',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 24),
          _buildWorkoutCard(
            index: 0,
            title: 'Treino 1',
            duration: '30 minutos',
            description:
                '5 min leves, 20 min de caminhada e 5 min leves.',
          ),
          _buildWorkoutCard(
            index: 1,
            title: 'Treino 2',
            duration: '35 minutos',
            description:
                '5 min leves, 25 min de caminhada e 5 min leves.',
          ),
          _buildWorkoutCard(
            index: 2,
            title: 'Treino 3',
            duration: '40 minutos',
            description:
                '5 min leves, 30 min de caminhada e 5 min leves.',
          ),
        ],
      ),
    );
  }
}