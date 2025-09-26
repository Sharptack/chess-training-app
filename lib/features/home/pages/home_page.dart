// lib/features/home/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../core/constants.dart';
import '../../../data/sources/local/asset_source.dart';

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
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          
          // DEBUG TEST BUTTON FOR LEVEL 2
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Tools',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      const assetSource = AssetSource();
                      
                      print('========================================');
                      print('Testing level 2 loading...');
                      print('========================================');
                      
                      // Test 1: Check if level_0002.json exists
                      try {
                        final result = await assetSource.readJson('assets/data/levels/level_0002.json');
                        if (result.isSuccess) {
                          print('✅ SUCCESS: level_0002.json loaded');
                          print('Level ID: ${result.data?['id']}');
                          print('Title: ${result.data?['title']}');
                          print('Video ID: ${result.data?['lessonVideo']?['id']}');
                          
                          // Show success dialog
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('✅ Level 2 Found!'),
                                content: Text('Level loaded successfully:\n\n'
                                    'ID: ${result.data?['id']}\n'
                                    'Title: ${result.data?['title']}\n'
                                    'Video: ${result.data?['lessonVideo']?['id']}'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } else {
                          print('❌ FAILED: ${result.failure}');
                          
                          // Show error dialog
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('❌ Level 2 Not Found'),
                                content: Text('Error: ${result.failure}'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print('❌ EXCEPTION: $e');
                        
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('❌ Exception'),
                              content: Text('Error: $e'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                      
                      // Test 2: List all level files
                      try {
                        print('\n========================================');
                        print('Checking all level files in assets:');
                        print('========================================');
                        
                        final bundle = DefaultAssetBundle.of(context);
                        final manifestString = await bundle.loadString('AssetManifest.json');
                        final Map<String, dynamic> manifestMap = json.decode(manifestString);
                        
                        final levelFiles = manifestMap.keys
                            .where((path) => path.contains('data/levels/'))
                            .toList();
                        
                        if (levelFiles.isEmpty) {
                          print('❌ No level files found in manifest');
                        } else {
                          print('Found ${levelFiles.length} level files:');
                          for (final path in levelFiles) {
                            print('  ✓ $path');
                          }
                        }
                      } catch (e) {
                        print('Could not list assets: $e');
                      }
                      
                      print('========================================');
                      print('Debug test complete');
                      print('========================================');
                    },
                    child: const Text('Test Level 2 Loading'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click to check if level_0002.json is properly loaded',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Existing test buttons
          ElevatedButton(
            onPressed: () => context.go('/test-chess'),
            child: const Text('Test Chess Board'),
          ),
          ElevatedButton(
            onPressed: () => context.go('/test-chess-package'),
            child: const Text('Test Chess Package'),
          ),
          ElevatedButton(
            onPressed: () => context.go('/chessboard-test'),
            child: const Text('Test Chessboard'),
          ),
        ],
      ),
    );
  }
}