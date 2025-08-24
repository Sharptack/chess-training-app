import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CampaignPage extends StatelessWidget {
  final String campaignId;
  const CampaignPage({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Campaign: $campaignId')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: 9, // placeholder levels
        itemBuilder: (context, index) {
          final levelId = (index + 1).toString().padLeft(4, '0');
          return InkWell(
            onTap: () => context.go('/level/$levelId'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Center(
                child: Text('Level $levelId', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
          );
        },
      ),
    );
  }
}