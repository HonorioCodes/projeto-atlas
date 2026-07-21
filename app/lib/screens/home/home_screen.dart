import 'package:flutter/material.dart';
import '../onboarding/welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_walk,
                size: 96,
              ),
              const SizedBox(height: 24),
              const Text(
                'Passo a Passo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Um passo hoje.\nUma vida mais saudável amanhã.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const WelcomeScreen(),
  ),
);
},
                  child: const Text('Começar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}