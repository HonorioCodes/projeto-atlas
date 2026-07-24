import 'package:app/models/training_settings.dart';
import 'package:app/utils/distance_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('automático mostra metros abaixo de um quilômetro', () {
    expect(
      formatDistanceForDisplay(350, DistanceDisplayUnit.automatic),
      '350 m',
    );
  });

  test('automático mostra quilômetros a partir de um quilômetro', () {
    expect(
      formatDistanceForDisplay(2480, DistanceDisplayUnit.automatic),
      '2,48 km',
    );
  });

  test('quilômetros sempre mostra quilômetros', () {
    expect(
      formatDistanceForDisplay(350, DistanceDisplayUnit.kilometers),
      '0,35 km',
    );
    expect(
      formatDistanceForDisplay(2480, DistanceDisplayUnit.kilometers),
      '2,48 km',
    );
  });

  test('metros sempre mostra metros arredondados', () {
    expect(
      formatDistanceForDisplay(349.6, DistanceDisplayUnit.meters),
      '350 m',
    );
    expect(
      formatDistanceForDisplay(2480, DistanceDisplayUnit.meters),
      '2480 m',
    );
  });

  test('valor zero é formatado com segurança', () {
    expect(formatDistanceForDisplay(0, DistanceDisplayUnit.automatic), '0 m');
    expect(
      formatDistanceForDisplay(0, DistanceDisplayUnit.kilometers),
      '0,00 km',
    );
  });

  test('valor negativo é tratado como zero', () {
    expect(formatDistanceForDisplay(-50, DistanceDisplayUnit.meters), '0 m');
  });

  test('valor não finito é tratado como zero', () {
    expect(
      formatDistanceForDisplay(double.nan, DistanceDisplayUnit.automatic),
      '0 m',
    );
    expect(
      formatDistanceForDisplay(double.infinity, DistanceDisplayUnit.kilometers),
      '0,00 km',
    );
  });
}
