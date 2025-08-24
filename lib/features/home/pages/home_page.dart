import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chess Trainer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome! 🎯',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a campaign and progress through levels with lessons, puzzles, and bots.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Beginner Campaign'),
              subtitle: const Text('Fundamentals of chess'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/campaign/${AppConstants.defaultCampaignId}'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Intermediate Campaign'),
              subtitle: const Text('Tactics & strategy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/campaign/intermediate'),
            ),
          ),
        ],
      ),
    );
  }
}