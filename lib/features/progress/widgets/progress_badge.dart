// lib/features/progress/widgets/progress_badge.dart
import 'package:flutter/material.dart';
import '../../../data/models/progress.dart';

class ProgressBadge extends StatelessWidget {
  final Progress progress;

  const ProgressBadge({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    String text;
    if (progress.completed) {
      text = '✅';
    } else if (progress.started) {
      text = '⏳';
    } else {
      text = '▶️';
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}
