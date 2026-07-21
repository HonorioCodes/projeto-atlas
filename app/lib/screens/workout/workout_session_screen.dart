import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/workout_model.dart';
import '../../models/workout_step_model.dart';
import '../../services/workout_feedback_service.dart';
import 'workout_result_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutSessionScreen({super.key, required this.workout});

  @override
  State<WorkoutSessionScreen> createState() {
    return _WorkoutSessionScreenState();
  }
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  Timer? _timer;

  late final List<WorkoutStepModel> _steps;
  late final int _totalSeconds;

  int _currentStepIndex = 0;
  int _elapsedSeconds = 0;

  late int _remainingStepSeconds;

  bool _isRunning = false;
  bool _hasStarted = false;
  bool _completionFeedbackEmitted = false;
  bool _resultScreenOpen = false;
  bool _allowExit = false;

  final WorkoutFeedbackService _feedbackService = WorkoutFeedbackService();

  WorkoutStepModel get _currentStep {
    return _steps[_currentStepIndex];
  }

  bool get _hasActiveWorkout {
    return _hasStarted && _elapsedSeconds < _totalSeconds;
  }

  @override
  void initState() {
    super.initState();

    _steps = widget.workout.steps.isEmpty
        ? [
            WorkoutStepModel(
              title: 'Treino',
              instruction: widget.workout.description,
              durationSeconds: _readFallbackDuration(),
            ),
          ]
        : widget.workout.steps;

    _totalSeconds = _steps.fold<int>(0, (total, step) {
      return total + step.durationSeconds;
    });

    _remainingStepSeconds = _currentStep.durationSeconds;

    unawaited(_feedbackService.initialize());
  }

  int _readFallbackDuration() {
    final durationMatch = RegExp(r'\d+').firstMatch(widget.workout.duration);

    final minutes = int.tryParse(durationMatch?.group(0) ?? '') ?? 1;

    return minutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();

    unawaited(_feedbackService.dispose());

    super.dispose();
  }

  double get _overallProgress {
    if (_totalSeconds == 0) {
      return 0;
    }

    return _elapsedSeconds / _totalSeconds;
  }

  double get _stepProgress {
    if (_currentStep.durationSeconds == 0) {
      return 0;
    }

    return (_currentStep.durationSeconds - _remainingStepSeconds) /
        _currentStep.durationSeconds;
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final minutesText = minutes.toString().padLeft(2, '0');
    final secondsText = seconds.toString().padLeft(2, '0');

    if (hours == 0) {
      return '$minutesText:$secondsText';
    }

    final hoursText = hours.toString().padLeft(2, '0');

    return '$hoursText:$minutesText:$secondsText';
  }

  String get _statusText {
    if (_elapsedSeconds >= _totalSeconds) {
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

    _timer = Timer.periodic(const Duration(seconds: 1), _handleTimerTick);
  }

  void _handleTimerTick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    if (_remainingStepSeconds > 1) {
      setState(() {
        _remainingStepSeconds--;
        _elapsedSeconds++;
      });

      return;
    }

    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _elapsedSeconds++;
        _currentStepIndex++;
        _remainingStepSeconds = _currentStep.durationSeconds;
      });

      unawaited(_feedbackService.onStepChanged());

      return;
    }

    timer.cancel();

    setState(() {
      _elapsedSeconds = _totalSeconds;
      _remainingStepSeconds = 0;
      _isRunning = false;
    });

    unawaited(_completeWorkoutAutomatically());
  }

  Future<void> _completeWorkoutAutomatically() async {
    await _emitWorkoutCompletedFeedback();

    if (!mounted) {
      return;
    }

    await _openResultScreen(completedManually: false);
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
      _currentStepIndex = 0;
      _elapsedSeconds = 0;
      _remainingStepSeconds = _steps.first.durationSeconds;
      _isRunning = false;
      _hasStarted = false;
      _completionFeedbackEmitted = false;
      _allowExit = false;
    });

    _feedbackService.resetCompletionFeedback();
  }

  Future<void> _emitWorkoutCompletedFeedback() async {
    if (_completionFeedbackEmitted) {
      return;
    }

    _completionFeedbackEmitted = true;

    await _feedbackService.onWorkoutCompleted();
  }

  void _exitScreen({required bool completed}) {
    _timer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRunning = false;
      _allowExit = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(completed);
    });
  }

  Future<void> _requestExit() async {
    if (!_hasActiveWorkout) {
      _exitScreen(completed: false);
      return;
    }

    final wasRunning = _isRunning;

    _timer?.cancel();

    if (_isRunning) {
      setState(() {
        _isRunning = false;
      });
    }

    await _feedbackService.onWarningOrConfirmation();

    if (!mounted) {
      return;
    }

    final shouldAbandon = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair do treino?'),
          content: const Text(
            'Seu progresso nesta execução será perdido. '
            'O treino não será marcado como concluído.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Continuar treino'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Abandonar treino'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (shouldAbandon == true) {
      _exitScreen(completed: false);
      return;
    }

    if (wasRunning) {
      _startOrResumeWorkout();
    }
  }

  Future<void> _openResultScreen({required bool completedManually}) async {
    if (_resultScreenOpen || !mounted) {
      return;
    }

    _resultScreenOpen = true;

    final shouldSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) {
          return WorkoutResultScreen(
            workoutTitle: widget.workout.title,
            elapsedSeconds: _elapsedSeconds,
            plannedSeconds: _totalSeconds,
            completedManually: completedManually,
          );
        },
      ),
    );

    _resultScreenOpen = false;

    if (!mounted) {
      return;
    }

    if (shouldSave == true) {
      _exitScreen(completed: true);
    }
  }

  Future<void> _finishWorkoutManually() async {
    final wasRunning = _isRunning;

    _timer?.cancel();

    if (_isRunning) {
      setState(() {
        _isRunning = false;
      });
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Concluir treino?'),
          content: const Text(
            'O treino será marcado como concluído '
            'mesmo que ainda existam etapas pendentes.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Concluir'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (confirmed == true) {
      await _emitWorkoutCompletedFeedback();

      if (!mounted) {
        return;
      }

      await _openResultScreen(completedManually: true);

      return;
    }

    if (wasRunning) {
      _startOrResumeWorkout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingTotalSeconds = _totalSeconds - _elapsedSeconds;

    return PopScope<bool>(
      canPop: _allowExit || !_hasActiveWorkout,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        await _requestExit();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.workout.title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Etapa ${_currentStepIndex + 1} '
                      'de ${_steps.length}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStep.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(_currentStep.instruction, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                        value: _stepProgress,
                        strokeWidth: 12,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Tempo da etapa'),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(_remainingStepSeconds),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Tempo restante do treino: '
              '${_formatTime(remainingTotalSeconds)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _overallProgress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning
                        ? _pauseWorkout
                        : _startOrResumeWorkout,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
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
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reiniciar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _finishWorkoutManually,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Concluir treino'),
            ),
          ],
        ),
      ),
    );
  }
}
