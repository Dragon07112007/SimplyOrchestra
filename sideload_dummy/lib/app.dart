import 'package:flutter/material.dart';

import 'screens/training_screen.dart';
import 'theme/app_theme.dart';

class TaktstockTrainerApp extends StatelessWidget {
  const TaktstockTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taktstock Trainer',
      theme: AppTheme.dark(),
      home: const TrainingScreen(),
    );
  }
}
