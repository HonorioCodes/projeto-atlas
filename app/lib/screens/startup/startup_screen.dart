import 'package:flutter/material.dart';

import '../../services/plan_storage_service.dart';
import '../../services/user_storage_service.dart';
import '../couch_to_5k/couch_to_5k_screen.dart';
import '../home/home_screen.dart';
import '../plans/plans_screen.dart';
import '../walking/walking_plan_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  late final Future<Widget> _initialScreenFuture;

  @override
  void initState() {
    super.initState();
    _initialScreenFuture = _loadInitialScreen();
  }

  Future<Widget> _loadInitialScreen() async {
    final user = await UserStorageService().loadUser();

    if (user == null) {
      return const HomeScreen();
    }

    final selectedPlan =
        await PlanStorageService().loadSelectedPlan();

    if (selectedPlan == 'walking') {
      return const WalkingPlanScreen();
    }

    if (selectedPlan == 'couch_to_5k') {
      return const CouchTo5KScreen();
    }

    return const PlansScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const HomeScreen();
        }

        return snapshot.data!;
      },
    );
  }
}