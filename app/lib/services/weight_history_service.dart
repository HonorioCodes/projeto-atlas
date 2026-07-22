import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/weight_record.dart';

class WeightHistoryService {
  static const String _historyKey = 'weight_history';

  static const int _maximumRecords = 500;

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<WeightRecord>> loadRecords() async {
    final savedHistory = await _preferences.getString(_historyKey);

    if (savedHistory == null || savedHistory.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(savedHistory);

      if (decoded is! List<dynamic>) {
        return [];
      }

      final records = decoded
          .whereType<Map<String, dynamic>>()
          .map(WeightRecord.fromJson)
          .where((record) {
            return record.weightKg > 0;
          })
          .toList();

      records.sort((first, second) {
        return second.recordedAt.compareTo(first.recordedAt);
      });

      return records;
    } catch (_) {
      return [];
    }
  }

  Future<void> ensureInitialRecord(double initialWeight) async {
    final records = await loadRecords();

    if (records.isNotEmpty || initialWeight <= 0) {
      return;
    }

    final recordedAt = DateTime.now();

    final initialRecord = WeightRecord(
      id:
          'initial-'
          '${recordedAt.microsecondsSinceEpoch}',
      weightKg: initialWeight,
      recordedAt: recordedAt,
    );

    await _saveAll([initialRecord]);
  }

  Future<void> saveRecord(WeightRecord record) async {
    final records = await loadRecords();

    records.insert(0, record);

    final limitedRecords = records.take(_maximumRecords).toList();

    await _saveAll(limitedRecords);
  }

  Future<void> _saveAll(List<WeightRecord> records) async {
    final encodedRecords = records.map((record) => record.toJson()).toList();

    await _preferences.setString(_historyKey, jsonEncode(encodedRecords));
  }

  Future<void> deleteAllRecords() async {
    await _preferences.remove(_historyKey);
  }
}
