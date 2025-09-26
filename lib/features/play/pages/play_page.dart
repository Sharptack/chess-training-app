// lib/features/play/pages/play_page.dart
import 'package:flutter/material.dart';

class PlayPage extends StatelessWidget {
  final String levelId;
  const PlayPage({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Play - Level $levelId')),
      body: const Center(child: Text('Gameplay coming soon')),
    );
  }
}