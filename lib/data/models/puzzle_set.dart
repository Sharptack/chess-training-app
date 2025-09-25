// lib/data/models/puzzle_set.dart

import 'puzzle.dart';

/// A collection of puzzles for a specific level
class PuzzleSet {
  final String levelId;
  final String title;
  final String description;
  final List<Puzzle> puzzles;

  const PuzzleSet({
    required this.levelId,
    required this.title,
    required this.description,
    required this.puzzles,
  });

  int get puzzleCount => puzzles.length;

  Puzzle? getPuzzleAt(int index) {
    if (index >= 0 && index < puzzles.length) {
      return puzzles[index];
    }
    return null;
  }

  Puzzle? getPuzzleById(String id) {
    try {
      return puzzles.firstWhere((puzzle) => puzzle.id == id);
    } catch (e) {
      return null;
    }
  }

  factory PuzzleSet.fromJson(Map<String, dynamic> json) {
    return PuzzleSet(
      levelId: json['levelId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      puzzles: (json['puzzles'] as List)
          .map((puzzleJson) => Puzzle.fromJson(puzzleJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'title': title,
      'description': description,
      'puzzles': puzzles.map((puzzle) => puzzle.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'PuzzleSet(levelId: $levelId, title: $title, puzzleCount: $puzzleCount)';
  }
}