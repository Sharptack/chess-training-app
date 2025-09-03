import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/repositories/progress_repository.dart';
import '../data/models/progress.dart';
import '../data/repositories/level_repository.dart';
import '../data/models/video_item.dart';

// LevelRepository provider
final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  return LevelRepository();
});

/// Returns the lesson VideoItem for a given levelId.
final lessonByIdProvider =
    FutureProvider.family<VideoItem, String>((ref, String levelId) async {
  final repo = ref.watch(levelRepositoryProvider);
  final result = await repo.getLevelById(levelId);

  if (result.isError) {
    throw Exception(result.failure.toString());
  }

  final level = result.data!;
  return level.lessonVideo; // ✅ strongly typed, no dynamic hacks
});

// Hive-backed ProgressRepository provider
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final box = Hive.box('progressBox');
  return ProgressRepository(box);
});

/// Auto-refreshable lesson progress
final lessonProgressProvider = FutureProvider.family<Progress, Map<String, String>>(
  (ref, ids) async {
    final repo = ref.watch(progressRepositoryProvider);
    return repo.getLessonProgress(ids['levelId']!, ids['videoId']!);
  },
);

/// Command helpers (refresh after write)
Future<void> markLessonStarted(WidgetRef ref, String levelId, String videoId) async {
  final repo = ref.read(progressRepositoryProvider);
  await repo.markLessonStarted(levelId, videoId);
  ref.invalidate(
    lessonProgressProvider({'levelId': levelId, 'videoId': videoId}),
  );
}

Future<void> markLessonCompleted(WidgetRef ref, String levelId, String videoId) async {
  final repo = ref.read(progressRepositoryProvider);
  await repo.markLessonCompleted(levelId, videoId);
  ref.invalidate(
    lessonProgressProvider({'levelId': levelId, 'videoId': videoId}),
  );
}