import 'package:flutter/material.dart';

class LockedBadge extends StatelessWidget {
  final bool locked;
  final String? message;
  final List<RequirementItem>? requirements;

  const LockedBadge({
    super.key,
    required this.locked,
    this.message,
    this.requirements,
  });

  @override
  Widget build(BuildContext context) {
    if (!locked) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, color: Colors.white, size: 48),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (requirements != null && requirements!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...requirements!.map((req) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        req.completed ? Icons.check_circle : Icons.circle_outlined,
                        color: req.completed ? Colors.green : Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${req.label}: ${req.status}',
                          style: TextStyle(
                            color: req.completed ? Colors.green : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class RequirementItem {
  final String label;
  final String status;
  final bool completed;

  RequirementItem({
    required this.label,
    required this.status,
    required this.completed,
  });
}