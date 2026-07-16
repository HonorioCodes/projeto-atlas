import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WorkoutProgressService {
  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  String _getKey(String planId) {
    return 'workout_progress_$planId';
  }

  Future<void> saveProgress(
    String planId,
    List<bool> progress,
  ) async {
    await _preferences.setString(
      _getKey(planId),
      jsonEncode(progress),
    );
  }

  Future<List<bool>> loadProgress(
    String planId,
    int workoutCount,
  ) async {
    final savedProgress = await _preferences.getString(
      _getKey(planId),
    );

    if (savedProgress == null) {
      return List<bool>.filled(workoutCount, false);
    }

    try {
      final decodedProgress =
          jsonDecode(savedProgress) as List<dynamic>;

      return List<bool>.generate(
        workoutCount,
        (index) {
          if (index >= decodedProgress.length) {
            return false;
          }

          return decodedProgress[index] == true;
        },
      );
    } catch (_) {
      return List<bool>.filled(workoutCount, false);
    }
  }

  Future<void> deleteProgress(String planId) async {
    await _preferences.remove(_getKey(planId));
  }
}