import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

enum LocationAccessStatus {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  granted,
}

class LocationAccessResult {
  final LocationAccessStatus status;
  final LocationPermission? permission;

  const LocationAccessResult({required this.status, this.permission});

  bool get isGranted {
    return status == LocationAccessStatus.granted;
  }
}

class LocationService {
  Future<LocationAccessResult> checkAccess({
    bool requestPermission = false,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const LocationAccessResult(
        status: LocationAccessStatus.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationAccessResult(
        status: LocationAccessStatus.permissionDeniedForever,
        permission: permission,
      );
    }

    if (permission == LocationPermission.denied) {
      return LocationAccessResult(
        status: LocationAccessStatus.permissionDenied,
        permission: permission,
      );
    }

    return LocationAccessResult(
      status: LocationAccessStatus.granted,
      permission: permission,
    );
  }

  Future<void> requestTrackingNotificationPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final currentStatus =
          await permission_handler.Permission.notification.status;

      if (currentStatus.isGranted) {
        return;
      }

      await permission_handler.Permission.notification.request();
    } catch (_) {
      // Uma falha na permissão de notificação
      // não pode impedir o início do treino.
    }
  }

  Future<Position> getCurrentPosition() async {
    final access = await checkAccess();

    if (!access.isGranted) {
      throw StateError('A localização não está disponível.');
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    );

    return Geolocator.getCurrentPosition(locationSettings: settings);
  }

  Stream<Position> getPositionStream() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Treino em andamento',
          notificationText:
              'O Passo a Passo está registrando '
              'sua distância e seu ritmo.',
          notificationChannelName: 'Monitoramento de treino',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );

      return Geolocator.getPositionStream(locationSettings: androidSettings);
    }

    const defaultSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    return Geolocator.getPositionStream(locationSettings: defaultSettings);
  }

  double calculateDistance({required Position start, required Position end}) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}
