// lib/data/models/level.dart
import 'package:ChessTrainerApp/data/models/video_item.dart';
import 'package:ChessTrainerApp/data/models/game.dart';

class Level {
  final String id;
  final String title;
  final String description;
  final String campaignId;
  final VideoItem lessonVideo;
  final List<String> puzzleIds;
  final List<String> playBotIds; // Deprecated: use games instead
  final int requiredGames; // Deprecated: use games instead
  final List<Game> games; // New games array

  Level({
    required this.id,
    required this.title,
    required this.description,
    required this.campaignId,
    required this.lessonVideo,
    required this.puzzleIds,
    this.playBotIds = const [],
    this.requiredGames = 3,
    this.games = const [],
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      throw ArgumentError('Level.fromJson received empty JSON');
    }

    // Parse lesson video
    final lesson = json['lesson'] as Map<String, dynamic>?;
    if (lesson == null) {
      throw ArgumentError('Missing "lesson" object in JSON');
    }
    final videoJson = lesson['video'] as Map<String, dynamic>?;
    if (videoJson == null) {
      throw ArgumentError('Missing "video" in lesson');
    }
    final lessonVideo = VideoItem.fromJson(videoJson);

    // Parse puzzle IDs
    final puzzleIds = (json['puzzles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // Parse playBot IDs from the "play" object (legacy support)
    final play = json['play'] as Map<String, dynamic>?;
    final playBotIds = (play?['botIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // Parse required games from play object, fallback to root level (legacy support)
    final requiredGames = play?['gamesRequired'] as int? ??
                          json['requiredGames'] as int? ??
                          3;

    // Parse games array (new approach)
    List<Game> games = [];
    if (play?['games'] != null) {
      games = (play!['games'] as List<dynamic>)
          .map((e) => Game.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (playBotIds.isNotEmpty) {
      // Fallback: convert old botIds format to new games format
      games = playBotIds.map((botId) => Game(
        id: 'game_$botId',
        type: GameType.bot,
        botId: botId,
        completionsRequired: requiredGames,
      )).toList();
    }

    return Level(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      campaignId: json['campaignId'] as String,
      lessonVideo: lessonVideo,
      puzzleIds: puzzleIds,
      playBotIds: playBotIds,
      requiredGames: requiredGames,
      games: games,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'campaignId': campaignId,
      'lesson': {
        'video': lessonVideo.toJson(),
      },
      'puzzles': puzzleIds,
      'play': {
        'botIds': playBotIds,
        'gamesRequired': requiredGames,
        'games': games.map((g) => g.toJson()).toList(),
      },
    };
  }
}
