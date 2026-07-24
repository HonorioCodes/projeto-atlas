import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_settings.dart';

abstract interface class TrainingSettingsStorage {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);
}

class _SharedPreferencesTrainingSettingsStorage
    implements TrainingSettingsStorage {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<String?> getString(String key) {
    return _preferences.getString(key);
  }

  @override
  Future<void> setString(String key, String value) {
    return _preferences.setString(key, value);
  }
}

class TrainingSettingsService {
  static const String _settingsKey = 'training_settings';

  final TrainingSettingsStorage _storage;

  TrainingSettingsService({TrainingSettingsStorage? storage})
    : _storage = storage ?? _SharedPreferencesTrainingSettingsStorage();

  Future<TrainingSettings> loadSettings() async {
    final savedSettings = await _storage.getString(_settingsKey);

    if (savedSettings == null || savedSettings.isEmpty) {
      return TrainingSettings.defaults;
    }

    try {
      final decoded = jsonDecode(savedSettings);

      if (decoded is! Map<String, dynamic>) {
        return TrainingSettings.defaults;
      }

      return TrainingSettings.fromJson(decoded);
    } catch (_) {
      return TrainingSettings.defaults;
    }
  }

  Future<void> saveSettings(TrainingSettings settings) async {
    await _storage.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> resetSettings() async {
    await saveSettings(TrainingSettings.defaults);
  }
}
