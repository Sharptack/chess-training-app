// lib/state/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../core/game_logic/game_state.dart';
import '../core/game_logic/chess_board_state.dart';
import '../data/repositories/bot_repository.dart';
import '../data/models/bot.dart';

import '../data/repositories/progress_repository.dart';
import '../data/models/progress.dart';
import '../data/repositories/level_repository.dart';
import '../data/repositories/campaign_repository.dart';
import '../data/models/campaign.dart';
import '../data/models/video_item.dart';
import '../data/repositories/puzzle_repository.dart';
import '../data/models/puzzle.dart';
import '../data/models/puzzle_set.dart';
import '../data/models/bot_progress.dart';
import '../data/models/game_progress.dart';
import '../data/models/game.dart';

// ============================================================================
// CAMPAIGN PROVIDERS
// ============================================================================

/// CampaignRepository provider
final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return const CampaignRepository();
});

/// Returns all campaigns from the index
final allCampaignsProvider = FutureProvider<List<Campaign>>((ref) async {
  final repo = ref.watch(campaignRepositoryProvider);
  final result = await repo.getAllCampaigns();

  if (result.isError) {
    throw Exception(result.failure!.message);
  }

  return result.data!;
});

/// Returns a single campaign by ID
final campaignProvider = FutureProvider.family<Campaign, String>((ref, String campaignId) async {
  final repo = ref.watch(campaignRepositoryProvider);
  final result = await repo.getCampaignById(campaignId);

  if (result.isError) {
    throw Exception(result.failure!.message);
  }

  return result.data!;
});

/// Get count of completed levels in a campaign
final campaignLevelCompletionProvider = FutureProvider.family<(int, int), String>(
  (ref, String campaignId) async {
    final campaign = await ref.watch(campaignProvider(campaignId).future);

    int completedLevels = 0;

    for (final levelId in campaign.levelIds) {
      final levelRequirements = await ref.watch(bossUnlockRequirementsProvider(levelId).future);
      if (levelRequirements.isUnlocked) {
        completedLevels++;
      }
    }

    return (completedLevels, campaign.levelIds.length);
  },
);

/// Returns boss unlock requirements for a campaign (checks ALL levels in campaign)
/// Simplified: Just checks if all levels are complete
final campaignBossUnlockRequirementsProvider = FutureProvider.family<BossUnlockRequirements, String>(
  (ref, String campaignId) async {
    final completion = await ref.watch(campaignLevelCompletionProvider(campaignId).future);
    final completedLevels = completion.$1;
    final totalLevels = completion.$2;
    final allLevelsComplete = completedLevels >= totalLevels;

    return BossUnlockRequirements(
      lessonComplete: allLevelsComplete,
      lessonStatus: '$completedLevels / $totalLevels levels complete',
      puzzlesComplete: allLevelsComplete,
      puzzleStatus: '',
      playComplete: allLevelsComplete,
      playStatus: '',
    );
  },
);

// ============================================================================
// LEVEL & LESSON PROVIDERS
// ============================================================================

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

/// Returns the full Level model for a given levelId.
final levelProvider =
    FutureProvider.family((ref, String levelId) async {
  final repo = ref.watch(levelRepositoryProvider);
  final result = await repo.getLevelById(levelId);

  if (result.isError) {
    throw Exception(result.failure!.message);
  }

  return result.data!;
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
  ref.invalidate(bossUnlockRequirementsProvider(levelId));
}

// PuzzleRepository provider
final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  return PuzzleRepository();
});

/// Returns a puzzle set for a specific level
final puzzleSetProvider = FutureProvider.family<PuzzleSet, String>((ref, String levelId) async {
  final repo = ref.watch(puzzleRepositoryProvider);
  final result = await repo.getPuzzleSetByLevelId(levelId);

  if (result.isError) {
    throw Exception(result.failure.toString());
  }

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

/// Command helper to mark individual puzzle completion
Future<void> markPuzzleCompleted(WidgetRef ref, String levelId, String puzzleId) async {
  final repo = ref.read(progressRepositoryProvider);
  // Use a combined key for puzzle progress
  await repo.markLessonCompleted('puzzle_${levelId}', puzzleId);
  ref.invalidate(lessonProgressProvider('puzzle_${levelId}_$puzzleId'));
}

/// Command helper to mark all puzzles complete for a level
Future<void> markLevelPuzzlesCompleted(WidgetRef ref, String levelId) async {
  final repo = ref.read(progressRepositoryProvider);
  await repo.markLessonCompleted('puzzles', levelId);
  ref.invalidate(lessonProgressProvider('puzzles_$levelId'));
  ref.invalidate(levelPuzzleProgressProvider(levelId));
  ref.invalidate(bossUnlockRequirementsProvider(levelId));
}

/// Get puzzle progress for a specific puzzle
final puzzleProgressProvider = FutureProvider.family<Progress, String>(
  (ref, String key) async {
    // Key format: levelId_puzzleId
    final parts = key.split('_');
    if (parts.length < 2) {
      throw ArgumentError('Invalid puzzle progress key format');
    }
    final levelId = parts[0];
    final puzzleId = parts.sublist(1).join('_');
    
    final repo = ref.watch(progressRepositoryProvider);
    return repo.getLessonProgress('puzzle_$levelId', puzzleId);
  },
);

/// Get overall puzzle completion for a level
final levelPuzzleProgressProvider = FutureProvider.family<Progress, String>(
  (ref, String levelId) async {
    final repo = ref.watch(progressRepositoryProvider);
    return repo.getLessonProgress('puzzles', levelId);
  },
);

// Bot repository provider
final botRepositoryProvider = Provider<BotRepository>((ref) {
  return BotRepository();
});

/// Get all available bots
final botsProvider = FutureProvider<List<Bot>>((ref) async {
  final repo = ref.watch(botRepositoryProvider);
  final result = await repo.getAllBots();
  
  if (result.isError) {
    throw Exception(result.failure.toString());
  }
  
  return result.data!;
});

/// Get a specific bot by ID
final botProvider = FutureProvider.family<Bot, String>((ref, String botId) async {
  final repo = ref.watch(botRepositoryProvider);
  final result = await repo.getBotById(botId);
  
  if (result.isError) {
    throw Exception(result.failure.toString());
  }
  
  return result.data!;
});

/// Chess board state provider - creates a new instance per game
final chessBoardStateProvider = Provider.family<ChessBoardState, String>((ref, String gameId) {
  final boardState = ChessBoardState();
  ref.onDispose(() => boardState.dispose());
  return boardState;
});

/// State notifier for managing game state
final gameStateNotifierProvider = StateNotifierProvider.family<GameStateNotifier, GameState?, String>(
  (ref, gameId) => GameStateNotifier(),
);

class GameStateNotifier extends StateNotifier<GameState?> {
  GameStateNotifier() : super(null);
  
  void startGame({
    required Bot bot,
    required bool humanPlaysWhite,
  }) {
    // Clean up previous game
    state?.dispose();
    state?.removeListener(_onGameStateChanged);
    
    // Create new game
    final boardState = ChessBoardState();
    final gameState = GameState(
      boardState: boardState,
      botConfig: bot,
      humanPlaysWhite: humanPlaysWhite,
    );
    
    // Listen to GameState changes and trigger UI rebuilds
    gameState.addListener(_onGameStateChanged);
    
    state = gameState;
  }
  
  void _onGameStateChanged() {
    // Notify Riverpod that the state has changed
    // In StateNotifier, reassigning state to itself triggers change detection
    state = state;
  }
  
  void endGame() {
    state?.removeListener(_onGameStateChanged);
    state?.dispose();
    state = null;
  }
  
  @override
  void dispose() {
    state?.removeListener(_onGameStateChanged);
    state?.dispose();
    super.dispose();
  }
}

/// Get bot progress for a level
final botProgressProvider = FutureProvider.family<BotProgress, String>(
  (ref, String key) async {
    final parts = key.split('_');
    if (parts.length < 2) {
      throw ArgumentError('Invalid bot progress key format');
    }
    final levelId = parts[0];
    final botId = parts.sublist(1).join('_');
    
    final repo = ref.watch(progressRepositoryProvider);
    return repo.getBotProgress(levelId, botId);
  },
);

/// Get game progress (for non-bot games like check_checkmate)
final gameProgressProvider = FutureProvider.family<GameProgress, String>(
  (ref, String gameId) async {
    final repo = ref.watch(progressRepositoryProvider);
    // We need to get the game to know completionsRequired
    // For now, use a default of 1 - this should be improved
    return repo.getGameProgress(gameId, 1);
  },
);

/// Record a completed bot game
Future<void> recordBotGameCompleted(
  WidgetRef ref,
  String levelId,
  String botId,
  bool won,
  int requiredGames,
) async {
  final repo = ref.read(progressRepositoryProvider);
  await repo.recordBotGame(levelId, botId, won, requiredGames);
  ref.invalidate(botProgressProvider('${levelId}_$botId'));
  ref.invalidate(playProgressProvider(levelId));
  ref.invalidate(bossUnlockRequirementsProvider(levelId));
}

/// Get overall play progress for a level (checks all games' completion requirements)
final playProgressProvider = FutureProvider.family<Progress, String>(
  (ref, String levelId) async {
    print('DEBUG playProgressProvider: Checking progress for level $levelId');

    // Get level to know which games are required
    final levelResult = await ref.watch(levelRepositoryProvider).getLevelById(levelId);

    if (levelResult.isError) {
      print('DEBUG playProgressProvider: Error loading level');
      return Progress(levelId: levelId, videoId: 'play', started: false, completed: false);
    }

    final level = levelResult.data!;
    final progressRepo = ref.watch(progressRepositoryProvider);

    // If level has games array, use that; otherwise fall back to bot IDs
    if (level.games.isNotEmpty) {
      print('DEBUG playProgressProvider: Level has ${level.games.length} games');

      int gamesCompleted = 0;
      bool anyStarted = false;

      for (final game in level.games) {
        if (game.type == GameType.bot) {
          // For bot games, check bot progress
          final botProgress = await progressRepo.getBotProgress(levelId, game.botId!);
          print('DEBUG playProgressProvider: Bot game ${game.id} has ${botProgress.gamesPlayed}/${game.completionsRequired}');

          if (botProgress.gamesPlayed >= game.completionsRequired) {
            gamesCompleted++;
          }
          if (botProgress.gamesPlayed > 0) {
            anyStarted = true;
          }
        } else {
          // For non-bot games (like check_checkmate), check game progress
          final gameProgress = await progressRepo.getGameProgress(game.id, game.completionsRequired);
          print('DEBUG playProgressProvider: Game ${game.id} has ${gameProgress.completions}/${game.completionsRequired}');

          if (gameProgress.completions >= game.completionsRequired) {
            gamesCompleted++;
          }
          if (gameProgress.completions > 0) {
            anyStarted = true;
          }
        }
      }

      final totalRequired = level.games.length;
      final completed = gamesCompleted >= totalRequired;

      print('DEBUG playProgressProvider: Games completed: $gamesCompleted/$totalRequired, Completed: $completed');

      return Progress(
        levelId: levelId,
        videoId: 'play',
        started: anyStarted,
        completed: completed,
        startedAt: anyStarted ? DateTime.now() : null,
        completedAt: completed ? DateTime.now() : null,
      );
    } else {
      // Legacy: use playBotIds
      print('DEBUG playProgressProvider: Level has ${level.playBotIds.length} bots (legacy), ${level.requiredGames} games required per bot');

      int botsCompleted = 0;
      bool anyStarted = false;

      for (final botId in level.playBotIds) {
        final botProgress = await progressRepo.getBotProgress(levelId, botId);
        print('DEBUG playProgressProvider: Bot $botId has ${botProgress.gamesPlayed} games played');

        if (botProgress.gamesPlayed >= level.requiredGames) {
          botsCompleted++;
        }

        if (botProgress.gamesPlayed > 0) {
          anyStarted = true;
        }
      }

      final totalRequired = level.playBotIds.length;
      final completed = botsCompleted >= totalRequired;

      print('DEBUG playProgressProvider: Bots completed: $botsCompleted, Total required: $totalRequired, Completed: $completed');

      return Progress(
        levelId: levelId,
        videoId: 'play',
        started: anyStarted,
        completed: completed,
        startedAt: anyStarted ? DateTime.now() : null,
        completedAt: completed ? DateTime.now() : null,
      );
    }
  },
);

/// Model for boss unlock requirements status
class BossUnlockRequirements {
  final bool lessonComplete;
  final bool puzzlesComplete;
  final bool playComplete;
  final bool isUnlocked;
  final String lessonStatus;
  final String puzzleStatus;
  final String playStatus;

  BossUnlockRequirements({
    required this.lessonComplete,
    required this.puzzlesComplete,
    required this.playComplete,
    required this.lessonStatus,
    required this.puzzleStatus,
    required this.playStatus,
  }) : isUnlocked = lessonComplete && puzzlesComplete && playComplete;
}

/// Check if a level is unlocked (first level always unlocked, others need previous complete)
final isLevelUnlockedProvider = FutureProvider.family<bool, String>(
  (ref, String levelId) async {
    // Get the level to find its campaign and position
    final levelResult = await ref.watch(levelRepositoryProvider).getLevelById(levelId);
    if (levelResult.isError) return false;

    final level = levelResult.data!;

    // Get the campaign to find level order
    final campaignResult = await ref.watch(campaignProvider(level.campaignId).future);
    final campaign = campaignResult;

    // Find this level's position in the campaign
    final levelIndex = campaign.levelIds.indexOf(levelId);

    // First level is always unlocked
    if (levelIndex <= 0) return true;

    // Check if previous level is complete
    final previousLevelId = campaign.levelIds[levelIndex - 1];
    final previousLevelRequirements = await ref.watch(bossUnlockRequirementsProvider(previousLevelId).future);

    return previousLevelRequirements.isUnlocked;
  },
);

/// Check if boss is unlocked for a level
final bossUnlockRequirementsProvider = FutureProvider.family<BossUnlockRequirements, String>(
  (ref, String levelId) async {
    // Get level to know requirements
    final levelResult = await ref.watch(levelRepositoryProvider).getLevelById(levelId);

    if (levelResult.isError) {
      return BossUnlockRequirements(
        lessonComplete: false,
        puzzlesComplete: false,
        playComplete: false,
        lessonStatus: 'Error loading level',
        puzzleStatus: 'Error loading level',
        playStatus: 'Error loading level',
      );
    }

    final level = levelResult.data!;
    final progressRepo = ref.watch(progressRepositoryProvider);

    // Check lesson progress
    final lessonProgress = await progressRepo.getLessonProgress(levelId, level.lessonVideo.id);
    final lessonComplete = lessonProgress.completed;
    final lessonStatus = lessonComplete ? 'Complete' : 'Not started';

    // Check puzzle progress
    final puzzleProgress = await progressRepo.getLessonProgress('puzzles', levelId);
    final puzzlesComplete = puzzleProgress.completed;

    // Count completed puzzles
    int completedPuzzles = 0;
    for (final puzzleId in level.puzzleIds) {
      final progress = await progressRepo.getLessonProgress('puzzle_$levelId', puzzleId);
      if (progress.completed) completedPuzzles++;
    }
    final puzzleStatus = puzzlesComplete
        ? 'Complete'
        : '${level.puzzleIds.length - completedPuzzles} remaining';

    // Check play progress
    final playProgress = await ref.watch(playProgressProvider(levelId).future);
    final playComplete = playProgress.completed;

    // Count total games played vs required
    int totalGamesPlayed = 0;
    for (final botId in level.playBotIds) {
      final botProgress = await progressRepo.getBotProgress(levelId, botId);
      // Cap each bot's contribution at requiredGames
      totalGamesPlayed += botProgress.gamesPlayed.clamp(0, level.requiredGames);
    }
    final totalGamesRequired = level.playBotIds.length * level.requiredGames;
    final playStatus = playComplete
        ? 'Complete'
        : '$totalGamesPlayed / $totalGamesRequired games';

    return BossUnlockRequirements(
      lessonComplete: lessonComplete,
      puzzlesComplete: puzzlesComplete,
      playComplete: playComplete,
      lessonStatus: lessonStatus,
      puzzleStatus: puzzleStatus,
      playStatus: playStatus,
    );
  },
);

/// Get boss progress for a level (simple: completed or not)
/// DEPRECATED: Use campaignBossProgressProvider instead
final bossProgressProvider = FutureProvider.family<Progress, String>(
  (ref, String levelId) async {
    final repo = ref.watch(progressRepositoryProvider);
    return repo.getLessonProgress('boss', levelId);
  },
);

/// Get campaign boss progress (new campaign-level tracking)
final campaignBossProgressProvider = FutureProvider.family<Progress, String>(
  (ref, String campaignId) async {
    final repo = ref.watch(progressRepositoryProvider);
    return repo.getCampaignBossProgress(campaignId);
  },
);

/// Mark campaign boss as completed
Future<void> markBossCompleted(WidgetRef ref, String campaignId) async {
  final repo = ref.read(progressRepositoryProvider);
  await repo.markCampaignBossCompleted(campaignId);
  ref.invalidate(campaignBossProgressProvider(campaignId));
  // Invalidate campaign unlock for all campaigns (next campaign may now be unlocked)
  ref.invalidate(allCampaignsProvider);
}

/// Check if a campaign is unlocked
/// Campaign 1 is always unlocked, others require previous campaign boss defeated
final isCampaignUnlockedProvider = FutureProvider.family<bool, String>(
  (ref, String campaignId) async {
    // Get all campaigns to determine order
    final allCampaigns = await ref.watch(allCampaignsProvider.future);

    // Find this campaign's index
    final campaignIndex = allCampaigns.indexWhere((c) => c.id == campaignId);

    // If not found or is first campaign, it's unlocked
    if (campaignIndex <= 0) return true;

    // Check if previous campaign's boss is defeated
    final previousCampaign = allCampaigns[campaignIndex - 1];
    final previousBossProgress = await ref.watch(
      campaignBossProgressProvider(previousCampaign.id).future
    );

    return previousBossProgress.completed;
  },
);