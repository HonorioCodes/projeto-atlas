import 'package:shared_preferences/shared_preferences.dart';

class PlanStorageService {
  static const String _selectedPlanKey = 'selected_plan';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<void> saveSelectedPlan(String plan) async {
    await _preferences.setString(
      _selectedPlanKey,
      plan,
    );
  }

  Future<String?> loadSelectedPlan() async {
    return _preferences.getString(_selectedPlanKey);
  }

  Future<void> deleteSelectedPlan() async {
    await _preferences.remove(_selectedPlanKey);
  }
}