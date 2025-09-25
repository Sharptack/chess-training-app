// lib/data/models/puzzle.dart

/// Individual puzzle with chess position and solution
class Puzzle {
  final String id;
  final String title;
  final String subtitle;
  final String fen;
  final String toMove; // "white" or "black"
  final List<String> themes;
  final int difficulty;
  final List<String> solutionMoves; // Can be multiple valid solutions
  final List<String> hints;
  final String successMessage;
  final String failureMessage;

  const Puzzle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.fen,
    required this.toMove,
    required this.themes,
    required this.difficulty,
    required this.solutionMoves,
    required this.hints,
    required this.successMessage,
    required this.failureMessage,
  });

  /// Check if a move matches any of the solution moves
  bool isSolutionMove(String move) {
    // Clean up the move string (remove special characters that might differ)
    final cleanMove = _cleanMoveNotation(move);
    
    print('DEBUG Puzzle.isSolutionMove: Checking move "$move" (cleaned: "$cleanMove")');
    print('DEBUG Puzzle.isSolutionMove: Against solutions: $solutionMoves');
    
    // Check against each solution move
    for (final solution in solutionMoves) {
      final cleanSolution = _cleanMoveNotation(solution);
      print('DEBUG Puzzle.isSolutionMove: Comparing "$cleanMove" with "$cleanSolution"');
      
      // Check for exact match
      if (cleanMove == cleanSolution) {
        print('DEBUG Puzzle.isSolutionMove: MATCH FOUND!');
        return true;
      }
      
      // Also check if the move starts with the solution (for checkmate notation)
      // e.g., "Re8" matches "Re8#"
      if (cleanSolution.startsWith(cleanMove) || cleanMove.startsWith(cleanSolution)) {
        print('DEBUG Puzzle.isSolutionMove: PARTIAL MATCH FOUND!');
        return true;
      }
    }
    
    print('DEBUG Puzzle.isSolutionMove: No match found');
    return false;
  }
  
  /// Clean move notation for comparison
  String _cleanMoveNotation(String move) {
    // Remove check (+) and checkmate (#) symbols for comparison
    // as the chess engine might not always include them in the same way
    String cleaned = move.replaceAll('+', '').replaceAll('#', '');
    
    // Remove spaces
    cleaned = cleaned.trim();
    
    // Handle different move formats
    // If it's in the format "e1-e8", convert to "e1e8"
    if (cleaned.contains('-')) {
      cleaned = cleaned.replaceAll('-', '');
    }
    
    return cleaned;
  }

  bool get isWhiteToMove => toMove.toLowerCase() == 'white';
  bool get isBlackToMove => toMove.toLowerCase() == 'black';
  
  String get turnDisplay => isWhiteToMove ? 'White to Move' : 'Black to Move';

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      fen: json['fen'] as String,
      toMove: json['toMove'] as String,
      themes: List<String>.from(json['themes'] as List),
      difficulty: json['difficulty'] as int,
      solutionMoves: List<String>.from(json['solutionMoves'] as List),
      hints: List<String>.from(json['hints'] as List),
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

  @override
  String toString() {
    return 'Puzzle(id: $id, title: $title, difficulty: $difficulty)';
  }
}