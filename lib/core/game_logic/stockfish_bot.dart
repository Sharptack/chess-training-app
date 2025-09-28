// lib/core/game_logic/stockfish_bot.dart
import 'dart:async';
import 'package:stockfish/stockfish.dart';
import 'chess_board_state.dart';

class StockfishBot {
  final int difficulty;
  late Stockfish _stockfish;
  Completer<String?>? _currentMoveCompleter;
  StreamSubscription? _outputSubscription;
  
  StockfishBot({required this.difficulty}) {
    assert(difficulty >= 1 && difficulty <= 5, 'Difficulty must be 1-5');
    _initializeStockfish();
  }
  
  Future<void> _initializeStockfish() async {
    _stockfish = Stockfish();
    
    // Wait for engine to be ready
    while (_stockfish.state.value != StockfishState.ready) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Send UCI initialization
    _stockfish.stdin = 'uci';
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Configure skill level
    final skillLevel = _getSkillLevel();
    _stockfish.stdin = 'setoption name Skill Level value $skillLevel';
    
    // Listen to output
    _outputSubscription = _stockfish.stdout.listen((line) {
      print('Stockfish: $line'); // Debug output
      _handleStockfishOutput(line);
    });
    
    _stockfish.stdin = 'isready';
    await Future.delayed(const Duration(milliseconds: 100));
    _stockfish.stdin = 'ucinewgame';
  }
  
  Future<String?> getNextMove(ChessBoardState boardState) async {
    print('DEBUG: Getting move for position: ${boardState.fen}');
    
    // Ensure ready
    if (_stockfish.state.value != StockfishState.ready) {
      print('WARNING: Stockfish not ready, reinitializing...');
      await _initializeStockfish();
    }
    
    // Cancel pending requests
    if (_currentMoveCompleter != null && !_currentMoveCompleter!.isCompleted) {
      _currentMoveCompleter!.complete(null);
    }
    
    _currentMoveCompleter = Completer<String?>();
    
    // CRITICAL: Always start fresh from initial position
    // This prevents position confusion
    _stockfish.stdin = 'ucinewgame';
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Send current position
    final fen = boardState.fen;
    _stockfish.stdin = 'position fen $fen';
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Request move
    final moveTime = _getMoveTime();
    _stockfish.stdin = 'go movetime $moveTime';
    
    // Wait with timeout
    try {
      final move = await _currentMoveCompleter!.future.timeout(
        Duration(milliseconds: moveTime + 2000),
        onTimeout: () {
          print('ERROR: Stockfish timeout!');
          _stockfish.stdin = 'stop'; // Force stop
          return null;
        },
      );
      
      if (move != null) {
        print('DEBUG: Got UCI move: $move');
        // For now, just return the UCI move directly
        // The chess package can handle UCI format
        return move;
      }
    } catch (e) {
      print('ERROR in getNextMove: $e');
    }
    
    return null;
  }
  
  void _handleStockfishOutput(String line) {
    if (line.startsWith('bestmove')) {
      final parts = line.split(' ');
      if (parts.length >= 2) {
        final move = parts[1];
        if (move != '(none)' && _currentMoveCompleter != null && !_currentMoveCompleter!.isCompleted) {
          _currentMoveCompleter!.complete(move);
        }
      }
    }
  }
  
  int _getSkillLevel() {
    switch (difficulty) {
      case 1: return 1;
      case 2: return 5;
      case 3: return 10;
      case 4: return 15;
      case 5: return 20;
      default: return 10;
    }
  }
  
  int _getMoveTime() {
    switch (difficulty) {
      case 1: return 100;
      case 2: return 300;
      case 3: return 500;
      case 4: return 1000;
      case 5: return 1500;
      default: return 500;
    }
  }
  
  void dispose() {
    _outputSubscription?.cancel();
    _stockfish.stdin = 'quit';
    _stockfish.dispose();
  }
}