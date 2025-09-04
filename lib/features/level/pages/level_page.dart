// lib/features/level/pages/level_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/progress.dart';
import '../../../state/providers.dart';
import '../../progress/widgets/progress_badge.dart';

class LevelPage extends ConsumerWidget {
  final String levelId;
  const LevelPage({super.key, required this.levelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Level $levelId')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          // LESSON TILE – now looks up videoId dynamically
          Consumer(
            builder: (context, ref, _) {
              final asyncLesson = ref.watch(lessonByIdProvider(levelId));

              return asyncLesson.when(
                loading: () => const _LevelTile(title: 'Lesson', route: ''),
                error: (_, __) => const _LevelTile(title: 'Lesson', route: ''),
                data: (video) {
                  return _LevelTile(
                    title: 'Lesson',
                    route: '/level/$levelId/lesson',
                    progressProvider: lessonProgressProvider,
                    levelId: levelId,
                    videoId: video.id, // 👈 dynamic!
                  );
                },
              );
            },
          ),
          _LevelTile(
            title: 'Puzzles',
            route: '/level/$levelId/puzzles',
          ),
          _LevelTile(
            title: 'Play',
            route: '/level/$levelId/play',
          ),
          _LevelTile(
            title: 'Boss',
            route: '/level/$levelId/boss',
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends ConsumerWidget {
  final String title;
  final String route;
  final String? levelId;
  final String? videoId;

  /// Accept a FutureProviderFamily, so we can call it with parameters
  final FutureProviderFamily<Progress, Map<String, String>>? progressProvider;

  const _LevelTile({
    required this.title,
    required this.route,
    this.levelId,
    this.videoId,
    this.progressProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget badge = const SizedBox.shrink();

    if (levelId != null && videoId != null && progressProvider != null) {
      final asyncProgress = ref.watch(
        progressProvider!({'levelId': levelId!, 'videoId': videoId!}),
      );

      badge = asyncProgress.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (progress) => ProgressBadge(progress: progress),
      );
    }

    return GestureDetector(
      onTap: () => context.push(route),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          Positioned(top: 8, right: 8, child: badge),
        ],
      ),
    );
  }
}