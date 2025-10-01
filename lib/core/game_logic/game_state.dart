// lib/core/game_logic/game_state.dart
import 'package:flutter/foundation.dart';
import 'chess_board_state.dart';
import '../../data/models/bot.dart';
import 'bot_factory.dart';

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
  final ChessBot _bot;
  final Bot _botConfig;
  final bool _humanPlaysWhite;
  bool _gameCompletedNormally = false;
  
  GameStatus _status = GameStatus.notStarted;
  String? _gameOverReason;
  final List<String> _moveLog = [];
  
  GameState({
    required ChessBoardState boardState,
    required Bot botConfig,
    required bool humanPlaysWhite,
  }) : _boardState = boardState,
       _bot = BotFactory.createBot(botConfig: botConfig),
       _botConfig = botConfig,
       _humanPlaysWhite = humanPlaysWhite {
    
    // Listen to board state changes
    _boardState.addListener(_onBoardStateChanged);
    
    // Start the game
    _startGame();
  }
  
  @override
  void dispose() {
    _bot.dispose(); // Properly dispose of bot
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
  bool get gameCompletedNormally => _gameCompletedNormally;
  bool get humanWon => _status == GameStatus.humanWin;
  
  // === GAME CONTROL ===
  
  void _startGame() {
  _boardState.reset();
  _status = _humanPlaysWhite ? GameStatus.waitingForHuman : GameStatus.waitingForBot;
  _gameOverReason = null;
  _moveLog.clear();

  notifyListeners();

  // If bot plays white, make the first move
  if (!_humanPlaysWhite) {
    _makeBotMove();
  }
}
  
  void restart() {
    _startGame();
  }
  
void resignGame() {
    _gameCompletedNormally = false; // Mark as resigned
    _status = GameStatus.botWin;
    _gameOverReason = 'Human resigned';
    notifyListeners();
  }
  
  // === MOVE HANDLING ===
  
  /// Called when human makes a move
  void onHumanMove(String moveNotation) {
    if (_status != GameStatus.waitingForHuman) {
      return;
    }

    // Record the move
    _moveLog.add('${_moveLog.length ~/ 2 + 1}. $moveNotation');

    // Check game state after human move
    if (_checkGameOver()) {
      return;
    }

    // Switch to bot turn
    _status = GameStatus.waitingForBot;
    notifyListeners();

    // Make bot move
    _makeBotMove();
  }
  
  Future<void> _makeBotMove() async {
    if (_status != GameStatus.waitingForBot) return;

    final botMove = await _bot.getNextMove(_boardState);

    if (botMove == null) {
      _checkGameOver();
      return;
    }

    // Make the bot's move - try SAN first, then UCI
    bool success = _boardState.makeSanMove(botMove);
    if (!success && botMove.length >= 4) {
      // Try as UCI move
      success = _boardState.makeUciMove(botMove);
    }

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
        return;
      }

      // Switch to human turn
      _status = GameStatus.waitingForHuman;
      notifyListeners();
    }
  }
  
  bool _checkGameOver() {
    if (_boardState.isCheckmate) {
      _gameCompletedNormally = true;
      _status = isHumanTurn ? GameStatus.botWin : GameStatus.humanWin;
      _gameOverReason = 'Checkmate';
    } else if (_boardState.isStalemate) {
      _gameCompletedNormally = true;
      _status = GameStatus.draw;
      _gameOverReason = 'Stalemate';
    } else if (_boardState.isDraw) {
      _gameCompletedNormally = true;
      _status = GameStatus.draw;
      _gameOverReason = 'Draw by repetition or 50-move rule';
    } else {
      return false;
    }
    
    notifyListeners();
    return true;
  }
  
  void _onBoardStateChanged() {
    // Board state changed, notify listeners
    notifyListeners();
  }
} // This closes the class