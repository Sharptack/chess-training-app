// lib/data/models/puzzle.dart
import 'package:equatable/equatable.dart';

class Puzzle extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String fen; // chess position in FEN format
  final String toMove; // "white" or "black"
  final List<String> themes; // tactical themes (e.g., "checkmate", "fork", "pin")
  final int difficulty; // 1-10 difficulty scale
  final List<String> solutionMoves; // solution sequence in algebraic notation
  final List<String> hints; // optional hints for the puzzle
  final String successMessage; // message shown when solved correctly
  final String failureMessage; // message shown when incorrect move is made

  const Puzzle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.fen,
    required this.toMove,
    required this.themes,
    required this.difficulty,
    required this.solutionMoves,
    this.hints = const [],
    required this.successMessage,
    required this.failureMessage,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      fen: json['fen'] as String,
      toMove: json['toMove'] as String,
      themes: List<String>.from(json['themes'] as List<dynamic>),
      difficulty: json['difficulty'] as int,
      solutionMoves: List<String>.from(json['solutionMoves'] as List<dynamic>),
      hints: json['hints'] != null 
          ? List<String>.from(json['hints'] as List<dynamic>)
          : const [],
      successMessage: json['successMessage'] as String,
      failureMessage: json['failureMessage'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'fen': fen,
      'toMove': toMove,
      'themes': themes,
      'difficulty': difficulty,
      'solutionMoves': solutionMoves,
      'hints': hints,
      'successMessage': successMessage,
      'failureMessage': failureMessage,
    };
  }

  /// Convenience getter to determine if it's White's turn
  bool get isWhiteToMove => toMove.toLowerCase() == 'white';

  /// Get the first (primary) solution move
  String get primarySolution => solutionMoves.isNotEmpty ? solutionMoves.first : '';

  /// Check if a given move matches any of the solution moves
  bool isSolutionMove(String move) {
    return solutionMoves.contains(move);
  }

  /// Get a display string for whose turn it is
  String get turnDisplay => isWhiteToMove ? 'White to move' : 'Black to move';

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    fen,
    toMove,
    themes,
    difficulty,
    solutionMoves,
    hints,
    successMessage,
    failureMessage,
  ];
}