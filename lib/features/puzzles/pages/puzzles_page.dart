import 'package:flutter/material.dart';

class PuzzlesPage extends StatelessWidget {
  final String levelId;
  const PuzzlesPage({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Puzzles - Level $levelId')),
      body: const Center(child: Text('Puzzles coming soon')),
    );
  }
}