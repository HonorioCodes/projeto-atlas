import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class UserStorageService {
  static const String _userKey = 'registered_user';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toMap());

    await _preferences.setString(_userKey, userJson);
  }

  Future<UserModel?> loadUser() async {
    final userJson = await _preferences.getString(_userKey);

    if (userJson == null || userJson.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(userJson);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return UserModel.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteUser() async {
    await _preferences.remove(_userKey);
  }
}
