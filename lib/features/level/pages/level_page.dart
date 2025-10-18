// lib/features/level/pages/level_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/responsive_utils.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = ResponsiveUtils.getHorizontalPadding(context);
          final spacing = ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20);

          // Calculate responsive tile height based on screen size
          final tileHeight = ResponsiveUtils.getValue(
            context,
            mobile: constraints.maxHeight * 0.25, // 25% of screen height on mobile
            tablet: 200.0,
            desktop: 220.0,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                // Top tile - Lesson (wider, circular/diamond shape)
                SizedBox(
                  height: tileHeight,
                  child: Consumer(
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
                            videoId: video.id,
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: spacing),
                // Bottom row - Puzzles and Games (side by side)
                SizedBox(
                  height: tileHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _LevelTile(
                          title: 'Puzzles',
                          route: '/level/$levelId/puzzles',
                          progressType: _ProgressType.puzzle,
                          levelId: levelId,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: _LevelTile(
                          title: 'Games',
                          route: '/level/$levelId/play',
                          progressType: _ProgressType.play,
                          levelId: levelId,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 24, desktop: 28)),
                // Boss unlock requirements display
                _BossUnlockRequirementsDisplay(levelId: levelId),
              ],
            ),
          );
        },
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

/// Displays boss unlock requirements progress for this level
/// (Boss is at campaign level, but we show progress here for visibility)
class _BossUnlockRequirementsDisplay extends ConsumerWidget {
  final String levelId;

  const _BossUnlockRequirementsDisplay({required this.levelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockRequirementsAsync = ref.watch(bossUnlockRequirementsProvider(levelId));

    return unlockRequirementsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requirements) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: ResponsiveUtils.getIconSize(context, mobile: 22, tablet: 24, desktop: 28),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 6, tablet: 8, desktop: 10)),
                    Text(
                      'Level Progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRequirement(
                  context,
                  'Lesson',
                  requirements.lessonStatus,
                  requirements.lessonComplete,
                ),
                _buildRequirement(
                  context,
                  'Puzzles',
                  requirements.puzzleStatus,
                  requirements.puzzlesComplete,
                ),
                _buildRequirement(
                  context,
                  'Games',
                  requirements.playStatus,
                  requirements.playComplete,
                ),
                if (requirements.isUnlocked) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Level complete! Return to campaign to continue.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequirement(
    BuildContext context,
    String label,
    String status,
    bool completed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: ResponsiveUtils.getIconSize(context, mobile: 18, tablet: 20, desktop: 22),
            color: completed ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            status,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}