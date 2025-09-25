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
  final List<String> solutionMoves; // For single-move puzzles
  final List<MoveSequence>? solutionSequence; // For multi-move puzzles
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
    this.solutionSequence,
    required this.hints,
    required this.successMessage,
    required this.failureMessage,
  });

  /// Check if this is a multi-move puzzle
  bool get isMultiMove => solutionSequence != null && solutionSequence!.isNotEmpty;
  
  /// Get total moves needed to solve (counting only user moves)
  int get totalUserMoves {
    if (!isMultiMove) return 1;
    return solutionSequence!.where((seq) => seq.isUserMove).length;
  }

  /// Check if a move matches any of the solution moves (for single-move puzzles)
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
  
  /// Check if a move is correct for multi-move puzzle at given step
  bool isCorrectMoveAtStep(String move, int stepIndex) {
    print('DEBUG Puzzle.isCorrectMoveAtStep: Checking move "$move" at step $stepIndex');
    
    if (!isMultiMove) {
      print('DEBUG: Not a multi-move puzzle, using single-move check');
      return isSolutionMove(move);
    }
    
    if (stepIndex >= solutionSequence!.length) {
      print('DEBUG: Step index $stepIndex is out of bounds (sequence length: ${solutionSequence!.length})');
      return false;
    }
    
    final expectedStep = solutionSequence![stepIndex];
    print('DEBUG: Expected at step $stepIndex: ${expectedStep.move} (isUserMove: ${expectedStep.isUserMove})');
    
    if (!expectedStep.isUserMove) {
      print('DEBUG: This step is for computer, not user');
      return false;
    }
    
    final cleanMove = _cleanMoveNotation(move);
    final cleanExpected = _cleanMoveNotation(expectedStep.move);
    
    print('DEBUG: Comparing cleaned moves: "$cleanMove" vs "$cleanExpected"');
    
    final matches = cleanMove == cleanExpected || 
           cleanExpected.startsWith(cleanMove) || 
           cleanMove.startsWith(cleanExpected);
           
    print('DEBUG: Match result: $matches');
    return matches;
  }
  
  /// Get computer's response move at given step
  String? getComputerResponseAtStep(int stepIndex) {
    if (!isMultiMove) return null;
    
    // Look for the next computer move after this step
    for (int i = stepIndex + 1; i < solutionSequence!.length; i++) {
      if (!solutionSequence![i].isUserMove) {
        return solutionSequence![i].move;
      }
    }
    
    return null;
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
    // Parse solution sequence if present
    List<MoveSequence>? sequence;
    if (json['solutionSequence'] != null) {
      sequence = (json['solutionSequence'] as List)
          .map((item) => MoveSequence.fromJson(item))
          .toList();
    }
    
    return Puzzle(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      fen: json['fen'] as String,
      toMove: json['toMove'] as String,
      themes: List<String>.from(json['themes'] as List),
      difficulty: json['difficulty'] as int,
      solutionMoves: List<String>.from(json['solutionMoves'] as List),
      solutionSequence: sequence,
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
      if (solutionSequence != null) 
        'solutionSequence': solutionSequence!.map((s) => s.toJson()).toList(),
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

/// Represents a single move in a multi-move puzzle sequence
class MoveSequence {
  final String move;        // The move in SAN notation
  final bool isUserMove;     // true if user should make this move, false if computer
  final String? comment;     // Optional comment about this move

  const MoveSequence({
    required this.move,
    required this.isUserMove,
    this.comment,
  });

  factory MoveSequence.fromJson(Map<String, dynamic> json) {
    return MoveSequence(
      move: json['move'] as String,
      isUserMove: json['isUserMove'] as bool,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'move': move,
      'isUserMove': isUserMove,
      if (comment != null) 'comment': comment,
    };
  }
}