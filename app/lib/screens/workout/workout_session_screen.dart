import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/workout_model.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutSessionScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutSessionScreen> createState() {
    return _WorkoutSessionScreenState();
  }
}

class _WorkoutSessionScreenState
    extends State<WorkoutSessionScreen> {
  Timer? _timer;

  late final int _totalSeconds;
  late int _remainingSeconds;

  bool _isRunning = false;
  bool _hasStarted = false;
  bool _completionDialogOpen = false;

  @override
  void initState() {
    super.initState();

    final durationMatch = RegExp(
      r'\d+',
    ).firstMatch(widget.workout.duration);

    final durationMinutes = int.tryParse(
          durationMatch?.group(0) ?? '',
        ) ??
        1;

    _totalSeconds = durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress {
    if (_totalSeconds == 0) {
      return 0;
    }

    return (_totalSeconds - _remainingSeconds) /
        _totalSeconds;
  }

  String get _formattedTime {
    final hours = _remainingSeconds ~/ 3600;

    final minutes =
        (_remainingSeconds % 3600) ~/ 60;

    final seconds = _remainingSeconds % 60;

    final hoursText =
        hours.toString().padLeft(2, '0');

    final minutesText =
        minutes.toString().padLeft(2, '0');

    final secondsText =
        seconds.toString().padLeft(2, '0');

    return '$hoursText:$minutesText:$secondsText';
  }

  String get _statusText {
    if (_remainingSeconds == 0) {
      return 'Treino concluído';
    }

    if (_isRunning) {
      return 'Treino em andamento';
    }

    if (_hasStarted) {
      return 'Treino pausado';
    }

    return 'Pronto para começar';
  }

  void _startOrResumeWorkout() {
    if (_isRunning) {
      return;
    }

    setState(() {
      _isRunning = true;
      _hasStarted = true;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingSeconds <= 1) {
          timer.cancel();

          setState(() {
            _remainingSeconds = 0;
            _isRunning = false;
          });

          _showCompletionDialog();
          return;
        }

        setState(() {
          _remainingSeconds--;
        });
      },
    );
  }

  void _pauseWorkout() {
    _timer?.cancel();

    setState(() {
      _isRunning = false;
    });
  }

  void _resetWorkout() {
    _timer?.cancel();

    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
      _hasStarted = false;
    });
  }

  Future<void> _showCompletionDialog() async {
    if (_completionDialogOpen || !mounted) {
      return;
    }

    _completionDialogOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Treino concluído',
          ),
          content: const Text(
            'Parabéns! Você completou o treino.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Finalizar',
              ),
            ),
          ],
        );
      },
    );

    _completionDialogOpen = false;
  }

  Future<void> _finishWorkoutManually() async {
    _timer?.cancel();

    if (_isRunning) {
      setState(() {
        _isRunning = false;
      });
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Concluir treino?',
          ),
          content: const Text(
            'O treino será marcado como concluído.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Concluir',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (confirmed == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workout.title,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.workout.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 230,
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 230,
                    height: 230,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 12,
                    ),
                  ),
                  Text(
                    _formattedTime,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRunning
                      ? _pauseWorkout
                      : _startOrResumeWorkout,
                  icon: Icon(
                    _isRunning
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    _isRunning
                        ? 'Pausar'
                        : _hasStarted
                            ? 'Continuar'
                            : 'Iniciar',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetWorkout,
                  icon: const Icon(
                    Icons.restart_alt,
                  ),
                  label: const Text(
                    'Reiniciar',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _finishWorkoutManually,
            icon: const Icon(
              Icons.check_circle_outline,
            ),
            label: const Text(
              'Concluir treino',
            ),
          ),
        ],
      ),
    );
  }
}