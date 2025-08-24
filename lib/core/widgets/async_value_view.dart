import 'package:flutter/material.dart';

/// Minimal loading/error/empty wrapper for now (no async lib dependency yet).
class AsyncValueView extends StatelessWidget {
  final bool isLoading;
  final Object? error;
  final Widget Function() builder;
  final String emptyMessage;

  const AsyncValueView({
    super.key,
    required this.isLoading,
    required this.builder,
    this.error,
    this.emptyMessage = 'Nothing here yet',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Error: $error'),
        ),
      );
    }
    final child = builder();
    return child;
  }
}