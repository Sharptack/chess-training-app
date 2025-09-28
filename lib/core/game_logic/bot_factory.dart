// lib/core/game_logic/bot_factory.dart
import 'mock_bot.dart';
import 'stockfish_bot.dart';
import 'chess_board_state.dart';

/// Factory for creating chess bots
class BotFactory {
  static const bool USE_STOCKFISH = true; // Toggle this for testing
  
  /// Create a bot with the specified difficulty (1-5)
  static ChessBot createBot({required int difficulty}) {
    if (USE_STOCKFISH) {
      return StockfishBotAdapter(difficulty: difficulty);
    } else {
      return MockBotAdapter(difficulty: difficulty);
    }
  }
}

/// Common interface for all bots
abstract class ChessBot {
  Future<String?> getNextMove(ChessBoardState boardState);
  void dispose();
}

/// Adapter for StockfishBot
class StockfishBotAdapter implements ChessBot {
  final StockfishBot _bot;
  
  StockfishBotAdapter({required int difficulty}) 
    : _bot = StockfishBot(difficulty: difficulty);
  
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