// lib/router/app_router.dart
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
  static const campaign = 'campaign'; // /campaign/:id (campaign detail)
  static const level = 'level';       // /level/:id
  static const lesson = 'lesson';     // /level/:id/lesson
  static const puzzles = 'puzzles';   // /level/:id/puzzles
  static const play = 'play';         // /level/:id/play
  static const boss = 'boss';         // /campaign/:id/boss (moved to campaign level)
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
          // Campaign detail with levels and boss
          GoRoute(
            path: '${Routes.campaign}/:campaignId',
            name: 'campaign',
            builder: (context, state) {
              final campaignId = state.pathParameters['campaignId']!;
              return CampaignPage(campaignId: campaignId);
            },
            routes: [
              // Boss at campaign level
              GoRoute(
                path: Routes.boss,
                name: 'campaign-boss',
                builder: (context, state) {
                  final campaignId = state.pathParameters['campaignId']!;
                  return BossPage(campaignId: campaignId);
                },
              ),
            ],
          ),
          // Level detail with lesson, puzzles, play
          GoRoute(
            path: '${Routes.level}/:levelId',
            name: 'level',
            builder: (context, state) {
              final levelId = state.pathParameters['levelId']!;
              return LevelPage(levelId: levelId);
            },
            routes: [
              GoRoute(
                path: Routes.lesson,
                name: 'lesson',
                builder: (context, state) {
                  final levelId = state.pathParameters['levelId']!;
                  return LessonPage(levelId: levelId);
                },
              ),
              GoRoute(
                path: Routes.puzzles,
                name: 'puzzles',
                builder: (context, state) {
                  final levelId = state.pathParameters['levelId']!;
                  return PuzzlesPage(levelId: levelId);
                },
              ),
              GoRoute(
                path: Routes.play,
                name: 'play',
                builder: (context, state) {
                  final levelId = state.pathParameters['levelId']!;
                  return PlayPage(levelId: levelId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

