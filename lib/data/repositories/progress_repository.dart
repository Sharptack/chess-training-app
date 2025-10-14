// lib/data/repositories/progress_repository.dart
import 'package:hive/hive.dart';
import '../models/progress.dart';
import '../models/bot_progress.dart';

class ProgressRepository {
  final Box _box;

  ProgressRepository(this._box);

  String _key(String levelId, String videoId) => '${levelId}_$videoId';

  /// Fetch stored progress for a lesson
  Future<Progress> getLessonProgress(String levelId, String videoId) async {
    final key = _key(levelId, videoId);
    final stored = _box.get(key);
    if (stored == null) {
      return Progress(levelId: levelId, videoId: videoId, started: false, completed: false);
    }
    try {
      final map = Map<String, dynamic>.from(stored);
      map['levelId'] = levelId;
      map['videoId'] = videoId;
      final progress = Progress.fromJson(map);
      return progress;
    } catch (e) {
      return Progress(levelId: levelId, videoId: videoId, started: false, completed: false);
    }
  }

  /// Save progress (started) with timestamp (if not already set)
  Future<void> markLessonStarted(String levelId, String videoId) async {
    final key = _key(levelId, videoId);
    final existing = await getLessonProgress(levelId, videoId);
    final progress = existing.copyWith(
      started: true,
      startedAt: existing.startedAt ?? DateTime.now(),
    );
    await _box.put(key, progress.toJson());
  }

  /// Save progress (completed) with timestamps
  Future<void> markLessonCompleted(String levelId, String videoId) async {
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
  }

  /// Dev/testing helper: remove a lesson's progress
  Future<void> resetLesson(String levelId, String videoId) async {
    await _box.delete(_key(levelId, videoId));
  }

  Future<BotProgress> getBotProgress(String levelId, String botId) async {
    final key = 'bot_${levelId}_$botId';
    final data = _box.get(key);
    
    if (data == null) {
      return BotProgress(
        levelId: levelId,
        botId: botId,
        gamesRequired: 3, // Default, should come from level config
      );
    }
    
    return BotProgress.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> recordBotGame(String levelId, String botId, bool won, int requiredGames) async {
    final key = 'bot_${levelId}_$botId';
    final current = await getBotProgress(levelId, botId);

    final updated = BotProgress(
      levelId: levelId,
      botId: botId,
      gamesPlayed: current.gamesPlayed + 1,
      gamesWon: current.gamesWon + (won ? 1 : 0),
      gamesRequired: requiredGames,
      firstPlayedAt: current.firstPlayedAt ?? DateTime.now(),
      lastPlayedAt: DateTime.now(),
    );

    await _box.put(key, updated.toJson());
  }

  /// Mark campaign boss as completed
  Future<void> markCampaignBossCompleted(String campaignId) async {
    final key = 'campaign_boss_$campaignId';
    final progress = Progress(
      levelId: campaignId,
      videoId: 'boss',
      started: true,
      completed: true,
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
    await _box.put(key, progress.toJson());
  }

  /// Get campaign boss progress
  Future<Progress> getCampaignBossProgress(String campaignId) async {
    final key = 'campaign_boss_$campaignId';
    final stored = _box.get(key);

    if (stored == null) {
      return Progress(
        levelId: campaignId,
        videoId: 'boss',
        started: false,
        completed: false,
      );
    }

    try {
      final map = Map<String, dynamic>.from(stored);
      map['levelId'] = campaignId;
      map['videoId'] = 'boss';
      return Progress.fromJson(map);
    } catch (e) {
      return Progress(
        levelId: campaignId,
        videoId: 'boss',
        started: false,
        completed: false,
      );
    }
  }
}