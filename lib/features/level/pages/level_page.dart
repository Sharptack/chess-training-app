// lib/features/level/pages/level_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                    progressType: _ProgressType.lesson,
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
            progressType: _ProgressType.puzzle,
            levelId: levelId,
          ),
          _LevelTile(
            title: 'Play',
            route: '/level/$levelId/play',
            progressType: _ProgressType.play,
            levelId: levelId,
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

enum _ProgressType { none, lesson, puzzle, play }

class _LevelTile extends ConsumerWidget {
  final String title;
  final String route;
  final _ProgressType progressType;
  final String? levelId;
  final String? videoId;

  const _LevelTile({
    required this.title,
    required this.route,
    this.progressType = _ProgressType.none,
    this.levelId,
    this.videoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget badge = const SizedBox.shrink();

    // Handle lesson progress
    if (progressType == _ProgressType.lesson && levelId != null && videoId != null) {
      final progressKey = '${levelId!}_${videoId!}';
      final asyncProgress = ref.watch(lessonProgressProvider(progressKey));

      badge = asyncProgress.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (progress) => ProgressBadge(progress: progress),
      );
    }
    
    // Handle puzzle progress
    else if (progressType == _ProgressType.puzzle && levelId != null) {
      final asyncProgress = ref.watch(levelPuzzleProgressProvider(levelId!));

      badge = asyncProgress.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (progress) => ProgressBadge(progress: progress),
      );
    }

    // Handle play progress
    else if (progressType == _ProgressType.play && levelId != null) {
      final asyncProgress = ref.watch(playProgressProvider(levelId!));

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