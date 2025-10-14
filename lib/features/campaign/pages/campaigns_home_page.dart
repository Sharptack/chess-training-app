// lib/features/campaign/pages/campaigns_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/providers.dart';

/// Home screen showing all available campaigns
class CampaignsHomePage extends ConsumerWidget {
  const CampaignsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(allCampaignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Training Campaigns'),
      ),
      body: campaignsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading campaigns: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(allCampaignsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return const Center(
              child: Text('No campaigns available'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];

              // Check if campaign is unlocked (campaign 1 always unlocked)
              final isUnlocked = index == 0; // TODO: implement unlock logic

              return _CampaignCard(
                campaign: campaign,
                isUnlocked: isUnlocked,
                onTap: isUnlocked
                    ? () => context.push('/campaign/${campaign.id}')
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Complete the previous campaign boss to unlock!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final dynamic campaign;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _CampaignCard({
    required this.campaign,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isUnlocked ? 4 : 1,
        child: Stack(
          children: [
            Opacity(
              opacity: isUnlocked ? 1.0 : 0.5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      campaign.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Boss: ${campaign.boss.name}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.layers, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${campaign.levelIds.length} levels',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
