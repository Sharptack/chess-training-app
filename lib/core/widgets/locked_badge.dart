import 'package:flutter/material.dart';

class LockedBadge extends StatelessWidget {
  final bool locked;
  const LockedBadge({super.key, required this.locked});

  @override
  Widget build(BuildContext context) {
    if (!locked) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.lock, color: Colors.white),
      ),
    );
  }
}