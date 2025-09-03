import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LevelPage extends StatelessWidget {
  final String levelId;
  const LevelPage({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Level $levelId')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _LevelTile(
            title: 'Lesson',
            route: '/level/$levelId/lesson', // videoId can be handled in LessonPage
          ),
          _LevelTile(
            title: 'Puzzles',
            route: '/level/$levelId/puzzles',
          ),
          _LevelTile(
            title: 'Play',
            route: '/level/$levelId/play',
          ),
          _LevelTile(
            title: 'Boss',
            route: '/level/$levelId/boss',
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final String title;
  final String route;

  const _LevelTile({required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}