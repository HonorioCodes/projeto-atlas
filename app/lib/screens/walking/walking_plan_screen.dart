import 'package:flutter/material.dart';

import '../../services/plan_storage_service.dart';
import '../plans/plans_screen.dart';

class WalkingPlanScreen extends StatelessWidget {
  const WalkingPlanScreen({super.key});

  Future<void> _changePlan(BuildContext context) async {
    await PlanStorageService().deleteSelectedPlan();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const PlansScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caminhada Inteligente'),
        actions: [
          IconButton(
            onPressed: () => _changePlan(context),
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Trocar plano',
          ),
        ],
      ),
      body: const Center(
        child: Text('Em desenvolvimento'),
      ),
    );
  }
}