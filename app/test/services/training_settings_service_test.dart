import 'dart:convert';

import 'package:app/models/training_settings.dart';
import 'package:app/services/training_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

const String _settingsKey = 'training_settings';

class _MemoryTrainingSettingsStorage implements TrainingSettingsStorage {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getString(String key) async {
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  late _MemoryTrainingSettingsStorage storage;
  late TrainingSettingsService service;

  setUp(() {
    storage = _MemoryTrainingSettingsStorage();
    service = TrainingSettingsService(storage: storage);
  });

  test('retorna os padrões quando não existem dados salvos', () async {
    final settings = await service.loadSettings();

    expect(settings, TrainingSettings.defaults);
  });

  test('salva e carrega todas as configurações', () async {
    const expected = TrainingSettings(
      soundEnabled: false,
      vibrationEnabled: false,
      requireGpsToStart: false,
      keepScreenAwake: true,
      distanceDisplayUnit: DistanceDisplayUnit.kilometers,
    );

    await service.saveSettings(expected);

    expect(await service.loadSettings(), expected);
  });

  test('campos ausentes usam seus valores padrão', () async {
    storage.values[_settingsKey] = jsonEncode({
      'soundEnabled': false,
      'futureField': 'preservado para compatibilidade',
    });

    final settings = await service.loadSettings();

    expect(settings.soundEnabled, isFalse);
    expect(settings.vibrationEnabled, isTrue);
    expect(settings.requireGpsToStart, isTrue);
    expect(settings.keepScreenAwake, isFalse);
    expect(settings.distanceDisplayUnit, DistanceDisplayUnit.automatic);
  });

  test('JSON inválido retorna os padrões', () async {
    storage.values[_settingsKey] = '{json-invalido';

    expect(await service.loadSettings(), TrainingSettings.defaults);
  });

  test('reset restaura e persiste os padrões', () async {
    await service.saveSettings(
      const TrainingSettings(
        soundEnabled: false,
        vibrationEnabled: false,
        requireGpsToStart: false,
        keepScreenAwake: true,
        distanceDisplayUnit: DistanceDisplayUnit.meters,
      ),
    );

    await service.resetSettings();

    expect(await service.loadSettings(), TrainingSettings.defaults);
    expect(storage.values[_settingsKey], isNotNull);
  });

  test('enum desconhecido usa unidade automática', () async {
    storage.values[_settingsKey] = jsonEncode({'distanceDisplayUnit': 'miles'});

    final settings = await service.loadSettings();

    expect(settings.distanceDisplayUnit, DistanceDisplayUnit.automatic);
  });

  test('estrutura JSON desconhecida retorna os padrões', () async {
    storage.values[_settingsKey] = jsonEncode(['invalid']);

    expect(await service.loadSettings(), TrainingSettings.defaults);
  });
}
