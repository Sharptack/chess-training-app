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
import '../data/models/video_item.dart';
import '../data/repositories/puzzle_repository.dart';
import '../data/models/puzzle.dart';
import '../data/models/puzzle_set.dart';
import '../data/models/bot_progress.dart';


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
    // Force Riverpod to detect the change by creating a new reference
    final currentState = state;
    state = null;
    state = currentState;
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

/// Get overall play progress for a level (checks if all bots have completed required games)
final playProgressProvider = FutureProvider.family<Progress, String>(
  (ref, String levelId) async {
    print('DEBUG playProgressProvider: Checking progress for level $levelId');

    // Get level to know which bots and how many games required
    final levelResult = await ref.watch(levelRepositoryProvider).getLevelById(levelId);

    if (levelResult.isError) {
      print('DEBUG playProgressProvider: Error loading level');
      return Progress(levelId: levelId, videoId: 'play', started: false, completed: false);
    }

    final level = levelResult.data!;
    final progressRepo = ref.watch(progressRepositoryProvider);

    print('DEBUG playProgressProvider: Level has ${level.playBotIds.length} bots, ${level.requiredGames} games required per bot');

    // Check progress for each bot
    int totalGamesPlayed = 0;
    bool anyStarted = false;

    for (final botId in level.playBotIds) {
      final botProgress = await progressRepo.getBotProgress(levelId, botId);
      print('DEBUG playProgressProvider: Bot $botId has ${botProgress.gamesPlayed} games played');
      totalGamesPlayed += botProgress.gamesPlayed;
      if (botProgress.gamesPlayed > 0) {
        anyStarted = true;
      }
    }

    // Calculate total required games (requiredGames per bot * number of bots)
    final totalRequired = level.requiredGames * level.playBotIds.length;
    final completed = totalGamesPlayed >= totalRequired;

    print('DEBUG playProgressProvider: Total games played: $totalGamesPlayed, Total required: $totalRequired, Completed: $completed');

    return Progress(
      levelId: levelId,
      videoId: 'play',
      started: anyStarted,
      completed: completed,
      startedAt: anyStarted ? DateTime.now() : null,
      completedAt: completed ? DateTime.now() : null,
    );
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

    // Count total games needed
    int totalGamesPlayed = 0;
    for (final botId in level.playBotIds) {
      final botProgress = await progressRepo.getBotProgress(levelId, botId);
      totalGamesPlayed += botProgress.gamesPlayed;
    }
    final totalRequired = level.requiredGames * level.playBotIds.length;
    final gamesRemaining = totalRequired - totalGamesPlayed;
    final playStatus = playComplete
        ? 'Complete'
        : '$gamesRemaining more ${gamesRemaining == 1 ? 'game' : 'games'}';

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
final bossProgressProvider = FutureProvider.family<Progress, String>(
  (ref, String levelId) async {
    final repo = ref.watch(progressRepositoryProvider);
    return repo.getLessonProgress('boss', levelId);
  },
);

/// Mark boss as completed
Future<void> markBossCompleted(WidgetRef ref, String levelId) async {
  final repo = ref.read(progressRepositoryProvider);
  await repo.markLessonCompleted('boss', levelId);
  ref.invalidate(bossProgressProvider(levelId));
}