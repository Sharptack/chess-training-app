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
    print('DEBUG: GameStateNotifier._onGameStateChanged called');
    // Force rebuild by creating a new reference
    final currentState = state;
    if (currentState != null) {
      state = null;  // Clear first
      state = currentState;  // Then reassign
    }
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