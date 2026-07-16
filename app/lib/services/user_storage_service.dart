import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class UserStorageService {
  static const String _userKey = 'registered_user';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toMap());

    await _preferences.setString(
      _userKey,
      userJson,
    );
  }

  Future<UserModel?> loadUser() async {
    final userJson = await _preferences.getString(_userKey);

    if (userJson == null) {
      return null;
    }

    final userMap =
        jsonDecode(userJson) as Map<String, dynamic>;

    return UserModel.fromMap(userMap);
  }

  Future<void> deleteUser() async {
    await _preferences.remove(_userKey);
  }
}