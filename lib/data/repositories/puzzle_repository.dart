import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/puzzle.dart';
import 'package:ChessTrainerApp/core/utils/result.dart';
import 'package:ChessTrainerApp/core/errors/failure.dart';

class PuzzleRepository {
  final String indexPath;
  final Map<String, String> _indexCache = {};
  final Map<String, Puzzle> _puzzleCache = {};

  PuzzleRepository({this.indexPath = 'assets/data/puzzles/index.json'});

  Future<Result<Puzzle>> getPuzzleById(String id) async {
  final trimmed = id.trim();
  if (trimmed.isEmpty) {
    return Result.error(EmptyDataFailure('Puzzle ID is empty'));
  }

    // Return from cache if available
    if (_puzzleCache.containsKey(id)) {
      return Result.success(_puzzleCache[id]!);
    }

    try {
      // Load index.json if not cached
      if (_indexCache.isEmpty) {
        final indexJson = await rootBundle.loadString(indexPath);
        final Map<String, dynamic> jsonMap = json.decode(indexJson);
        _indexCache.addAll(jsonMap.map((k, v) => MapEntry(k, v as String)));
      }

      // Find which chunk file contains the puzzle
      final chunkFile = _indexCache[id];
      if (chunkFile == null) {
        return Result.error(NotFoundFailure('Puzzle ID not found in index'));
      }

      // Load chunk file
      final chunkJsonStr = await rootBundle.loadString('assets/data/puzzles/$chunkFile');
      final Map<String, dynamic> chunkJson = json.decode(chunkJsonStr);

      // Extract puzzle
      final puzzleJson = chunkJson[id];
      if (puzzleJson == null) {
        return Result.error(NotFoundFailure('Puzzle ID not found in chunk file'));
      }

      final puzzle = Puzzle.fromJson(puzzleJson);
      _puzzleCache[id] = puzzle; // cache for future
      return Result.success(puzzle);
    } catch (e) {
      return Result.error(UnexpectedFailure('Failed to load puzzle: $e'));
    }
  }
}
