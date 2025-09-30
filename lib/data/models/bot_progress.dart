// lib/data/models/bot_progress.dart
class BotProgress {
  final String levelId;
  final String botId;
  final int gamesPlayed;
  final int gamesWon;
  final int gamesRequired;
  final DateTime? firstPlayedAt;
  final DateTime? lastPlayedAt;

  BotProgress({
    required this.levelId,
    required this.botId,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    required this.gamesRequired,
    this.firstPlayedAt,
    this.lastPlayedAt,
  });

  bool get isComplete => gamesPlayed >= gamesRequired;

  factory BotProgress.fromJson(Map<String, dynamic> json) {
    return BotProgress(
      levelId: json['levelId'] as String,
      botId: json['botId'] as String,
      gamesPlayed: json['gamesPlayed'] ?? 0,
      gamesWon: json['gamesWon'] ?? 0,
      gamesRequired: json['gamesRequired'] ?? 3,
      firstPlayedAt: json['firstPlayedAt'] != null
          ? DateTime.tryParse(json['firstPlayedAt'])
          : null,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.tryParse(json['lastPlayedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'botId': botId,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'gamesRequired': gamesRequired,
      'firstPlayedAt': firstPlayedAt?.toIso8601String(),
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }
}