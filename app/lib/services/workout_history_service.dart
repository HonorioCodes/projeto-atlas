import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_session_record.dart';

class WorkoutHistoryService {
  static const String _historyKey = 'workout_history';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<WorkoutSessionRecord>> loadRecords() async {
    final savedHistory = await _preferences.getString(_historyKey);

    if (savedHistory == null || savedHistory.isEmpty) {
      return [];
    }

    try {
      final decodedHistory = jsonDecode(savedHistory) as List<dynamic>;

      final records = decodedHistory
          .whereType<Map<String, dynamic>>()
          .map(WorkoutSessionRecord.fromJson)
          .toList();

      records.sort((first, second) {
        return second.completedAt.compareTo(first.completedAt);
      });

      return records;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecord(WorkoutSessionRecord record) async {
    final records = await loadRecords();

    records.insert(0, record);

    const maximumSavedRecords = 200;

    final limitedRecords = records
        .take(maximumSavedRecords)
        .map((item) => item.toJson())
        .toList();

    await _preferences.setString(_historyKey, jsonEncode(limitedRecords));
  }

  Future<void> deleteAllRecords() async {
    await _preferences.remove(_historyKey);
  }
}
