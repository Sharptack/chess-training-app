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
    
    // Apply skill level (clamp to valid range -20 to +20)
    final skillLevel = (settings['skillLevel'] ?? _getDefaultSkillLevel()).clamp(-20, 20);
    _stockfish.stdin = 'setoption name Skill Level value $skillLevel';

    // Apply ELO limiting if specified (only for bots >= 1320 ELO)
    if (settings['limitStrength'] == true) {
      final uciElo = settings['uciElo'] ?? botConfig.elo;
      // UCI_Elo minimum is ~1320, ignore if below that
      if (uciElo >= 1320) {
        _stockfish.stdin = 'setoption name UCI_LimitStrength value true';
        _stockfish.stdin = 'setoption name UCI_Elo value $uciElo';
      }
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
    // Ensure ready
    if (_stockfish.state.value != StockfishState.ready) {
      await _initializeStockfish();
    }

    // Check for random blunder (for weak bots)
    final settings = botConfig.engineSettings ?? {};
    final blunderChance = settings['randomBlunderChance'] ?? 0.0;
    if (blunderChance > 0 && _random.nextDouble() < blunderChance) {
      final allLegalMoves = boardState.getLegalMoves();
      if (allLegalMoves.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: _getMoveTime()));
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
          _stockfish.stdin = 'stop';
          return null;
        },
      );

      return move;
    } catch (e) {
      return null;
    }
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
      case 1: return -10;  // Much weaker for true beginners
      case 2: return -5;   // Still weak but slightly better
      case 3: return 0;    // Occasional mistakes
      case 4: return 8;    // Competent
      case 5: return 15;   // Strong
      default: return 0;
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