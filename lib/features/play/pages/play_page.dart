// lib/features/play/pages/play_page.dart (simplified)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/game_view.dart';
import '../../../core/game_logic/game_state.dart';
import '../../../state/providers.dart';
import '../widgets/bot_selector_page.dart';

class PlayPage extends ConsumerStatefulWidget {
  final String levelId;
  
  const PlayPage({super.key, required this.levelId});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage> {
  bool _hasRecordedCompletion = false;
  GameStatus? _lastKnownStatus;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateNotifierProvider(widget.levelId));

    // Listen for game completion
    ref.listen(gameStateNotifierProvider(widget.levelId), (previous, current) {
      // Track the last known status, handling null transitions
      GameStatus? previousStatus = previous?.status ?? _lastKnownStatus;

      if (current != null) {
        final wasPlaying = previousStatus == GameStatus.waitingForHuman ||
                          previousStatus == GameStatus.waitingForBot;
        final gameEnded = current.status == GameStatus.humanWin ||
                         current.status == GameStatus.botWin ||
                         current.status == GameStatus.draw;

        if (wasPlaying && gameEnded && current.gameCompletedNormally && !_hasRecordedCompletion) {
          _hasRecordedCompletion = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleGameComplete(current);
          });
        }

        // Update last known status
        _lastKnownStatus = current.status;
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Play - Level ${widget.levelId}'),
        actions: gameState != null ? [
          // Show minimal progress in corner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: FutureBuilder<String>(
                future: _getProgressText(gameState),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ] : null,
      ),
      body: gameState == null 
        ? _buildBotSelector()
        : _buildGame(gameState),
    );
  }
  
  Widget _buildBotSelector() {
    _hasRecordedCompletion = false; // Reset when returning to selector
    _lastKnownStatus = null; // Reset last known status
    final botsAsync = ref.watch(botsProvider);

    return botsAsync.when(
      data: (bots) => BotSelectorPage(
        levelId: widget.levelId,
        bots: bots,
        onStartGame: (bot, humanPlaysWhite) {
          ref.read(gameStateNotifierProvider(widget.levelId).notifier)
            .startGame(bot: bot, humanPlaysWhite: humanPlaysWhite);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
  
  Widget _buildGame(GameState gameState) {
    return GameView(
      gameState: gameState,
      getStatusText: _getStatusText,
      onGameOverPressed: () => _showGameOverOptions(gameState),
    );
  }
  
  void _handleGameComplete(GameState gameState) async {
    // Record the game
    final levelResult = await ref.read(levelRepositoryProvider)
      .getLevelById(widget.levelId);

    if (levelResult.isSuccess) {
      final level = levelResult.data!;

      await recordBotGameCompleted(
        ref,
        widget.levelId,
        gameState.botConfig.id,
        gameState.humanWon,
        level.requiredGames,
      );

      // Force refresh
      ref.invalidate(botProgressProvider);
      ref.invalidate(botsProvider);

      if (mounted) {
        setState(() {});
      }
    }
  }
  
  void _showGameOverOptions(GameState gameState) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              gameState.gameOverReason ?? 'Game Over',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Play Again'),
              onTap: () {
                Navigator.pop(context);
                _hasRecordedCompletion = false; // Reset flag for next game
                gameState.restart();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Choose Different Bot'),
              onTap: () {
                Navigator.pop(context);
                ref.read(gameStateNotifierProvider(widget.levelId).notifier).endGame();
                // Invalidate bot progress to force refresh
                ref.invalidate(botProgressProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Back to Level'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<String> _getProgressText(GameState gameState) async {
    final progress = await ref.read(
      botProgressProvider('${widget.levelId}_${gameState.botConfig.id}').future
    );
    return '${progress.gamesPlayed}/${progress.gamesRequired}';
  }
  
  String _getStatusText(GameState gameState) {
    switch (gameState.status) {
      case GameStatus.waitingForHuman: return 'Your turn';
      case GameStatus.waitingForBot: return 'Bot thinking...';
      case GameStatus.humanWin: return 'You won!';
      case GameStatus.botWin: return '${gameState.botConfig.name} won';
      case GameStatus.draw: return 'Draw';
      default: return '';
    }
  }
}