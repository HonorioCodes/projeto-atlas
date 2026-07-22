import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

enum WorkoutGpsStatus {
  idle,
  searching,
  tracking,
  poorSignal,
  paused,
  unavailable,
  error,
}

class WorkoutLocationSnapshot {
  final WorkoutGpsStatus status;
  final double distanceMeters;
  final double? accuracyMeters;
  final int validPointCount;

  const WorkoutLocationSnapshot({
    required this.status,
    required this.distanceMeters,
    required this.accuracyMeters,
    required this.validPointCount,
  });

  static const WorkoutLocationSnapshot initial = WorkoutLocationSnapshot(
    status: WorkoutGpsStatus.idle,
    distanceMeters: 0,
    accuracyMeters: null,
    validPointCount: 0,
  );
}

class WorkoutLocationTracker {
  static const double _maximumAccuracyMeters = 35;
  static const double _minimumSegmentMeters = 1;
  static const double _maximumSegmentMeters = 100;

  static const double _maximumSpeedMetersPerSecond = 12;

  final LocationService _locationService;

  StreamSubscription<Position>? _positionSubscription;

  Position? _lastAcceptedPosition;

  void Function(WorkoutLocationSnapshot snapshot)? _onUpdate;

  double _distanceMeters = 0;
  double? _accuracyMeters;
  int _validPointCount = 0;

  WorkoutLocationTracker({LocationService? locationService})
    : _locationService = locationService ?? LocationService();

  Future<LocationAccessResult> start({
    required void Function(WorkoutLocationSnapshot snapshot) onUpdate,
  }) async {
    _onUpdate = onUpdate;

    await _cancelSubscription();

    _lastAcceptedPosition = null;

    final access = await _locationService.checkAccess(requestPermission: true);

    if (!access.isGranted) {
      _emit(WorkoutGpsStatus.unavailable);
      return access;
    }

    await _locationService.requestTrackingNotificationPermission();

    _emit(WorkoutGpsStatus.searching);

    try {
      _positionSubscription = _locationService.getPositionStream().listen(
        _handlePosition,
        onError: (Object error) {
          _emit(WorkoutGpsStatus.error);
        },
        onDone: () {
          _positionSubscription = null;
        },
        cancelOnError: false,
      );
    } catch (_) {
      _emit(WorkoutGpsStatus.error);
      rethrow;
    }

    return access;
  }

  void _handlePosition(Position position) {
    _accuracyMeters = position.accuracy;

    if (!position.accuracy.isFinite ||
        position.accuracy > _maximumAccuracyMeters) {
      _emit(WorkoutGpsStatus.poorSignal);
      return;
    }

    _validPointCount++;

    final previousPosition = _lastAcceptedPosition;

    if (previousPosition != null) {
      final segmentDistance = _locationService.calculateDistance(
        start: previousPosition,
        end: position,
      );

      final elapsedMilliseconds = position.timestamp
          .difference(previousPosition.timestamp)
          .inMilliseconds
          .abs();

      final elapsedSeconds = elapsedMilliseconds / 1000.0;

      final calculatedSpeed = elapsedSeconds > 0
          ? segmentDistance / elapsedSeconds
          : 0.0;

      final segmentIsValid =
          segmentDistance >= _minimumSegmentMeters &&
          segmentDistance <= _maximumSegmentMeters &&
          (elapsedSeconds <= 0 ||
              calculatedSpeed <= _maximumSpeedMetersPerSecond);

      if (segmentIsValid) {
        _distanceMeters += segmentDistance;
      }
    }

    _lastAcceptedPosition = position;

    _emit(WorkoutGpsStatus.tracking);
  }

  Future<void> pause() async {
    await _cancelSubscription();

    _lastAcceptedPosition = null;

    _emit(WorkoutGpsStatus.paused);
  }

  Future<void> stop() async {
    await _cancelSubscription();

    _lastAcceptedPosition = null;
  }

  Future<void> reset() async {
    await _cancelSubscription();

    _lastAcceptedPosition = null;
    _distanceMeters = 0;
    _accuracyMeters = null;
    _validPointCount = 0;

    _emit(WorkoutGpsStatus.idle);
  }

  Future<void> dispose() async {
    await _cancelSubscription();

    _lastAcceptedPosition = null;
    _onUpdate = null;
  }

  Future<bool> openAppSettings() {
    return _locationService.openAppSettings();
  }

  Future<bool> openLocationSettings() {
    return _locationService.openLocationSettings();
  }

  Future<void> _cancelSubscription() async {
    await _positionSubscription?.cancel();

    _positionSubscription = null;
  }

  void _emit(WorkoutGpsStatus status) {
    _onUpdate?.call(
      WorkoutLocationSnapshot(
        status: status,
        distanceMeters: _distanceMeters,
        accuracyMeters: _accuracyMeters,
        validPointCount: _validPointCount,
      ),
    );
  }
}
