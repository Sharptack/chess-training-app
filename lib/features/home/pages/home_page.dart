// lib/features/home/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../state/providers.dart';

/// Home screen showing all available campaigns
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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

          return LayoutBuilder(
            builder: (context, constraints) {
              // Responsive column count based on screen width
              final columnCount = ResponsiveUtils.getGridColumnCount(
                context,
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
              );

              final spacing = ResponsiveUtils.getSpacing(
                context,
                mobile: 12.0,
                tablet: 16.0,
                desktop: 20.0,
              );

              final padding = ResponsiveUtils.getHorizontalPadding(context);

              return GridView.builder(
                padding: EdgeInsets.all(padding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: 0.8,
                ),
                itemCount: campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = campaigns[index];
                  final previousCampaign = index > 0 ? campaigns[index - 1] : null;

                  return _CampaignCard(
                    campaign: campaign,
                    previousCampaign: previousCampaign,
                    onTap: () => context.push('/campaign/${campaign.id}'),
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

class _CampaignCard extends ConsumerWidget {
  final dynamic campaign;
  final dynamic previousCampaign;
  final VoidCallback onTap;

  const _CampaignCard({
    required this.campaign,
    required this.previousCampaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnlockedAsync = ref.watch(isCampaignUnlockedProvider(campaign.id));
    final completionAsync = ref.watch(campaignLevelCompletionProvider(campaign.id));

    return isUnlockedAsync.when(
      loading: () => _buildCard(context, true, 0, campaign.levelIds.length, null),
      error: (_, __) => _buildCard(context, false, 0, campaign.levelIds.length, null),
      data: (isUnlocked) {
        return completionAsync.when(
          loading: () => _buildCard(context, isUnlocked, 0, campaign.levelIds.length, null),
          error: (_, __) => _buildCard(context, isUnlocked, 0, campaign.levelIds.length, null),
          data: (completion) {
            final completedLevels = completion.$1;
            final totalLevels = completion.$2;

            return _buildCard(
              context,
              isUnlocked,
              completedLevels,
              totalLevels,
              isUnlocked ? onTap : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      previousCampaign != null
                          ? 'Complete ${previousCampaign.title} boss to unlock!'
                          : 'This campaign is locked',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    bool isUnlocked,
    int completedLevels,
    int totalLevels,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isUnlocked ? 4 : 1,
        child: Stack(
          children: [
            Opacity(
              opacity: isUnlocked ? 1.0 : 0.5,
              child: Padding(
                padding: EdgeInsets.all(context.horizontalPadding),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (completedLevels > 0 || isUnlocked) ...[
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                            size: ResponsiveUtils.getIconSize(context, mobile: 18, tablet: 20, desktop: 22)),
                          const SizedBox(width: 4),
                          Text(
                            '$completedLevels / $totalLevels levels',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(Icons.emoji_events,
                          size: ResponsiveUtils.getIconSize(context, mobile: 18, tablet: 20, desktop: 22)),
                        const SizedBox(width: 4),
                        Text(
                          'Boss: ${campaign.boss.name}',
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
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: ResponsiveUtils.getIconSize(context, mobile: 40, tablet: 48, desktop: 56),
                        color: Colors.white,
                      ),
                      if (previousCampaign != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Complete\n${previousCampaign.title}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
