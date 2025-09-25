// lib/data/repositories/puzzle_repository.dart
import '../models/puzzle.dart';
import '../models/puzzle_set.dart';
import '../sources/local/asset_source.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failure.dart';

class PuzzleRepository {
  final AssetSource _assetSource;
  final Map<String, PuzzleSet> _puzzleSetCache = {};
  final Map<String, Puzzle> _puzzleCache = {};

  PuzzleRepository({AssetSource? assetSource}) 
      : _assetSource = assetSource ?? const AssetSource();

  /// Get a puzzle set for a specific level
  Future<Result<PuzzleSet>> getPuzzleSetByLevelId(String levelId) async {
    final trimmed = levelId.trim();
    if (trimmed.isEmpty) {
      return Result.error(const EmptyDataFailure('Level ID is empty'));
    }

    // Return from cache if available
    if (_puzzleSetCache.containsKey(levelId)) {
      print('DEBUG: Returning cached puzzle set for level $levelId');
      return Result.success(_puzzleSetCache[levelId]!);
    }

    try {
      // Try different file naming conventions
      final possiblePaths = [
        'assets/data/puzzles/puzzle_set_$levelId.json',  // puzzle_set_0001.json
        'assets/data/puzzles/puzzle_set_${levelId.padLeft(4, '0')}.json',  // Ensure 4 digits
        'assets/data/puzzles/puzzle_set_${int.parse(levelId).toString().padLeft(3, '0')}.json',  // puzzle_set_001.json
      ];

      Result<Map<String, dynamic>>? successfulResult;
      String? successfulPath;

      for (final path in possiblePaths) {
        print('DEBUG: Trying to load puzzle set from: $path');
        final result = await _assetSource.readJson(path);
        
        if (result.isSuccess) {
          successfulResult = result;
          successfulPath = path;
          print('DEBUG: Successfully loaded from $path');
          break;
        }
      }

      if (successfulResult == null) {
        print('DEBUG: Failed to load puzzle set from any path for level $levelId');
        return Result.error(NotFoundFailure('Puzzle set not found for level $levelId'));
      }
      
      final puzzleSet = PuzzleSet.fromJson(successfulResult.data!);
      
      // Cache the puzzle set
      _puzzleSetCache[levelId] = puzzleSet;
      
      // Also cache individual puzzles for quick access
      for (final puzzle in puzzleSet.puzzles) {
        _puzzleCache[puzzle.id] = puzzle;
      }
      
      print('DEBUG: Loaded ${puzzleSet.puzzles.length} puzzles for level $levelId');
      return Result.success(puzzleSet);
    } catch (e, stackTrace) {
      print('DEBUG: Exception loading puzzle set: $e');
      print('DEBUG: Stack trace: $stackTrace');
      return Result.error(UnexpectedFailure('Failed to load puzzle set for level $levelId: $e'));
    }
  }

  // Rest of the methods remain the same...
  
  /// Get a single puzzle by ID (looks through all cached puzzle sets)
  Future<Result<Puzzle>> getPuzzleById(String puzzleId) async {
    final trimmed = puzzleId.trim();
    if (trimmed.isEmpty) {
      return Result.error(const EmptyDataFailure('Puzzle ID is empty'));
    }

    // Return from cache if available
    if (_puzzleCache.containsKey(puzzleId)) {
      return Result.success(_puzzleCache[puzzleId]!);
    }

    // If not in cache, we need to determine which level this puzzle belongs to
    // Expected format: puzzle_001_001 (level_puzzle)
    final parts = puzzleId.split('_');
    if (parts.length >= 3) {
      final levelId = parts[1]; // Extract level ID from puzzle ID
      
      // Try to load the puzzle set for this level
      final puzzleSetResult = await getPuzzleSetByLevelId(levelId);
      if (puzzleSetResult.isSuccess) {
        // Puzzle should now be in cache
        if (_puzzleCache.containsKey(puzzleId)) {
          return Result.success(_puzzleCache[puzzleId]!);
        }
      }
    }

    return Result.error(const NotFoundFailure('Puzzle not found'));
  }

  /// Get all puzzle sets (useful for overview/management)
  Future<Result<List<PuzzleSet>>> getAllPuzzleSets() async {
    // This would require knowing all available levels
    // For now, you could implement this by checking which files exist
    // or maintaining a manifest file
    return Result.error(const NotFoundFailure('getAllPuzzleSets not implemented yet'));
  }

  /// Clear all caches (useful for testing or memory management)
  void clearCache() {
    _puzzleSetCache.clear();
    _puzzleCache.clear();
  }

  /// Get puzzle statistics for a level
  PuzzleSetStats? getPuzzleSetStats(String levelId) {
    final puzzleSet = _puzzleSetCache[levelId];
    if (puzzleSet == null) return null;

    return PuzzleSetStats(
      totalPuzzles: puzzleSet.puzzleCount,
      difficulties: _getDifficultyDistribution(puzzleSet),
      themes: _getThemeDistribution(puzzleSet),
    );
  }

  Map<int, int> _getDifficultyDistribution(PuzzleSet puzzleSet) {
    final distribution = <int, int>{};
    for (final puzzle in puzzleSet.puzzles) {
      distribution[puzzle.difficulty] = (distribution[puzzle.difficulty] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _getThemeDistribution(PuzzleSet puzzleSet) {
    final distribution = <String, int>{};
    for (final puzzle in puzzleSet.puzzles) {
      for (final theme in puzzle.themes) {
        distribution[theme] = (distribution[theme] ?? 0) + 1;
      }
    }
    return distribution;
  }
}

/// Statistics for a puzzle set
class PuzzleSetStats {
  final int totalPuzzles;
  final Map<int, int> difficulties; // difficulty level -> count
  final Map<String, int> themes; // theme -> count

  const PuzzleSetStats({
    required this.totalPuzzles,
    required this.difficulties,
    required this.themes,
  });
}