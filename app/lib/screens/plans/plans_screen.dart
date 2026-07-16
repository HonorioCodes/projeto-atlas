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
              onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const WalkingPlanScreen(),
    ),
  );
},
              child: const Text('Caminhada Inteligente'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CouchTo5KScreen(),
    ),
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