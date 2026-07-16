import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';

class PassoAPassoApp extends StatelessWidget {
  const PassoAPassoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Passo a Passo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}