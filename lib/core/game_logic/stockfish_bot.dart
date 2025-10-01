// lib/core/game_logic/stockfish_bot.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:stockfish/stockfish.dart';
import 'chess_board_state.dart';
import '../../data/models/bot.dart';
import '../constants.dart';

class StockfishBot {
  final Bot botConfig;
  Stockfish? _stockfish;
  Completer<String?>? _currentMoveCompleter;
  StreamSubscription? _outputSubscription;
  final Random _random = Random();
  bool _initializationFailed = false;
  String? _lastError;

  StockfishBot({required this.botConfig}) {
    _initializeStockfish();
  }

  Future<void> _initializeStockfish() async {
    try {
      _stockfish = Stockfish();

      // Wait for engine to be ready with timeout
      final readyTimeout = DateTime.now().add(Duration(seconds: GameConstants.stockfishInitTimeoutSeconds));
      while (_stockfish!.state.value != StockfishState.ready) {
        if (DateTime.now().isAfter(readyTimeout)) {
          throw TimeoutException('Stockfish failed to initialize within $GameConstants.stockfishInitTimeoutSeconds seconds');
        }
        await Future.delayed(Duration(milliseconds: GameConstants.stockfishReadyCheckIntervalMs));
      }

      // Send UCI initialization
      _stockfish!.stdin = 'uci';
      await Future.delayed(Duration(milliseconds: GameConstants.stockfishUciDelayMs));
    
      // Get settings from JSON or use defaults
      final settings = botConfig.engineSettings ?? {};

      // Apply skill level (clamp to valid range)
      final skillLevel = (settings['skillLevel'] ?? _getDefaultSkillLevel())
          .clamp(GameConstants.stockfishMinSkillLevel, GameConstants.stockfishMaxSkillLevel);
      _stockfish!.stdin = 'setoption name Skill Level value $skillLevel';

      // Apply ELO limiting if specified
      if (settings['limitStrength'] == true) {
        final uciElo = settings['uciElo'] ?? botConfig.elo;
        // UCI_Elo minimum is GameConstants.stockfishMinUciElo, ignore if below that
        if (uciElo >= GameConstants.stockfishMinUciElo) {
          _stockfish!.stdin = 'setoption name UCI_LimitStrength value true';
          _stockfish!.stdin = 'setoption name UCI_Elo value $uciElo';
        }
      }

      // Apply contempt if specified (affects playing style)
      if (settings['contempt'] != null) {
        _stockfish!.stdin = 'setoption name Contempt value ${settings['contempt']}';
      }

      // Apply other settings for weaker play
      if (botConfig.elo <= GameConstants.weakBotEloThreshold) {
        _stockfish!.stdin = 'setoption name MultiPV value 1';
        _stockfish!.stdin = 'setoption name Threads value 1';
        _stockfish!.stdin = 'setoption name Hash value 1';
      }

      // Listen to output
      _outputSubscription = _stockfish!.stdout.listen((line) {
        if (line.startsWith('bestmove') || line.contains('error')) {
          if (kDebugMode) {
            print('Stockfish: $line');
          }
        }
        _handleStockfishOutput(line);
      });

      _stockfish!.stdin = 'isready';
      await Future.delayed(Duration(milliseconds: GameConstants.stockfishIsReadyDelayMs));
      _stockfish!.stdin = 'ucinewgame';

      if (kDebugMode) {
        print('Stockfish initialized successfully for bot: ${botConfig.name}');
      }
    } catch (e, stackTrace) {
      _initializationFailed = true;
      _lastError = e.toString();
      if (kDebugMode) {
        print('ERROR: Stockfish initialization failed for bot ${botConfig.name}: $e');
        print('StackTrace: $stackTrace');
      }
      // Clean up if partially initialized
      _outputSubscription?.cancel();
      _stockfish?.dispose();
      _stockfish = null;
    }
  }

  /// Check if Stockfish is available and working
  bool get isAvailable => !_initializationFailed && _stockfish != null;

  /// Get error message if initialization failed
  String? get errorMessage => _lastError;
  
  Future<String?> getNextMove(ChessBoardState boardState) async {
    // If initialization failed, return null (caller should handle fallback)
    if (_initializationFailed || _stockfish == null) {
      if (kDebugMode) {
        print('Stockfish not available, returning null move');
      }
      return null;
    }

    try {
      // Ensure ready
      if (_stockfish!.state.value != StockfishState.ready) {
        await _initializeStockfish();
        // Check again after retry
        if (_initializationFailed || _stockfish == null) {
          return null;
        }
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
      _stockfish!.stdin = 'ucinewgame';
      await Future.delayed(Duration(milliseconds: GameConstants.stockfishPositionDelayMs));

      // Send current position
      final fen = boardState.fen;
      _stockfish!.stdin = 'position fen $fen';
      await Future.delayed(Duration(milliseconds: GameConstants.stockfishPositionDelayMs));

      // Request move
      final moveTime = _getMoveTime();
      _stockfish!.stdin = 'go movetime $moveTime';

      // Wait with timeout
      final move = await _currentMoveCompleter!.future.timeout(
        Duration(milliseconds: moveTime + GameConstants.stockfishMoveTimeoutBuffer),
        onTimeout: () {
          _stockfish?.stdin = 'stop';
          return null;
        },
      );

      return move;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR in getNextMove: $e');
      }
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
  
  // Fallback skill level based on difficulty
  int _getDefaultSkillLevel() {
    final difficulty = botConfig.difficultyLevel;
    switch (difficulty) {
      case 1: return GameConstants.stockfishSkillLevelDifficulty1;
      case 2: return GameConstants.stockfishSkillLevelDifficulty2;
      case 3: return GameConstants.stockfishSkillLevelDifficulty3;
      case 4: return GameConstants.stockfishSkillLevelDifficulty4;
      case 5: return GameConstants.stockfishSkillLevelDifficulty5;
      default: return GameConstants.stockfishSkillLevelDifficulty3;
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
      case 1: return GameConstants.moveTimeDifficulty1;
      case 2: return GameConstants.moveTimeDifficulty2;
      case 3: return GameConstants.moveTimeDifficulty3;
      case 4: return GameConstants.moveTimeDifficulty4;
      case 5: return GameConstants.moveTimeDifficulty5;
      default: return GameConstants.moveTimeDefault;
    }
  }
  
  void dispose() {
    _outputSubscription?.cancel();
    if (_stockfish != null) {
      try {
        _stockfish!.stdin = 'quit';
        _stockfish!.dispose();
      } catch (e) {
        if (kDebugMode) {
          print('Error disposing Stockfish: $e');
        }
      }
    }
  }
}