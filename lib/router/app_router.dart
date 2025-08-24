import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/pages/home_page.dart';
import '../features/campaign/pages/campaign_page.dart';
import '../features/level/pages/level_page.dart';
import '../features/lesson/pages/lesson_page.dart';
import '../features/puzzles/pages/puzzles_page.dart';
import '../features/play/pages/play_page.dart';
import '../features/boss/pages/boss_page.dart';

class Routes {
  static const home = '/';
  static const campaign = '/campaign'; // /campaign/:id
  static const level = '/level'; // /level/:id
  static const lesson = 'lesson';
  static const puzzles = 'puzzles';
  static const play = 'play';
  static const boss = 'boss';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'campaign/:id',
            name: 'campaign',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CampaignPage(campaignId: id);
            },
          ),
          GoRoute(
            path: 'level/:id',
            name: 'level',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return LevelPage(levelId: id);
            },
            routes: [
              GoRoute(
                path: Routes.lesson,
                name: 'lesson',
                builder: (context, state) {
                  final levelId = state.pathParameters['id']!;
                  return LessonPage(levelId: levelId);
                },
              ),
              GoRoute(
                path: Routes.puzzles,
                name: 'puzzles',
                builder: (context, state) {
                  final levelId = state.pathParameters['id']!;
                  return PuzzlesPage(levelId: levelId);
                },
              ),
              GoRoute(
                path: Routes.play,
                name: 'play',
                builder: (context, state) {
                  final levelId = state.pathParameters['id']!;
                  return PlayPage(levelId: levelId);
                },
              ),
              GoRoute(
                path: Routes.boss,
                name: 'boss',
                builder: (context, state) {
                  final levelId = state.pathParameters['id']!;
                  return BossPage(levelId: levelId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}