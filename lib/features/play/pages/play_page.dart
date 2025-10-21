// lib/features/play/pages/play_page.dart (simplified)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/game_view.dart';
import '../../../core/game_logic/game_state.dart';
import '../../../state/providers.dart';
import '../widgets/game_selector_page.dart';

class PlayPage extends ConsumerStatefulWidget {
  final String levelId;
  
  const PlayPage({super.key, required this.levelId});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage> {
  bool _hasRecordedCompletion = false;
  GameStatus? _lastKnownStatus;
  GameState? _currentGameState;

  @override
  void dispose() {
    _currentGameState?.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    final gameState = _currentGameState;
    if (gameState == null) return;

    print('DEBUG PlayPage _onGameStateChanged: status: ${gameState.status}');

    final previousStatus = _lastKnownStatus;
    final currentStatus = gameState.status;

    final wasPlaying = previousStatus == GameStatus.waitingForHuman ||
                      previousStatus == GameStatus.waitingForBot;
    final gameEnded = currentStatus == GameStatus.humanWin ||
                     currentStatus == GameStatus.botWin ||
                     currentStatus == GameStatus.draw;

    print('DEBUG PlayPage: wasPlaying=$wasPlaying, gameEnded=$gameEnded, gameCompletedNormally=${gameState.gameCompletedNormally}, hasRecordedCompletion=$_hasRecordedCompletion');

    if (wasPlaying && gameEnded && gameState.gameCompletedNormally && !_hasRecordedCompletion) {
      // Only record if: (1) human won, OR (2) human lost but met minimum move requirement
      final shouldRecord = gameState.humanWon || gameState.meetsMinMoveRequirement;

      print('DEBUG PlayPage: Game ended. Won: ${gameState.humanWon}, MoveCount: ${gameState.moveCount}, MinRequired: ${gameState.botConfig.minMovesForCompletion}, ShouldRecord: $shouldRecord');

      if (shouldRecord) {
        _hasRecordedCompletion = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleGameComplete(gameState);
        });
      }
    }

    // Update last known status
    _lastKnownStatus = currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateNotifierProvider(widget.levelId));

    // Set up listener when game state changes
    if (gameState != _currentGameState) {
      _currentGameState?.removeListener(_onGameStateChanged);
      _currentGameState = gameState;
      _currentGameState?.addListener(_onGameStateChanged);
      _lastKnownStatus = gameState?.status;
    }
    
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

    // Load level to get the specific bot IDs for this level
    final levelAsync = ref.watch(levelProvider(widget.levelId));
    final botsAsync = ref.watch(botsProvider);

    return levelAsync.when(
      data: (level) {
        return botsAsync.when(
          data: (allBots) {
            // Collect all bot IDs from both playBotIds and games array
            final botIds = <String>{
              ...level.playBotIds,
              ...level.games
                  .where((g) => g.botId != null)
                  .map((g) => g.botId!)
            };

            // Filter bots to only include those specified in the level
            final levelBots = allBots.where((bot) => botIds.contains(bot.id)).toList();

            return GameSelectorPage(
              levelId: widget.levelId,
              bots: levelBots,
              games: level.games, // Pass the games array
              onStartGame: (bot, humanPlaysWhite) {
                ref.read(gameStateNotifierProvider(widget.levelId).notifier)
                  .startGame(bot: bot, humanPlaysWhite: humanPlaysWhite);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error loading bots: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading level: $error')),
    );
  }
  
  Widget _buildGame(GameState gameState) {
    // Listen to game state changes to rebuild GameView
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        return GameView(
          gameState: gameState,
          getStatusText: _getStatusText,
          onGameOverPressed: () => _showGameOverOptions(gameState),
          onResign: () => _confirmResign(gameState),
        );
      },
    );
  }

  void _confirmResign(GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resign Game'),
        content: const Text('Are you sure you want to resign? This will not count toward your progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              gameState.resignGame();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }
  
  void _handleGameComplete(GameState gameState) async {
    print('DEBUG _handleGameComplete: Starting for bot ${gameState.botConfig.id}');

    // Record the game
    final levelResult = await ref.read(levelRepositoryProvider)
      .getLevelById(widget.levelId);

    if (levelResult.isSuccess) {
      final level = levelResult.data!;

      print('DEBUG _handleGameComplete: Recording game. LevelId: ${widget.levelId}, BotId: ${gameState.botConfig.id}, Won: ${gameState.humanWon}, RequiredGames: ${level.requiredGames}');

      await recordBotGameCompleted(
        ref,
        widget.levelId,
        gameState.botConfig.id,
        gameState.humanWon,
        level.requiredGames,
      );

      print('DEBUG _handleGameComplete: Game recorded, invalidating providers');

      // Force refresh
      ref.invalidate(botProgressProvider);
      ref.invalidate(botsProvider);

      if (mounted) {
        setState(() {});
      }

      print('DEBUG _handleGameComplete: Complete');
    } else {
      print('DEBUG _handleGameComplete: ERROR - Failed to load level');
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
              leading: const Icon(Icons.sports_esports),
              title: const Text('Choose Different Game'),
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
      case GameStatus.humanWin:
        return gameState.gameOverReason != null
            ? 'You won! ${gameState.gameOverReason}'
            : 'You won!';
      case GameStatus.botWin:
        return gameState.gameOverReason != null
            ? '${gameState.botConfig.name} won - ${gameState.gameOverReason}'
            : '${gameState.botConfig.name} won';
      case GameStatus.draw:
        return gameState.gameOverReason != null
            ? 'Draw - ${gameState.gameOverReason}'
            : 'Draw';
      default: return '';
    }
  }
}