import 'package:hive/hive.dart';
import '../models/progress.dart';

class ProgressRepository {
  final Box _box;

  ProgressRepository(this._box);

  /// Fetch stored progress for a lesson
  Future<Progress> getLessonProgress(String levelId, String videoId) async {
    final key = '${levelId}_$videoId';
    final stored = _box.get(key);

    if (stored == null) {
      return Progress(levelId: levelId, videoId: videoId, started: false, completed: false);
    }

    return Progress.fromJson(Map<String, dynamic>.from(stored));
  }

  /// Save progress (started)
  Future<void> markLessonStarted(String levelId, String videoId) async {
    final key = '${levelId}_$videoId';
    final existing = await getLessonProgress(levelId, videoId);
    final progress = existing.copyWith(started: true);
    await _box.put(key, progress.toJson());
  }

  /// Save progress (completed)
  Future<void> markLessonCompleted(String levelId, String videoId) async {
    final key = '${levelId}_$videoId';
    final existing = await getLessonProgress(levelId, videoId);
    final progress = existing.copyWith(started: true, completed: true);
    await _box.put(key, progress.toJson());
  }
}
