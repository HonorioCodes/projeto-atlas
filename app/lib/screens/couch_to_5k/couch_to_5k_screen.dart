import 'package:flutter/material.dart';

import '../../data/training_plans.dart';
import '../training/training_plan_screen.dart';

class CouchTo5KScreen extends StatelessWidget {
  const CouchTo5KScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TrainingPlanScreen(
      planId: 'couch_to_5k',
      title: 'Da Caminhada à Corrida 5 km',
      weeks: couchTo5KTrainingWeeks,
    );
  }
}