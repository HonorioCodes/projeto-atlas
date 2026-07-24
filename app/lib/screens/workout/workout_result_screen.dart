import 'package:flutter/material.dart';

import '../../models/training_settings.dart';
import '../../models/workout_session_record.dart';
import '../../services/workout_history_service.dart';
import '../../utils/distance_formatter.dart';

class WorkoutResultScreen extends StatefulWidget {
  final String workoutTitle;
  final int elapsedSeconds;
  final int plannedSeconds;
  final bool completedManually;
  final double distanceMeters;
  final int validGpsPointCount;
  final DistanceDisplayUnit distanceDisplayUnit;

  const WorkoutResultScreen({
    super.key,
    required this.workoutTitle,
    required this.elapsedSeconds,
    required this.plannedSeconds,
    required this.completedManually,
    required this.distanceMeters,
    required this.validGpsPointCount,
    this.distanceDisplayUnit = DistanceDisplayUnit.automatic,
  });

  @override
  State<WorkoutResultScreen> createState() {
    return _WorkoutResultScreenState();
  }
}

class _WorkoutResultScreenState extends State<WorkoutResultScreen> {
  final WorkoutHistoryService _historyService = WorkoutHistoryService();

  bool _isSaving = false;
  String? _saveError;

  double get _progress {
    if (widget.plannedSeconds <= 0) {
      return 0;
    }

    final value = widget.elapsedSeconds / widget.plannedSeconds;

    return value.clamp(0.0, 1.0).toDouble();
  }

  double? get _averageSpeedKmPerHour {
    if (widget.elapsedSeconds <= 0 || widget.distanceMeters <= 0) {
      return null;
    }

    final distanceKilometers = widget.distanceMeters / 1000;

    final elapsedHours = widget.elapsedSeconds / 3600;

    return distanceKilometers / elapsedHours;
  }

  int? get _averagePaceSecondsPerKm {
    if (widget.elapsedSeconds <= 0 || widget.distanceMeters <= 0) {
      return null;
    }

    final distanceKilometers = widget.distanceMeters / 1000;

    return (widget.elapsedSeconds / distanceKilometers).round();
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

  String _formatPace(int? secondsPerKilometer) {
    if (secondsPerKilometer == null) {
      return '--';
    }

    final minutes = secondsPerKilometer ~/ 60;

    final seconds = secondsPerKilometer % 60;

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')} min/km';
  }

  String _formatSpeed(double? kilometersPerHour) {
    if (kilometersPerHour == null) {
      return '--';
    }

    return '${kilometersPerHour.toStringAsFixed(2)} km/h';
  }

  Future<void> _saveAndFinish() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final completedAt = DateTime.now();

    final record = WorkoutSessionRecord(
      id: completedAt.microsecondsSinceEpoch.toString(),
      workoutTitle: widget.workoutTitle,
      completedAt: completedAt,
      elapsedSeconds: widget.elapsedSeconds,
      plannedSeconds: widget.plannedSeconds,
      completedManually: widget.completedManually,
      distanceMeters: widget.distanceMeters,
      validGpsPointCount: widget.validGpsPointCount,
    );

    try {
      await _historyService.saveRecord(record);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _saveError =
            'Não foi possível salvar o treino. '
            'Tente novamente.';
      });
    }
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
                widget.workoutTitle,
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
                        value: _formatTime(widget.elapsedSeconds),
                      ),
                      const Divider(height: 28),
                      _ResultRow(
                        label: 'Duração planejada',
                        value: _formatTime(widget.plannedSeconds),
                      ),
                      const Divider(height: 28),
                      _ResultRow(
                        label: 'Distância',
                        value: formatDistanceForDisplay(
                          widget.distanceMeters,
                          widget.distanceDisplayUnit,
                        ),
                      ),
                      const Divider(height: 28),
                      _ResultRow(
                        label: 'Ritmo médio',
                        value: _formatPace(_averagePaceSecondsPerKm),
                      ),
                      const Divider(height: 28),
                      _ResultRow(
                        label: 'Velocidade média',
                        value: _formatSpeed(_averageSpeedKmPerHour),
                      ),
                      const Divider(height: 28),
                      _ResultRow(
                        label: 'Pontos válidos de GPS',
                        value: widget.validGpsPointCount.toString(),
                      ),
                      const Divider(height: 28),
                      _ResultRow(
                        label: 'Tipo de conclusão',
                        value: widget.completedManually
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
              if (_saveError != null) ...[
                const SizedBox(height: 20),
                Text(
                  _saveError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAndFinish,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Salvando...' : 'Finalizar e salvar'),
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
