import 'package:flutter/material.dart';

import '../../../../core/utils/app_info.dart';

// Écran temporaire — sera remplacé par l'accueil Maladie / Urgences / Vitamines.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppInfo.name)),
      body: const Center(child: Text('Accueil — à venir')),
    );
  }
}
