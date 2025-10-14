// lib/features/campaign/pages/campaign_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/providers.dart';
import '../../../core/widgets/locked_badge.dart';
import '../../progress/widgets/progress_badge.dart';

/// Shows all levels within a campaign plus the campaign boss
class CampaignDetailPage extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailPage({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignProvider(campaignId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign'),
      ),
      body: campaignAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading campaign: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(campaignProvider(campaignId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (campaign) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign header
                Text(
                  campaign.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  campaign.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // Levels grid
                Text(
                  'Levels',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: campaign.levelIds.length,
                  itemBuilder: (context, index) {
                    final levelId = campaign.levelIds[index];
                    return _LevelTile(
                      levelId: levelId,
                      levelNumber: index + 1,
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Boss section
                Text(
                  'Campaign Boss',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _BossTile(
                  campaignId: campaignId,
                  boss: campaign.boss,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LevelTile extends ConsumerWidget {
  final String levelId;
  final int levelNumber;

  const _LevelTile({
    required this.levelId,
    required this.levelNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsync = ref.watch(levelProvider(levelId));

    return levelAsync.when(
      loading: () => _buildTileContainer(
        context,
        'Level\n$levelNumber',
        null,
        () {},
      ),
      error: (_, __) => _buildTileContainer(
        context,
        'Level\n$levelNumber',
        null,
        () {},
      ),
      data: (level) {
        // Check if level is unlocked
        final isUnlockedAsync = ref.watch(isLevelUnlockedProvider(levelId));

        return isUnlockedAsync.when(
          loading: () => _buildTileContainer(
            context,
            'Level\n$levelNumber',
            null,
            () {},
          ),
          error: (_, __) => _buildTileContainer(
            context,
            'Level\n$levelNumber',
            null,
            () {},
            isLocked: true,
          ),
          data: (isUnlocked) {
            return _buildTileContainer(
              context,
              'Level\n$levelNumber',
              null, // TODO: Add progress badge
              isUnlocked
                  ? () => context.push('/level/$levelId')
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete the previous level to unlock!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
              isLocked: !isUnlocked,
            );
          },
        );
      },
    );
  }

  Widget _buildTileContainer(
    BuildContext context,
    String title,
    Widget? badge,
    VoidCallback onTap, {
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (badge != null) Positioned(top: 4, right: 4, child: badge),
          if (isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.lock, color: Colors.white, size: 32),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BossTile extends ConsumerWidget {
  final String campaignId;
  final dynamic boss;

  const _BossTile({
    required this.campaignId,
    required this.boss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check boss unlock requirements
    final unlockRequirementsAsync =
        ref.watch(campaignBossUnlockRequirementsProvider(campaignId));

    return unlockRequirementsAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading boss: ${boss.name}'),
        ),
      ),
      data: (requirements) {
        final isUnlocked = requirements.isUnlocked;

        return GestureDetector(
          onTap: isUnlocked
              ? () => context.push('/campaign/$campaignId/boss')
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete all campaign requirements to unlock the boss!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          child: Card(
            elevation: isUnlocked ? 8 : 2,
            child: Stack(
              children: [
                Opacity(
                  opacity: isUnlocked ? 1.0 : 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    boss.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    'ELO: ${boss.elo} • ${boss.style}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isUnlocked) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Requirements:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          _buildRequirement(
                            context,
                            'Complete all lessons',
                            requirements.lessonComplete,
                          ),
                          _buildRequirement(
                            context,
                            'Complete all puzzles',
                            requirements.puzzlesComplete,
                          ),
                          _buildRequirement(
                            context,
                            requirements.playStatus,
                            requirements.playComplete,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequirement(BuildContext context, String text, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: completed ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: completed ? Colors.green : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
