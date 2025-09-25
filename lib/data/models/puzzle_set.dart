//lib/data/models/puzzle_set.dart
import 'package:equatable/equatable.dart';
import 'puzzle.dart';

class PuzzleSet extends Equatable {
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

  factory PuzzleSet.fromJson(Map<String, dynamic> json) {
    return PuzzleSet(
      levelId: json['levelId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      puzzles: (json['puzzles'] as List<dynamic>)
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

  /// Get puzzle by index
  Puzzle? getPuzzleAt(int index) {
    if (index >= 0 && index < puzzles.length) {
      return puzzles[index];
    }
    return null;
  }

  /// Total number of puzzles in this set
  int get puzzleCount => puzzles.length;

  @override
  List<Object?> get props => [levelId, title, description, puzzles];
}