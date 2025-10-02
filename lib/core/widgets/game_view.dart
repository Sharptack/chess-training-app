// lib/core/widgets/game_view.dart
import 'package:flutter/material.dart';
import '../game_logic/game_state.dart';
import 'chess_board_widget.dart';

/// Shared widget for displaying a chess game in progress
/// Used by both PlayPage and BossPage to show the game board and status
class GameView extends StatelessWidget {
  final GameState gameState;
  final String Function(GameState) getStatusText;
  final VoidCallback? onGameOverPressed;
  final VoidCallback? onResign;

  const GameView({
    super.key,
    required this.gameState,
    required this.getStatusText,
    this.onGameOverPressed,
    this.onResign,
  });

  bool get _isGameOver =>
      gameState.status == GameStatus.humanWin ||
      gameState.status == GameStatus.botWin ||
      gameState.status == GameStatus.draw;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(getStatusText(gameState)),
                    Text(
                      'Moves: ${gameState.moveCount}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_isGameOver && onGameOverPressed != null)
                ElevatedButton(
                  onPressed: onGameOverPressed,
                  child: const Text('Next'),
                )
              else if (!_isGameOver && onResign != null)
                TextButton.icon(
                  onPressed: onResign,
                  icon: const Icon(Icons.flag, size: 16),
                  label: const Text('Resign'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
        ),

        // Move restriction error message
        if (gameState.lastMoveRestrictionError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gameState.lastMoveRestrictionError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Chess board
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = (constraints.maxWidth < constraints.maxHeight
                          ? constraints.maxWidth
                          : constraints.maxHeight) -
                      32;

                  return ChessBoardWidget(
                    boardState: gameState.boardState,
                    size: size,
                    onMoveMade: gameState.onHumanMove,
                    validateMove: gameState.validateMove,
                    onIllegalMove: () {
                      // Don't show snackbar for restriction errors - they're shown in the banner
                      if (gameState.lastMoveRestrictionError == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Illegal move!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
