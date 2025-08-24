import 'package:flutter/material.dart';

class BossPage extends StatelessWidget {
  final String levelId;
  const BossPage({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Boss - Level $levelId')),
      body: const Center(child: Text('Boss battle coming soon')),
    );
  }
}
