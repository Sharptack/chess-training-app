import 'package:flutter/material.dart';

class LessonPage extends StatelessWidget {
  final String levelId;
  const LessonPage({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lesson - Level $levelId')),
      body: const Center(child: Text('Lesson content coming soon')),
    );
  }
}