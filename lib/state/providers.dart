// lib/state/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/repositories/progress_repository.dart';
import '../data/models/progress.dart';
import '../data/repositories/level_repository.dart';
import '../data/models/video_item.dart';
import '../data/repositories/puzzle_repository.dart';
import '../data/models/puzzle.dart';
import '../data/models/puzzle_set.dart';


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

// PuzzleRepository provider
final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  return PuzzleRepository();
});

/// Returns a puzzle set for a specific level
/// Returns a puzzle set for a specific level
final puzzleSetProvider = FutureProvider.family<PuzzleSet, String>((ref, String levelId) async {
  print('DEBUG: puzzleSetProvider called with levelId: $levelId'); // Add this
  final repo = ref.watch(puzzleRepositoryProvider);
  print('DEBUG: Got repository, calling getPuzzleSetByLevelId'); // Add this
  final result = await repo.getPuzzleSetByLevelId(levelId);

  if (result.isError) {
    print('DEBUG: Repository returned error: ${result.failure}'); // Add this
    throw Exception(result.failure.toString());
  }

  print('DEBUG: Repository returned success, puzzle set loaded'); // Add this
  return result.data!;
});

/// Returns a single puzzle by ID (if you still need individual puzzle access)
final puzzleProvider = FutureProvider.family<Puzzle, String>((ref, String puzzleId) async {
  final repo = ref.watch(puzzleRepositoryProvider);
  final result = await repo.getPuzzleById(puzzleId);

  if (result.isError) {
    throw Exception(result.failure.toString());
  }

  return result.data!;
});

/// Command helper to mark puzzle completion
Future<void> markPuzzleCompleted(WidgetRef ref, String puzzleId) async {
  final repo = ref.read(progressRepositoryProvider);
  // Using the existing lesson completion pattern
  await repo.markLessonCompleted('puzzle', puzzleId);
  ref.invalidate(lessonProgressProvider('puzzle_$puzzleId'));
}