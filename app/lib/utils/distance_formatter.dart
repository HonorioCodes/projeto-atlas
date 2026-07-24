import '../models/training_settings.dart';

String formatDistanceForDisplay(
  double distanceMeters,
  DistanceDisplayUnit unit,
) {
  final safeDistance = distanceMeters.isFinite && distanceMeters > 0
      ? distanceMeters
      : 0.0;

  switch (unit) {
    case DistanceDisplayUnit.automatic:
      if (safeDistance < 1000) {
        return '${safeDistance.round()} m';
      }

      return _formatKilometers(safeDistance);

    case DistanceDisplayUnit.kilometers:
      return _formatKilometers(safeDistance);

    case DistanceDisplayUnit.meters:
      return '${safeDistance.round()} m';
  }
}

String _formatKilometers(double distanceMeters) {
  final kilometers = distanceMeters / 1000;
  final formattedValue = kilometers.toStringAsFixed(2).replaceAll('.', ',');

  return '$formattedValue km';
}
