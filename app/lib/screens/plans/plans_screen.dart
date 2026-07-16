import '../../services/plan_storage_service.dart';
import '../walking/walking_plan_screen.dart';
import '../couch_to_5k/couch_to_5k_screen.dart';
import 'package:flutter/material.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha seu plano'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
  await PlanStorageService().saveSelectedPlan('walking');

  if (!context.mounted) {
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) => const WalkingPlanScreen(),
    ),
    (route) => false,
  );
},
              child: const Text('Caminhada para Iniciantes'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
  await PlanStorageService().saveSelectedPlan('couch_to_5k');

  if (!context.mounted) {
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) => const CouchTo5KScreen(),
    ),
    (route) => false,
  );
},
              child: const Text('Da Caminhada à Corrida 5 km'),
            ),
          ],
        ),
      ),
    );
  }
}