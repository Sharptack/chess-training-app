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

  const GameView({
    super.key,
    required this.gameState,
    required this.getStatusText,
    this.onGameOverPressed,
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
              Text(getStatusText(gameState)),
              if (_isGameOver && onGameOverPressed != null)
                ElevatedButton(
                  onPressed: onGameOverPressed,
                  child: const Text('Next'),
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
                    onIllegalMove: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Illegal move!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
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
