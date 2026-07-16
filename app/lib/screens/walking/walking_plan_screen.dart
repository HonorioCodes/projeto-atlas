import 'package:flutter/material.dart';

class WalkingPlanScreen extends StatelessWidget {
  const WalkingPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caminhada Inteligente'),
      ),
      body: const Center(
        child: Text(
          'Em desenvolvimento',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}