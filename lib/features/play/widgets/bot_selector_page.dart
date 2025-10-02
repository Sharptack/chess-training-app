// lib/features/play/widgets/bot_selector_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/bot.dart';
import '../../../state/providers.dart';

class BotSelectorPage extends ConsumerStatefulWidget {
  final String levelId;
  final List<Bot> bots;
  final Function(Bot, bool) onStartGame;
  
  const BotSelectorPage({
    super.key, 
    required this.levelId,
    required this.bots,
    required this.onStartGame,
  });

  @override
  ConsumerState<BotSelectorPage> createState() => _BotSelectorPageState();
}

class _BotSelectorPageState extends ConsumerState<BotSelectorPage> {
  Bot? _selectedBot;
  bool _humanPlaysWhite = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress overview for ALL bots
          _buildOverallProgress(),
          const SizedBox(height: 24),
          
          Text(
            'Select Your Game',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Bot list with individual progress
          Expanded(
            child: ListView.builder(
              itemCount: widget.bots.length,
              itemBuilder: (context, index) {
                final bot = widget.bots[index];
                return _buildBotCard(bot);
              },
            ),
          ),
          
          // Color selection
          const SizedBox(height: 16),
          _buildColorSelection(),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedBot != null 
                ? () => widget.onStartGame(_selectedBot!, _humanPlaysWhite)
                : null,
              child: const Text('Start Game'),
            ),
          ),
        ],
      ),
    );
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
    int total = 0;
    for (final bot in widget.bots) {
      final progress = await ref.read(
        botProgressProvider('${widget.levelId}_${bot.id}').future
      );
      total += progress.gamesPlayed;
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