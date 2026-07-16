import 'package:flutter/material.dart';

import '../../services/plan_storage_service.dart';
import '../plans/plans_screen.dart';

class CouchTo5KScreen extends StatefulWidget {
  const CouchTo5KScreen({super.key});

  @override
  State<CouchTo5KScreen> createState() =>
      _CouchTo5KScreenState();
}

class _CouchTo5KScreenState extends State<CouchTo5KScreen> {
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
        title: const Text(
          'Da Caminhada à Corrida 5 km',
        ),
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
            duration: '29 minutos',
            description:
                '5 min caminhando, 6 repetições de 1 min trotando e 2 min caminhando, finalizando com 6 min leves.',
          ),
          _buildWorkoutCard(
            index: 1,
            title: 'Treino 2',
            duration: '29 minutos',
            description:
                'Repita o Treino 1 em ritmo confortável, sem correr em velocidade máxima.',
          ),
          _buildWorkoutCard(
            index: 2,
            title: 'Treino 3',
            duration: '32 minutos',
            description:
                '5 min caminhando, 7 repetições de 1 min trotando e 2 min caminhando, finalizando com 6 min leves.',
          ),
        ],
      ),
    );
  }
}