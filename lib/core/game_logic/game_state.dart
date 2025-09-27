// lib/core/game_logic/game_state.dart
import 'package:flutter/foundation.dart';
import 'chess_board_state.dart';
import 'mock_bot.dart';
import '../../data/models/bot.dart';

enum GameStatus {
  waitingForHuman,
  waitingForBot, 
  humanWin,
  botWin,
  draw,
  notStarted,
}

/// Manages a human vs bot chess game
class GameState extends ChangeNotifier {
  final ChessBoardState _boardState;
  final MockBot _bot;
  final Bot _botConfig;
  final bool _humanPlaysWhite;
  
  GameStatus _status = GameStatus.notStarted;
  String? _gameOverReason;
  final List<String> _moveLog = [];
  
  GameState({
    required ChessBoardState boardState,
    required Bot botConfig,
    required bool humanPlaysWhite,
  }) : _boardState = boardState,
       _bot = MockBot(difficulty: botConfig.difficultyLevel),
       _botConfig = botConfig,
       _humanPlaysWhite = humanPlaysWhite {
    
    // Listen to board state changes
    _boardState.addListener(_onBoardStateChanged);
    
    // Start the game
    _startGame();
  }
  
  @override
  void dispose() {
    _boardState.removeListener(_onBoardStateChanged);
    super.dispose();
  }
  
  // === GETTERS ===
  
  GameStatus get status => _status;
  String? get gameOverReason => _gameOverReason;
  ChessBoardState get boardState => _boardState;
  Bot get botConfig => _botConfig;
  bool get humanPlaysWhite => _humanPlaysWhite;
  List<String> get moveLog => List.unmodifiable(_moveLog);
  
  bool get isHumanTurn => (_humanPlaysWhite && _boardState.isWhiteTurn) ||
                         (!_humanPlaysWhite && !_boardState.isWhiteTurn);
  
  bool get isBotTurn => !isHumanTurn;
  
  // === GAME CONTROL ===
  
  void _startGame() {
  _boardState.reset();
  _status = _humanPlaysWhite ? GameStatus.waitingForHuman : GameStatus.waitingForBot;
  _gameOverReason = null;
  _moveLog.clear();
  
  print('DEBUG GameState: Game started');
  print('DEBUG GameState: humanPlaysWhite: $_humanPlaysWhite');
  print('DEBUG GameState: Initial status: $_status');
  
  notifyListeners();
  
  // If bot plays white, make the first move
  if (!_humanPlaysWhite) {
    print('DEBUG GameState: Bot plays white, making first move');
    _makeBotMove();
  } else {
    print('DEBUG GameState: Human plays white, waiting for human move');
  }
}
  
  void restart() {
    _startGame();
  }
  
  void resignGame() {
    _status = GameStatus.botWin;
    _gameOverReason = 'Human resigned';
    notifyListeners();
  }
  
  // === MOVE HANDLING ===
  
  /// Called when human makes a move
  /// Called when human makes a move
void onHumanMove(String moveNotation) {
  print('DEBUG GameState: onHumanMove called with: $moveNotation');
  print('DEBUG GameState: Current status: $_status');
  print('DEBUG GameState: humanPlaysWhite: $_humanPlaysWhite');
  print('DEBUG GameState: isHumanTurn: $isHumanTurn');
  
  if (_status != GameStatus.waitingForHuman) {
    print('DEBUG GameState: EARLY RETURN - status is not waitingForHuman');
    return;
  }
  
  print('DEBUG GameState: Processing human move...');
  
  // Record the move
  _moveLog.add('${_moveLog.length ~/ 2 + 1}. $moveNotation');
  
  // Check game state after human move
  if (_checkGameOver()) {
    print('DEBUG GameState: Game over detected');
    return;
  }
  
  // Switch to bot turn
  print('DEBUG GameState: Switching to bot turn');
  _status = GameStatus.waitingForBot;
  notifyListeners();
  
  // Make bot move after a brief delay
  print('DEBUG GameState: Calling _makeBotMove()');
  _makeBotMove();
}
  
  Future<void> _makeBotMove() async {
  print('DEBUG: _makeBotMove started, status: $_status');
  
  if (_status != GameStatus.waitingForBot) return;
  
  final botMove = await _bot.getNextMove(_boardState);
  print('DEBUG: Bot selected move: $botMove');
  
  if (botMove == null) {
    print('DEBUG: Bot has no legal moves');
    _checkGameOver();
    return;
  }
  
  // Make the bot's move
  final success = _boardState.makeSanMove(botMove);
  print('DEBUG: Bot move success: $success');
  
  if (success) {
    // Record bot move
    final moveNumber = _moveLog.length ~/ 2 + 1;
    final isOddMove = _moveLog.length % 2 == 0;
    
    if (isOddMove) {
      _moveLog.add('$moveNumber. $botMove');
    } else {
      // Add to existing move pair
      _moveLog[_moveLog.length - 1] += ' $botMove';
    }
    
    // Check game state after bot move
    if (_checkGameOver()) {
      print('DEBUG: Game over after bot move');
      return;
    }
    
    // Switch to human turn
    print('DEBUG: Switching status from $_status to waitingForHuman');
    _status = GameStatus.waitingForHuman;
    notifyListeners();
    print('DEBUG: Status updated and notified');
  }
}
  
  bool _checkGameOver() {
    if (_boardState.isCheckmate) {
      _status = isHumanTurn ? GameStatus.botWin : GameStatus.humanWin;
      _gameOverReason = 'Checkmate';
    } else if (_boardState.isStalemate) {
      _status = GameStatus.draw;
      _gameOverReason = 'Stalemate';
    } else if (_boardState.isDraw) {
      _status = GameStatus.draw;
      _gameOverReason = 'Draw by repetition or 50-move rule';
    } else {
      return false; // Game continues
    }
    
    notifyListeners();
    return true;
  }
  
  void _onBoardStateChanged() {
    // Board state changed, notify listeners
    notifyListeners();
  }
}