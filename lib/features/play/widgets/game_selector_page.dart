// lib/features/play/widgets/game_selector_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/bot.dart';
import '../../../data/models/game.dart';
import '../../../state/providers.dart';
import '../../games/check_checkmate/pages/check_checkmate_page.dart';

class GameSelectorPage extends ConsumerStatefulWidget {
  final String levelId;
  final List<Bot> bots;
  final List<Game> games;
  final Function(Bot, bool) onStartGame;

  const GameSelectorPage({
    super.key,
    required this.levelId,
    required this.bots,
    this.games = const [],
    required this.onStartGame,
  });

  @override
  ConsumerState<GameSelectorPage> createState() => _GameSelectorPageState();
}

class _GameSelectorPageState extends ConsumerState<GameSelectorPage> {
  Bot? _selectedBot;
  Game? _selectedGame;
  bool _humanPlaysWhite = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress overview for ALL games
          _buildOverallProgress(),
          const SizedBox(height: 24),

          Text(
            'Select Your Game',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Game list with individual progress
          Expanded(
            child: ListView.builder(
              itemCount: widget.games.isNotEmpty ? widget.games.length : widget.bots.length,
              itemBuilder: (context, index) {
                // Use new games array if available, otherwise fallback to bots
                if (widget.games.isNotEmpty) {
                  final game = widget.games[index];
                  return _buildGameCard(game);
                } else {
                  // Legacy: just show bots
                  final bot = widget.bots[index];
                  return _buildBotCard(bot);
                }
              },
            ),
          ),

          // Color selection (only for bot games)
          if (_selectedBot != null || (_selectedGame?.type == GameType.bot)) ...[
            const SizedBox(height: 16),
            _buildColorSelection(),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedBot != null || _selectedGame != null)
                ? _handleStartGame
                : null,
              child: const Text('Start Game'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStartGame() {
    if (_selectedGame != null) {
      _launchGame(_selectedGame!);
    } else if (_selectedBot != null) {
      widget.onStartGame(_selectedBot!, _humanPlaysWhite);
    }
  }

  void _launchGame(Game game) {
    switch (game.type) {
      case GameType.bot:
        // Find the bot and launch
        final bot = widget.bots.firstWhere(
          (b) => b.id == game.botId,
          orElse: () => throw Exception('Bot not found: ${game.botId}'),
        );
        widget.onStartGame(bot, _humanPlaysWhite);
        break;
      case GameType.checkCheckmate:
        // Navigate to CheckCheckmatePage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckCheckmatePage(
              gameId: game.id,
              levelId: widget.levelId,
              positionIds: game.positionIds ?? [],
              completionsRequired: game.completionsRequired,
            ),
          ),
        );
        break;
    }
  }
  
  Widget _buildOverallProgress() {
    // Show combined progress for all bots, using requiredGames from Level config
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final levelAsync = ref.watch(levelRepositoryProvider).getLevelById(widget.levelId);
                return FutureBuilder(
                  future: levelAsync,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator(minHeight: 8);
                    }
                    final result = snapshot.data;
                    if (result == null || result.isError) {
                      return const Text('Error loading level config');
                    }
                    final level = result.data!;
                    return FutureBuilder<int>(
                      future: _calculateTotalGames(),
                      builder: (context, gamesSnapshot) {
                        final totalGames = gamesSnapshot.data ?? 0;
                        final totalRequired = level.requiredGames * widget.bots.length;
                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value: (totalGames / totalRequired).clamp(0.0, 1.0),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 4),
                            Text('$totalGames / $totalRequired completions'),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBotCard(Bot bot) {
    return Consumer(
      builder: (context, ref, child) {
        return ref.watch(botProgressProvider('${widget.levelId}_${bot.id}')).when(
          data: (progress) {
            return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getDifficultyColor(bot.difficultyLevel),
                child: Text(
                  bot.difficultyLevel.toString(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(bot.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ELO: ${bot.elo} • Style: ${bot.style}'),
                  if (bot.startingFen != null)
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Custom position',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  if (bot.allowedMoves != null)
                    Row(
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'Move restrictions',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  if (progress.gamesPlayed > 0)
                    Text(
                      'Completed: ${progress.gamesPlayed} (${progress.gamesWon} wins)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              trailing: _selectedBot?.id == bot.id
                ? const Icon(Icons.check_circle, color: Colors.green)
                : progress.isComplete 
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => setState(() => _selectedBot = bot),
            ),
          );
        },
        loading: () => const Card(child: ListTile(title: Text('Loading...'))),
        error: (_, __) => Card(child: ListTile(title: Text(bot.name))),
      );
    },
  );
}

  Widget _buildGameCard(Game game) {
    switch (game.type) {
      case GameType.bot:
        return _buildBotGameCard(game);
      case GameType.checkCheckmate:
        return _buildCheckCheckmateGameCard(game);
    }
  }

  Widget _buildBotGameCard(Game game) {
    // Find the bot
    Bot? bot;
    try {
      bot = widget.bots.firstWhere((b) => b.id == game.botId);
    } catch (e) {
      // Bot not found - show error card
      return Card(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.red,
            child: Icon(Icons.error, color: Colors.white),
          ),
          title: Text('Error: Bot ${game.botId} not found'),
          subtitle: const Text('This game cannot be played'),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        // Use bot progress provider for bot games
        return ref.watch(botProgressProvider('${widget.levelId}_${game.botId}')).when(
          data: (progress) {
            return Card(
              child: ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: _getDifficultyColor(bot!.difficultyLevel),
                      child: Text(
                        bot.difficultyLevel.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                title: Text(bot.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${game.gameTypeLabel}'),
                    Text('ELO: ${bot.elo} • Style: ${bot.style}'),
                    if (progress.gamesPlayed > 0)
                      Text(
                        'Completed: ${progress.gamesPlayed}/${game.completionsRequired} (${progress.gamesWon} wins)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                trailing: _selectedGame?.id == game.id
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : progress.isComplete
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => setState(() {
                  _selectedGame = game;
                  _selectedBot = null;
                }),
              ),
            );
          },
          loading: () => const Card(child: ListTile(title: Text('Loading...'))),
          error: (_, __) => Card(child: ListTile(title: Text(game.displayName))),
        );
      },
    );
  }

  Widget _buildCheckCheckmateGameCard(Game game) {
    return Consumer(
      builder: (context, ref, child) {
        return ref.watch(gameProgressProvider(game.id)).when(
          data: (progress) {
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.psychology, color: Colors.white),
                ),
                title: Text(game.displayName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${game.gameTypeLabel}'),
                    Text('${game.positionIds?.length ?? 0} positions'),
                    if (progress.completions > 0)
                      Text(
                        'Completed: ${progress.completions}/${game.completionsRequired}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                trailing: _selectedGame?.id == game.id
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : progress.isComplete
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => setState(() {
                  _selectedGame = game;
                  _selectedBot = null;
                }),
              ),
            );
          },
          loading: () => const Card(child: ListTile(title: Text('Loading...'))),
          error: (_, __) => Card(child: ListTile(title: Text(game.displayName))),
        );
      },
    );
  }

  Widget _buildColorSelection() {
    return Row(
      children: [
        Expanded(
          child: FilterChip(
            selected: _humanPlaysWhite,
            label: const Text('Play as White'),
            onSelected: (selected) {
              if (selected) setState(() => _humanPlaysWhite = true);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilterChip(
            selected: !_humanPlaysWhite,
            label: const Text('Play as Black'),
            onSelected: (selected) {
              if (selected) setState(() => _humanPlaysWhite = false);
            },
          ),
        ),
      ],
    );
  }
  
  Future<int> _calculateTotalGames() async {
    // Get level config to know requiredGames
    final levelResult = await ref.read(levelRepositoryProvider).getLevelById(widget.levelId);
    if (levelResult.isError) return 0;
    final level = levelResult.data!;

    int total = 0;
    for (final bot in widget.bots) {
      final progress = await ref.read(
        botProgressProvider('${widget.levelId}_${bot.id}').future
      );
      // Only count up to requiredGames per bot (cap excess games)
      final cappedGames = progress.gamesPlayed > level.requiredGames
        ? level.requiredGames
        : progress.gamesPlayed;
      total += cappedGames;
    }
    return total;
  }
  
  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1: return Colors.green;
      case 2: return Colors.lightGreen;
      case 3: return Colors.orange;
      case 4: return Colors.deepOrange;
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }
}