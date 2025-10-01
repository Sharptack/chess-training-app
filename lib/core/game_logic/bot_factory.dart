// lib/core/game_logic/bot_factory.dart
import 'package:flutter/foundation.dart';
import 'mock_bot.dart';
import 'stockfish_bot.dart';
import 'chess_board_state.dart';
import '../../data/models/bot.dart';

/// Factory for creating chess bots with automatic fallback
class BotFactory {
  static const bool USE_STOCKFISH = true; // Toggle this for testing

  /// Create a bot with the specified difficulty (1-5)
  /// Automatically falls back to MockBot if Stockfish fails
  static ChessBot createBot({required Bot botConfig}) {
    if (USE_STOCKFISH) {
      return StockfishBotWithFallback(botConfig: botConfig);
    } else {
      return MockBotAdapter(difficulty: botConfig.difficultyLevel);
    }
  }
}

/// Common interface for all bots
abstract class ChessBot {
  Future<String?> getNextMove(ChessBoardState boardState);
  void dispose();
}

/// Adapter that tries Stockfish first, falls back to MockBot on failure
class StockfishBotWithFallback implements ChessBot {
  final Bot _botConfig;
  late final StockfishBot _stockfish;
  MockBot? _fallbackBot;
  bool _usingFallback = false;

  StockfishBotWithFallback({required Bot botConfig})
      : _botConfig = botConfig,
        _stockfish = StockfishBot(botConfig: botConfig);

  @override
  Future<String?> getNextMove(ChessBoardState boardState) async {
    // If we're already using fallback, use it
    if (_usingFallback && _fallbackBot != null) {
      return _fallbackBot!.getNextMove(boardState);
    }

    // Try Stockfish first
    final move = await _stockfish.getNextMove(boardState);

    // If Stockfish returned null and hasn't failed yet, check if it failed
    if (move == null && !_stockfish.isAvailable && !_usingFallback) {
      if (kDebugMode) {
        print('⚠️ Stockfish failed for ${_botConfig.name}, switching to MockBot fallback');
        print('Error: ${_stockfish.errorMessage}');
      }

      // Initialize fallback bot
      _usingFallback = true;
      _fallbackBot = MockBot(difficulty: _botConfig.difficultyLevel);

      // Get move from fallback
      return _fallbackBot!.getNextMove(boardState);
    }

    return move;
  }

  @override
  void dispose() {
    _stockfish.dispose();
    // MockBot doesn't need disposal
  }
}

/// Adapter for StockfishBot (direct, without fallback)
class StockfishBotAdapter implements ChessBot {
  final StockfishBot _bot;

  StockfishBotAdapter({required Bot botConfig})
    : _bot = StockfishBot(botConfig: botConfig);

  @override
  Future<String?> getNextMove(ChessBoardState boardState) {
    return _bot.getNextMove(boardState);
  }

  @override
  void dispose() {
    _bot.dispose();
  }
}

/// Adapter for MockBot
class MockBotAdapter implements ChessBot {
  final MockBot _bot;
  
  MockBotAdapter({required int difficulty})
    : _bot = MockBot(difficulty: difficulty);
  
  @override
  Future<String?> getNextMove(ChessBoardState boardState) {
    return _bot.getNextMove(boardState);
  }
  
  @override
  void dispose() {
    // MockBot doesn't need disposal
  }
}