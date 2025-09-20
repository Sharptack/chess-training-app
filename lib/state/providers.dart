import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/repositories/progress_repository.dart';
import '../data/models/progress.dart';
import '../data/repositories/level_repository.dart';
import '../data/models/video_item.dart';

/// Command helper to reset a lesson's progress and refresh its state.
Future<void> resetLesson(WidgetRef ref, String levelId, String videoId) async {
  final repo = ref.read(progressRepositoryProvider);
  await repo.resetLesson(levelId, videoId);
  // Use the stable string key format
  ref.invalidate(lessonProgressProvider('${levelId}_$videoId'));
}

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
  return level.lessonVideo;
});

// Hive-backed ProgressRepository provider
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final box = Hive.box('progressBox');
  return ProgressRepository(box);
});

/// Auto-refreshable lesson progress - using stable string key instead of Map
final lessonProgressProvider = FutureProvider.family<Progress, String>(
  (ref, String key) async {
    // Extract levelId and videoId from the key
    final parts = key.split('_');
    if (parts.length < 2) {
      throw ArgumentError('Invalid progress key format. Expected: levelId_videoId');
    }
    final levelId = parts[0];
    final videoId = parts.sublist(1).join('_'); // Handle videoIds that might contain underscores
    
    final repo = ref.watch(progressRepositoryProvider);
    return repo.getLessonProgress(levelId, videoId);
  },
);

/// Command helpers (refresh after write)
Future<void> markLessonStarted(WidgetRef ref, String levelId, String videoId) async {
  final repo = ref.read(progressRepositoryProvider);
  await repo.markLessonStarted(levelId, videoId);
  ref.invalidate(lessonProgressProvider('${levelId}_$videoId'));
}

Future<void> markLessonCompleted(WidgetRef ref, String levelId, String videoId) async {
  final repo = ref.read(progressRepositoryProvider);
  await repo.markLessonCompleted(levelId, videoId);
  ref.invalidate(lessonProgressProvider('${levelId}_$videoId'));
}