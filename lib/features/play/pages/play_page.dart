// lib/features/play/pages/play_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/chess_board_widget.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/game_logic/game_state.dart';
import '../../../data/models/bot.dart';
import '../../../state/providers.dart';

class PlayPage extends ConsumerStatefulWidget {
  final String levelId;
  
  const PlayPage({super.key, required this.levelId});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage> {
  Bot? _selectedBot;
  bool _humanPlaysWhite = true;
  bool _gameStarted = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateNotifierProvider(widget.levelId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Play - Level ${widget.levelId}'),
        actions: [
          if (gameState != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _restartGame,
              tooltip: 'Restart Game',
            ),
        ],
      ),
      body: gameState == null 
        ? _buildGameSetup()
        : _buildActiveGame(gameState),
    );
  }

  Widget _buildGameSetup() {
    final asyncBots = ref.watch(botsProvider);
    
    return AsyncValueView(
      asyncValue: asyncBots,
      data: (bots) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Opponent',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Bot selection
            Expanded(
              child: ListView.builder(
                itemCount: bots.length,
                itemBuilder: (context, index) {
                  final bot = bots[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getDifficultyColor(bot.difficultyLevel),
                        child: Text(
                          bot.difficultyLevel.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(bot.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ELO: ${bot.elo} • Style: ${bot.style}'),
                          if (bot.weaknesses.isNotEmpty)
                            Text(
                              'Weaknesses: ${bot.weaknesses.join(", ")}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      trailing: _selectedBot?.id == bot.id
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                      onTap: () {
                        setState(() {
                          _selectedBot = bot;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            
            // Color selection
            const SizedBox(height: 16),
            Text(
              'Play as',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    selected: _humanPlaysWhite,
                    label: const Text('White'),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _humanPlaysWhite = true;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    selected: !_humanPlaysWhite,
                    label: const Text('Black'),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _humanPlaysWhite = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedBot != null ? _startGame : null,
                child: const Text('Start Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGame(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Game info header
          _buildGameHeader(gameState),
          
          const SizedBox(height: 16),
          
          // Chess board
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = (constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight) - 32;
                  
                  return ChessBoardWidget(
                    boardState: gameState.boardState,
                    size: size,
                    onMoveMade: (move) { 
                        gameState.onHumanMove(move);
                    },
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
          
          const SizedBox(height: 16),
          
          // Game controls and status
          _buildGameControls(gameState),
        ],
      ),
    );
  }

  Widget _buildGameHeader(GameState gameState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gameState.humanPlaysWhite ? 'You (White)' : 'You (Black)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Human',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Text('vs', style: Theme.of(context).textTheme.titleLarge),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      gameState.humanPlaysWhite 
                        ? '${gameState.botConfig.name} (Black)'
                        : '${gameState.botConfig.name} (White)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'ELO ${gameState.botConfig.elo}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Game status
            _buildGameStatus(gameState),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStatus(GameState gameState) {
    print('DEBUG UI: _buildGameStatus called, status: ${gameState.status}');

    String statusText;
    Color statusColor;

    switch (gameState.status) {
      case GameStatus.waitingForHuman:
        statusText = 'Your turn';
        statusColor = Colors.blue;
        break;
      case GameStatus.waitingForBot:
        statusText = '${gameState.botConfig.name} is thinking...';
        statusColor = Colors.orange;
        break;
      case GameStatus.humanWin:
        statusText = 'You won! ${gameState.gameOverReason}';
        statusColor = Colors.green;
        break;
      case GameStatus.botWin:
        statusText = '${gameState.botConfig.name} won! ${gameState.gameOverReason}';
        statusColor = Colors.red;
        break;
      case GameStatus.draw:
        statusText = 'Draw! ${gameState.gameOverReason}';
        statusColor = Colors.grey;
        break;
      default:
        statusText = 'Game not started';
        statusColor = Colors.grey;
    }
  print('DEBUG UI: Displaying status: $statusText');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (gameState.status == GameStatus.waitingForBot)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          if (gameState.status == GameStatus.waitingForBot)
            const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameControls(GameState gameState) {
    return Row(
      children: [
        // Move log button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showMoveLog(gameState),
            icon: const Icon(Icons.list),
            label: Text('Moves (${gameState.moveLog.length})'),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Resign button (only if game is active)
        if (gameState.status == GameStatus.waitingForHuman ||
            gameState.status == GameStatus.waitingForBot)
          ElevatedButton.icon(
            onPressed: () => _showResignDialog(gameState),
            icon: const Icon(Icons.flag),
            label: const Text('Resign'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1: return Colors.green;
      case 2: return Colors.lightGreen;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      case 5: return Colors.deepPurple;
      default: return Colors.grey;
    }
  }

  void _startGame() {
    if (_selectedBot == null) return;
    
    ref.read(gameStateNotifierProvider(widget.levelId).notifier)
        .startGame(
          bot: _selectedBot!,
          humanPlaysWhite: _humanPlaysWhite,
        );
    
    setState(() {
      _gameStarted = true;
    });
  }

  void _restartGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Game'),
        content: const Text('Are you sure you want to restart this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameStateNotifierProvider(widget.levelId).notifier)
                  .endGame();
              setState(() {
                _gameStarted = false;
                _selectedBot = null;
              });
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showResignDialog(GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resign Game'),
        content: const Text('Are you sure you want to resign this game?'),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  void _showMoveLog(GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move History'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: gameState.moveLog.isEmpty
            ? const Center(child: Text('No moves yet'))
            : ListView.builder(
                itemCount: gameState.moveLog.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 12,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    title: Text(
                      gameState.moveLog[index],
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}