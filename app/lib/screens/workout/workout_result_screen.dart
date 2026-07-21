import 'package:flutter/material.dart';

class WorkoutResultScreen extends StatelessWidget {
  final String workoutTitle;
  final int elapsedSeconds;
  final int plannedSeconds;
  final bool completedManually;

  const WorkoutResultScreen({
    super.key,
    required this.workoutTitle,
    required this.elapsedSeconds,
    required this.plannedSeconds,
    required this.completedManually,
  });

  double get _progress {
    if (plannedSeconds <= 0) {
      return 0;
    }

    final value = elapsedSeconds / plannedSeconds;

    return value.clamp(0.0, 1.0).toDouble();
  }

  String _formatTime(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;

    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final seconds = safeSeconds % 60;

    final minutesText = minutes.toString().padLeft(2, '0');
    final secondsText = seconds.toString().padLeft(2, '0');

    if (hours == 0) {
      return '$minutesText:$secondsText';
    }

    final hoursText = hours.toString().padLeft(2, '0');

    return '$hoursText:$minutesText:$secondsText';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_progress * 100).round();

    return PopScope<void>(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Resultado do treino'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Icon(
                Icons.check_circle,
                size: 88,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Treino concluído!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                workoutTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _ResultRow(
                        label: 'Tempo realizado',
                        value: _formatTime(elapsedSeconds),
                      ),
                      const Divider(height: 28),
                      _ResultRow(
                        label: 'Duração planejada',
                        value: _formatTime(plannedSeconds),
                      ),
                      const Divider(height: 28),
                      _ResultRow(
                        label: 'Tipo de conclusão',
                        value: completedManually
                            ? 'Conclusão manual'
                            : 'Conclusão automática',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Progresso realizado: $percentage%',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Finalizar e salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}
