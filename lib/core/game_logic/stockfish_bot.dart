// lib/core/game_logic/stockfish_bot.dart
import 'dart:async';
import 'dart:math';
import 'package:stockfish/stockfish.dart';
import 'chess_board_state.dart';
import '../../data/models/bot.dart';

class StockfishBot {
  final Bot botConfig;
  late Stockfish _stockfish;
  Completer<String?>? _currentMoveCompleter;
  StreamSubscription? _outputSubscription;
  final Random _random = Random();
  
  StockfishBot({required this.botConfig}) {
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
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Get settings from JSON or use defaults
    final settings = botConfig.engineSettings ?? {};
    
    // Apply skill level
    final skillLevel = settings['skillLevel'] ?? _getDefaultSkillLevel();
    _stockfish.stdin = 'setoption name Skill Level value $skillLevel';
    
    // Apply ELO limiting if specified
    if (settings['limitStrength'] == true) {
      _stockfish.stdin = 'setoption name UCI_LimitStrength value true';
      final uciElo = settings['uciElo'] ?? botConfig.elo;
      _stockfish.stdin = 'setoption name UCI_Elo value $uciElo';
    }
    
    // Apply contempt if specified (affects playing style)
    if (settings['contempt'] != null) {
      _stockfish.stdin = 'setoption name Contempt value ${settings['contempt']}';
    }
    
    // Apply other settings for weaker play
    if (botConfig.elo <= 600) {
      _stockfish.stdin = 'setoption name MultiPV value 1';
      _stockfish.stdin = 'setoption name Threads value 1';
      _stockfish.stdin = 'setoption name Hash value 1';
    }
    
    // Listen to output
    _outputSubscription = _stockfish.stdout.listen((line) {
      // Only log important messages to reduce console spam
      if (line.startsWith('bestmove') || line.contains('error')) {
        print('Stockfish: $line');
      }
      _handleStockfishOutput(line);
    });
    
    _stockfish.stdin = 'isready';
    await Future.delayed(const Duration(milliseconds: 100));
    _stockfish.stdin = 'ucinewgame';
  }
  
  Future<String?> getNextMove(ChessBoardState boardState) async {
    print('DEBUG: ${botConfig.name} thinking...');
    
    // Ensure ready
    if (_stockfish.state.value != StockfishState.ready) {
      print('WARNING: Stockfish not ready, reinitializing...');
      await _initializeStockfish();
    }
    
    // Check for random blunder (for weak bots)
    final settings = botConfig.engineSettings ?? {};
    final blunderChance = settings['randomBlunderChance'] ?? 0.0;
    if (blunderChance > 0 && _random.nextDouble() < blunderChance) {
      print('DEBUG: ${botConfig.name} makes a random move!');
      final allLegalMoves = boardState.getLegalMoves();
      if (allLegalMoves.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: _getMoveTime())); // Simulate thinking
        return allLegalMoves[_random.nextInt(allLegalMoves.length)];
      }
    }
    
    // Cancel pending requests
    if (_currentMoveCompleter != null && !_currentMoveCompleter!.isCompleted) {
      _currentMoveCompleter!.complete(null);
    }
    
    _currentMoveCompleter = Completer<String?>();
    
    // Start fresh position
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
          _stockfish.stdin = 'stop';
          return null;
        },
      );
      
      if (move != null) {
        print('DEBUG: ${botConfig.name} plays: $move');
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
  
  // Fallback skill level based on ELO
  int _getDefaultSkillLevel() {
    final difficulty = botConfig.difficultyLevel;
    switch (difficulty) {
      case 1: return 0;   // Weakest
      case 2: return 3;
      case 3: return 6;
      case 4: return 10;
      case 5: return 15;
      default: return 8;
    }
  }
  
  // Get move time from settings or calculate from difficulty
  int _getMoveTime() {
    final settings = botConfig.engineSettings ?? {};
    if (settings['moveTime'] != null) {
      return settings['moveTime'] as int;
    }
    
    // Fallback based on difficulty
    final difficulty = botConfig.difficultyLevel;
    switch (difficulty) {
      case 1: return 50;
      case 2: return 100;
      case 3: return 300;
      case 4: return 500;
      case 5: return 1000;
      default: return 300;
    }
  }
  
  void dispose() {
    _outputSubscription?.cancel();
    _stockfish.stdin = 'quit';
    _stockfish.dispose();
  }
}