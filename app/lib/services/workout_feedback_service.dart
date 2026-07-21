import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class WorkoutFeedbackService {
  static const String _stepChangeAsset = 'assets/audio/step_change.wav';
  static const String _workoutCompleteAsset =
      'assets/audio/workout_complete.wav';

  final SoLoud _soloud = SoLoud.instance;

  Future<void>? _initFuture;
  AudioSource? _stepChangeSource;
  AudioSource? _workoutCompleteSource;
  SoundHandle? _stepChangeHandle;
  SoundHandle? _workoutCompleteHandle;
  bool _workoutCompleteSoundPlayed = false;
  bool _isDisposed = false;

  Future<void> initialize() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  Future<void> onStepChanged() async {
    await _runSafely(() => HapticFeedback.mediumImpact());
    await _runSafely(_playStepChangeSound);
  }

  Future<void> onWorkoutCompleted() async {
    await _runSafely(() => HapticFeedback.successNotification());
    await _runSafely(_playWorkoutCompleteSound);
  }

  Future<void> onWarningOrConfirmation() async {
    await _runSafely(() => HapticFeedback.lightImpact());
  }

  void resetCompletionFeedback() {
    _workoutCompleteSoundPlayed = false;
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    await _runSafely(() async {
      await _stopHandle(_stepChangeHandle);
      await _stopHandle(_workoutCompleteHandle);

      if (_stepChangeSource != null) {
        await _soloud.disposeSource(_stepChangeSource!);
        _stepChangeSource = null;
      }

      if (_workoutCompleteSource != null) {
        await _soloud.disposeSource(_workoutCompleteSource!);
        _workoutCompleteSource = null;
      }

      if (_soloud.isInitialized) {
        _soloud.deinit();
      }

      _initFuture = null;
    });
  }

  Future<void> _initialize() async {
    if (_isDisposed) {
      return;
    }

    try {
      if (!_soloud.isInitialized) {
        await _soloud.init();
      }

      _stepChangeSource ??= await _soloud.loadAsset(_stepChangeAsset);
      _workoutCompleteSource ??= await _soloud.loadAsset(_workoutCompleteAsset);
    } catch (_) {
      // Falhas de áudio não devem interromper o treino.
    }
  }

  Future<void> _playStepChangeSound() async {
    await initialize();

    if (_isDisposed || !_soloud.isInitialized) {
      return;
    }

    final source = _stepChangeSource;
    if (source == null) {
      return;
    }

    try {
      await _stopHandle(_stepChangeHandle);
      _stepChangeHandle = _soloud.play(source, volume: 0.75);
    } catch (_) {
      // Falhas de áudio não devem interromper o treino.
    }
  }

  Future<void> _playWorkoutCompleteSound() async {
    if (_workoutCompleteSoundPlayed) {
      return;
    }

    await initialize();

    if (_isDisposed || !_soloud.isInitialized) {
      return;
    }

    final source = _workoutCompleteSource;
    if (source == null) {
      return;
    }

    try {
      _workoutCompleteSoundPlayed = true;
      await _stopHandle(_workoutCompleteHandle);
      _workoutCompleteHandle = _soloud.play(source, volume: 0.80);
    } catch (_) {
      _workoutCompleteSoundPlayed = false;
    }
  }

  Future<void> _stopHandle(SoundHandle? handle) async {
    if (handle == null || !_soloud.isInitialized) {
      return;
    }

    if (!_soloud.getIsValidVoiceHandle(handle)) {
      return;
    }

    try {
      await _soloud.stop(handle);
    } catch (_) {
      // Ignora falhas ao parar handles antigos.
    }
  }

  Future<void> _runSafely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Falhas de vibração ou som não devem interromper o treino.
    }
  }
}
