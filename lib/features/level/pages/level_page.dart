// lib/features/level/pages/level_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../state/providers.dart';
import '../../../core/widgets/locked_badge.dart';
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
            progressType: _ProgressType.boss,
            levelId: levelId,
          ),
        ],
      ),
    );
  }
}

enum _ProgressType { none, lesson, puzzle, play, boss }

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
    Widget? lockOverlay;

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

    // Handle puzzle progress (locked until lesson complete)
    else if (progressType == _ProgressType.puzzle && levelId != null) {
      // Check if lesson is complete first
      final lessonAsync = ref.watch(lessonByIdProvider(levelId!));

      return lessonAsync.when(
        loading: () => _buildTileContainer(context, null),
        error: (_, __) => _buildTileContainer(context, null),
        data: (video) {
          final lessonProgressAsync = ref.watch(lessonProgressProvider('${levelId!}_${video.id}'));

          return lessonProgressAsync.when(
            loading: () => _buildTileContainer(context, null),
            error: (_, __) => _buildTileContainer(context, null),
            data: (lessonProgress) {
              if (!lessonProgress.completed) {
                // Lesson not complete, show lock
                final lock = LockedBadge(
                  locked: true,
                  message: 'Complete the lesson to unlock',
                  requirements: [
                    RequirementItem(
                      label: 'Lesson',
                      status: 'Not complete',
                      completed: false,
                    ),
                  ],
                );
                return _buildLockedTile(context, lock);
              } else {
                // Lesson complete, show puzzle progress
                final asyncProgress = ref.watch(levelPuzzleProgressProvider(levelId!));
                badge = asyncProgress.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (progress) => ProgressBadge(progress: progress),
                );
                return _buildTileContainer(context, badge);
              }
            },
          );
        },
      );
    }

    // Handle play progress (locked until lesson complete)
    else if (progressType == _ProgressType.play && levelId != null) {
      // Check if lesson is complete first
      final lessonAsync = ref.watch(lessonByIdProvider(levelId!));

      return lessonAsync.when(
        loading: () => _buildTileContainer(context, null),
        error: (_, __) => _buildTileContainer(context, null),
        data: (video) {
          final lessonProgressAsync = ref.watch(lessonProgressProvider('${levelId!}_${video.id}'));

          return lessonProgressAsync.when(
            loading: () => _buildTileContainer(context, null),
            error: (_, __) => _buildTileContainer(context, null),
            data: (lessonProgress) {
              if (!lessonProgress.completed) {
                // Lesson not complete, show lock
                final lock = LockedBadge(
                  locked: true,
                  message: 'Complete the lesson to unlock',
                  requirements: [
                    RequirementItem(
                      label: 'Lesson',
                      status: 'Not complete',
                      completed: false,
                    ),
                  ],
                );
                return _buildLockedTile(context, lock);
              } else {
                // Lesson complete, show play progress
                final asyncProgress = ref.watch(playProgressProvider(levelId!));
                badge = asyncProgress.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (progress) => ProgressBadge(progress: progress),
                );
                return _buildTileContainer(context, badge);
              }
            },
          );
        },
      );
    }

    // Handle boss unlock and progress
    else if (progressType == _ProgressType.boss && levelId != null) {
      final unlockRequirementsAsync = ref.watch(bossUnlockRequirementsProvider(levelId!));
      final bossProgressAsync = ref.watch(bossProgressProvider(levelId!));

      return unlockRequirementsAsync.when(
        loading: () => _buildTileContainer(context, null),
        error: (_, __) => _buildTileContainer(context, null),
        data: (requirements) {
          if (requirements.isUnlocked) {
            // Boss is unlocked, show progress badge
            badge = bossProgressAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (progress) => ProgressBadge(progress: progress),
            );
            return _buildTileContainer(context, badge);
          } else {
            // Boss is locked, show requirements overlay
            lockOverlay = LockedBadge(
              locked: true,
              message: 'Complete requirements to unlock',
              requirements: [
                RequirementItem(
                  label: 'Lesson',
                  status: requirements.lessonStatus,
                  completed: requirements.lessonComplete,
                ),
                RequirementItem(
                  label: 'Puzzles',
                  status: requirements.puzzleStatus,
                  completed: requirements.puzzlesComplete,
                ),
                RequirementItem(
                  label: 'Play',
                  status: requirements.playStatus,
                  completed: requirements.playComplete,
                ),
              ],
            );
            return GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete all requirements to unlock the boss!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
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
                  lockOverlay!,
                ],
              ),
            );
          }
        },
      );
    }

    return _buildTileContainer(context, badge);
  }

  Widget _buildTileContainer(BuildContext context, Widget? badge) {
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
          if (badge != null) Positioned(top: 8, right: 8, child: badge),
        ],
      ),
    );
  }

  Widget _buildLockedTile(BuildContext context, Widget lockOverlay) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete the lesson to unlock this section!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
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
          lockOverlay,
        ],
      ),
    );
  }
}