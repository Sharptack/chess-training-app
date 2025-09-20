// lib/data/repositories/progress_repository.dart
import 'package:hive/hive.dart';
import '../models/progress.dart';

class ProgressRepository {
  final Box _box;

  ProgressRepository(this._box);

  String _key(String levelId, String videoId) => '${levelId}_$videoId';

  /// Fetch stored progress for a lesson
  Future<Progress> getLessonProgress(String levelId, String videoId) async {
    final key = _key(levelId, videoId);
    print('ProgressRepository.getLessonProgress: key=$key'); // Debug
    
    final stored = _box.get(key);
    print('ProgressRepository.getLessonProgress: stored=$stored'); // Debug

    if (stored == null) {
      print('ProgressRepository.getLessonProgress: returning new progress'); // Debug
      return Progress(levelId: levelId, videoId: videoId, started: false, completed: false);
    }

    try {
      // stored is already a Map<String, dynamic> from Hive, not JSON string
      final map = Map<String, dynamic>.from(stored);
      // Add the IDs back since they're not stored in the JSON
      map['levelId'] = levelId;
      map['videoId'] = videoId;
      
      print('ProgressRepository.getLessonProgress: parsing map=$map'); // Debug
      final progress = Progress.fromJson(map);
      print('ProgressRepository.getLessonProgress: returning existing progress=$progress'); // Debug
      return progress;
    } catch (e, stackTrace) {
      print('ProgressRepository.getLessonProgress: ERROR parsing stored progress: $e'); // Debug
      print('StackTrace: $stackTrace'); // Debug
      // If parsing fails, return a fresh progress
      return Progress(levelId: levelId, videoId: videoId, started: false, completed: false);
    }
  }

  /// Save progress (started) with timestamp (if not already set)
  Future<void> markLessonStarted(String levelId, String videoId) async {
    print('ProgressRepository.markLessonStarted: $levelId, $videoId'); // Debug
    final key = _key(levelId, videoId);
    final existing = await getLessonProgress(levelId, videoId);
    final progress = existing.copyWith(
      started: true,
      startedAt: existing.startedAt ?? DateTime.now(),
    );
    await _box.put(key, progress.toJson());
    print('ProgressRepository.markLessonStarted: saved progress'); // Debug
  }

  /// Save progress (completed) with timestamps
  Future<void> markLessonCompleted(String levelId, String videoId) async {
    print('ProgressRepository.markLessonCompleted: $levelId, $videoId'); // Debug
    final key = _key(levelId, videoId);
    final existing = await getLessonProgress(levelId, videoId);
    final now = DateTime.now();
    final progress = existing.copyWith(
      started: true,
      completed: true,
      startedAt: existing.startedAt ?? now,
      completedAt: now,
    );
    await _box.put(key, progress.toJson());
    print('ProgressRepository.markLessonCompleted: saved progress'); // Debug
  }

  /// Dev/testing helper: remove a lesson's progress
  Future<void> resetLesson(String levelId, String videoId) async {
    print('ProgressRepository.resetLesson: $levelId, $videoId'); // Debug
    await _box.delete(_key(levelId, videoId));
    print('ProgressRepository.resetLesson: deleted progress'); // Debug
  }
}