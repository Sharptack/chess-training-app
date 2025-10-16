// lib/data/models/game.dart

enum GameType {
  bot,
  checkCheckmate,
  // Future game types can be added here
}

class Game {
  final String id;
  final GameType type;
  final int completionsRequired;

  // Bot-specific fields
  final String? botId;

  // CheckCheckmate-specific fields
  final List<int>? positionIds;

  Game({
    required this.id,
    required this.type,
    this.completionsRequired = 1,
    this.botId,
    this.positionIds,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final GameType type;

    switch (typeStr) {
      case 'bot':
        type = GameType.bot;
        break;
      case 'check_checkmate':
        type = GameType.checkCheckmate;
        break;
      default:
        throw ArgumentError('Unknown game type: $typeStr');
    }

    return Game(
      id: json['id'] as String,
      type: type,
      completionsRequired: json['completionsRequired'] as int? ?? 1,
      botId: json['botId'] as String?,
      positionIds: (json['positionIds'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    // Convert enum to string format matching JSON
    String typeStr;
    switch (type) {
      case GameType.bot:
        typeStr = 'bot';
        break;
      case GameType.checkCheckmate:
        typeStr = 'check_checkmate';
        break;
    }

    final map = {
      'id': id,
      'type': typeStr,
      'completionsRequired': completionsRequired,
    };

    if (botId != null) {
      map['botId'] = botId!;
    }

    if (positionIds != null) {
      map['positionIds'] = positionIds!;
    }

    return map;
  }

  String get displayName {
    switch (type) {
      case GameType.bot:
        return botId ?? 'Bot Game';
      case GameType.checkCheckmate:
        return 'Check vs Checkmate';
    }
  }

  String get gameTypeLabel {
    switch (type) {
      case GameType.bot:
        return 'Bot';
      case GameType.checkCheckmate:
        return 'Puzzle';
    }
  }
}
