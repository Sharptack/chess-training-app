import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AsyncValue<T> wrapper: shows loading/error and builds on data.
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) data;

  const AsyncValueView({
    super.key,
    required this.asyncValue,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}