// lib/core/game_logic/mock_bot.dart
import 'dart:math';
import 'chess_board_state.dart';

/// A mock chess bot with adjustable difficulty levels (1-5)
class MockBot {
  final int difficulty; // 1 = random, 5 = best effort
  final Random _random = Random();
  
  MockBot({required this.difficulty}) {
    assert(difficulty >= 1 && difficulty <= 5, 'Difficulty must be 1-5');
  }
  
  /// Get the bot's next move given the current board state
  /// Returns null if no legal moves available
  Future<String?> getNextMove(ChessBoardState boardState) async {
    // Simulate thinking time based on difficulty
    await _simulateThinkingTime();
    
    final legalMoves = boardState.getLegalMoves();
    if (legalMoves.isEmpty) return null;
    
    switch (difficulty) {
      case 1:
        return _getRandomMove(legalMoves);
      case 2:
        return _getPreferCapturesMove(boardState, legalMoves);
      case 3:
        return _getPreferCapturesAndChecksMove(boardState, legalMoves);
      case 4:
        return _getBasicEvaluationMove(boardState, legalMoves);
      case 5:
        return _getAdvancedEvaluationMove(boardState, legalMoves);
      default:
        return _getRandomMove(legalMoves);
    }
  }
  
  Future<void> _simulateThinkingTime() async {
    final baseDelay = 500; // Base 500ms
    final variableDelay = difficulty * 300; // Up to 1.5s more for level 5
    final randomVariation = _random.nextInt(500); // ±500ms random
    
    final totalDelay = baseDelay + variableDelay + randomVariation;
    await Future.delayed(Duration(milliseconds: totalDelay));
  }
  
  String _getRandomMove(List<String> legalMoves) {
    return legalMoves[_random.nextInt(legalMoves.length)];
  }
  
  String _getPreferCapturesMove(ChessBoardState boardState, List<String> legalMoves) {
    // Separate captures from non-captures
    final captures = <String>[];
    final nonCaptures = <String>[];
    
    for (final move in legalMoves) {
      if (_isCapture(move)) {
        captures.add(move);
      } else {
        nonCaptures.add(move);
      }
    }
    
    // 80% chance to play a capture if available
    if (captures.isNotEmpty && _random.nextDouble() < 0.8) {
      return captures[_random.nextInt(captures.length)];
    }
    
    return _getRandomMove(legalMoves);
  }
  
  String _getPreferCapturesAndChecksMove(ChessBoardState boardState, List<String> legalMoves) {
    final captures = <String>[];
    final checks = <String>[];
    final normal = <String>[];
    
    for (final move in legalMoves) {
      if (_isCapture(move)) {
        captures.add(move);
      } else if (_isCheck(move)) {
        checks.add(move);
      } else {
        normal.add(move);
      }
    }
    
    // Priority: captures > checks > normal moves
    if (captures.isNotEmpty && _random.nextDouble() < 0.8) {
      return captures[_random.nextInt(captures.length)];
    }
    
    if (checks.isNotEmpty && _random.nextDouble() < 0.6) {
      return checks[_random.nextInt(checks.length)];
    }
    
    return _getRandomMove(legalMoves);
  }
  
  String _getBasicEvaluationMove(ChessBoardState boardState, List<String> legalMoves) {
    String bestMove = legalMoves.first;
    double bestScore = double.negativeInfinity;
    
    for (final move in legalMoves) {
      final score = _evaluateMove(boardState, move);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    
    // Add some randomness - don't always pick the "best" move
    if (_random.nextDouble() < 0.3) {
      return _getRandomMove(legalMoves);
    }
    
    return bestMove;
  }
  
  String _getAdvancedEvaluationMove(ChessBoardState boardState, List<String> legalMoves) {
    // For now, same as basic but with less randomness
    String bestMove = legalMoves.first;
    double bestScore = double.negativeInfinity;
    
    for (final move in legalMoves) {
      final score = _evaluateMove(boardState, move) + _getPositionalBonus(boardState, move);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    
    // Less randomness for higher difficulty
    if (_random.nextDouble() < 0.1) {
      return _getRandomMove(legalMoves);
    }
    
    return bestMove;
  }
  
  bool _isCapture(String move) {
    return move.contains('x');
  }
  
  bool _isCheck(String move) {
    return move.endsWith('+');
  }
  
  double _evaluateMove(ChessBoardState boardState, String move) {
    double score = 0.0;
    
    // Bonus for captures
    if (_isCapture(move)) {
      score += 5.0;
      
      // Bonus based on captured piece value
      final capturedPiece = _extractCapturedPiece(move);
      score += _getPieceValue(capturedPiece);
    }
    
    // Bonus for checks
    if (_isCheck(move)) {
      score += 3.0;
    }
    
    // Bonus for checkmate
    if (move.endsWith('#')) {
      score += 1000.0;
    }
    
    // Small random factor to avoid identical evaluations
    score += _random.nextDouble() * 0.1;
    
    return score;
  }
  
  double _getPositionalBonus(ChessBoardState boardState, String move) {
    double bonus = 0.0;
    
    // Bonus for moving pieces toward center
    final destination = _extractDestination(move);
    if (destination != null) {
      bonus += _getCenterControlBonus(destination);
    }
    
    // Small bonus for castle
    if (move == 'O-O' || move == 'O-O-O') {
      bonus += 2.0;
    }
    
    return bonus;
  }
  
  double _getPieceValue(String? piece) {
    if (piece == null) return 0.0;
    
    switch (piece.toLowerCase()) {
      case 'p': return 1.0;
      case 'n': case 'b': return 3.0;
      case 'r': return 5.0;
      case 'q': return 9.0;
      case 'k': return 100.0; // Should never be captured, but just in case
      default: return 0.0;
    }
  }
  
  double _getCenterControlBonus(String square) {
    // Bonus for controlling center squares
    const centerSquares = ['d4', 'd5', 'e4', 'e5'];
    const nearCenterSquares = ['c3', 'c4', 'c5', 'c6', 'd3', 'd6', 'e3', 'e6', 'f3', 'f4', 'f5', 'f6'];
    
    if (centerSquares.contains(square)) {
      return 1.0;
    } else if (nearCenterSquares.contains(square)) {
      return 0.5;
    }
    
    return 0.0;
  }
  
  String? _extractCapturedPiece(String move) {
    // This is a simplified extraction - in practice you'd need to look at the board
    // For now, assume any capture is worth something
    return 'p'; // Default to pawn value
  }
  
  String? _extractDestination(String move) {
    // Extract destination square from algebraic notation
    final regex = RegExp(r'([a-h][1-8])');
    final match = regex.firstMatch(move);
    return match?.group(1);
  }
}