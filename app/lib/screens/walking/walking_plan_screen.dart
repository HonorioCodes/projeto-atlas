import 'package:flutter/material.dart';

import '../../data/training_plans.dart';
import '../training/training_plan_screen.dart';

class WalkingPlanScreen extends StatelessWidget {
  const WalkingPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TrainingPlanScreen(
      planId: 'walking',
      title: 'Caminhada para Iniciantes',
      weeks: walkingTrainingWeeks,
    );
  }
}