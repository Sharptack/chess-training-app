import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/game_view.dart';
import '../../../core/game_logic/game_state.dart';
import '../../../data/models/bot.dart';
import '../../../state/providers.dart';

class BossPage extends ConsumerStatefulWidget {
  final String campaignId;
  const BossPage({super.key, required this.campaignId});

  @override
  ConsumerState<BossPage> createState() => _BossPageState();
}

class _BossPageState extends ConsumerState<BossPage> {
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

    final previousStatus = _lastKnownStatus;
    final currentStatus = gameState.status;

    final wasPlaying = previousStatus == GameStatus.waitingForHuman ||
                      previousStatus == GameStatus.waitingForBot;
    final gameEnded = currentStatus == GameStatus.humanWin ||
                     currentStatus == GameStatus.botWin ||
                     currentStatus == GameStatus.draw;

    if (wasPlaying && gameEnded && gameState.gameCompletedNormally && !_hasRecordedCompletion) {
      _hasRecordedCompletion = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleGameComplete(gameState);
      });
    }

    _lastKnownStatus = currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the game state and listen for changes
    final gameState = ref.watch(gameStateNotifierProvider('boss_${widget.campaignId}'));

    // Set up listener when game state changes
    if (gameState != _currentGameState) {
      _currentGameState?.removeListener(_onGameStateChanged);
      _currentGameState = gameState;
      _currentGameState?.addListener(_onGameStateChanged);
      _lastKnownStatus = gameState?.status;
    }

    // Load campaign data to get boss
    final campaignAsync = ref.watch(campaignProvider(widget.campaignId));

    return campaignAsync.when(
      data: (campaign) {
        final boss = campaign.boss;

        return Scaffold(
          appBar: AppBar(
            title: Text('Boss: ${boss.name}'),
            actions: gameState != null ? [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(
                    '${boss.elo} ELO',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ] : null,
          ),
          body: gameState == null
            ? _buildBossIntro(boss)
            : _buildGame(gameState, boss),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Boss Battle')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Boss Battle')),
        body: Center(child: Text('Error loading boss: $error')),
      ),
    );
  }

  Widget _buildBossIntro(boss) {
    _hasRecordedCompletion = false;
    _lastKnownStatus = null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              boss.name,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '${boss.elo} ELO • ${boss.style.toUpperCase()}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            const Text(
              'Defeat the boss to complete this level!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _startBossBattle(boss, true),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play as White'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _startBossBattle(boss, false),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play as Black'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startBossBattle(boss, bool humanPlaysWhite) {
    // Convert Boss to Bot for game state
    final bossAsBot = Bot(
      id: boss.id,
      name: boss.name,
      elo: boss.elo,
      style: boss.style,
      engineSettings: boss.engineSettings,
      weaknesses: [],
      startingFen: boss.startingFen,
      allowedMoves: boss.allowedMoves,
      minMovesForCompletion: boss.minMovesForCompletion ?? 10,
      allowUndo: boss.allowUndo ?? true,
    );

    ref.read(gameStateNotifierProvider('boss_${widget.campaignId}').notifier)
      .startGame(bot: bossAsBot, humanPlaysWhite: humanPlaysWhite);
  }

  Widget _buildGame(GameState gameState, boss) {
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
        content: const Text('Are you sure you want to resign?'),
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

  String _getStatusText(GameState gameState) {
    switch (gameState.status) {
      case GameStatus.waitingForHuman:
        return 'Your turn';
      case GameStatus.waitingForBot:
        return '${gameState.botConfig.name} is thinking...';
      case GameStatus.humanWin:
        return '🎉 Victory! You defeated the boss!';
      case GameStatus.botWin:
        return '${gameState.botConfig.name} wins. Try again!';
      case GameStatus.draw:
        return 'Draw! Try again to defeat the boss.';
      default:
        return '';
    }
  }

  void _showGameOverOptions(GameState gameState) {
    final won = gameState.status == GameStatus.humanWin;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(won ? '🎉 Boss Defeated!' : 'Game Over'),
        content: Text(
          won
            ? 'Congratulations! You have completed this level.'
            : 'Keep trying! You can defeat this boss.',
        ),
        actions: [
          if (!won)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartBattle();
              },
              child: const Text('Try Again'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to level page
            },
            child: Text(won ? 'Continue' : 'Back to Level'),
          ),
        ],
      ),
    );
  }

  void _restartBattle() {
    _hasRecordedCompletion = false;
    _lastKnownStatus = null;
    ref.read(gameStateNotifierProvider('boss_${widget.campaignId}').notifier).endGame();
  }

  Future<void> _handleGameComplete(GameState gameState) async {
    final won = gameState.status == GameStatus.humanWin;

    print('DEBUG: Boss game completed. Won: $won');

    if (won) {
      // Mark boss as complete
      await markBossCompleted(ref, widget.campaignId);
      print('DEBUG: Boss marked as completed for campaign ${widget.campaignId}');
    }
  }
}
