import 'package:geolocator/geolocator.dart';

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

  Future<Position> getCurrentPosition() async {
    final access = await checkAccess();

    if (!access.isGranted) {
      throw StateError('A localização não está disponível.');
    }

    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );

    return Geolocator.getCurrentPosition(locationSettings: settings);
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}
