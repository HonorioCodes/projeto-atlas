import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_storage_service.dart';
import '../home/home_screen.dart';
import '../plans/plans_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  late final Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = UserStorageService().loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const HomeScreen();
        }

        final user = snapshot.data;

        if (user == null) {
          return const HomeScreen();
        }

        return const PlansScreen();
      },
    );
  }
}