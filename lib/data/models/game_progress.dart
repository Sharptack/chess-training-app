// lib/data/models/game_progress.dart
class GameProgress {
  final String gameId;
  final int completions;
  final int completionsRequired;
  final DateTime? firstPlayedAt;
  final DateTime? lastPlayedAt;

  GameProgress({
    required this.gameId,
    this.completions = 0,
    required this.completionsRequired,
    this.firstPlayedAt,
    this.lastPlayedAt,
  });

  bool get isComplete => completions >= completionsRequired;

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      gameId: json['gameId'] as String,
      completions: json['completions'] ?? 0,
      completionsRequired: json['completionsRequired'] ?? 1,
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
      'gameId': gameId,
      'completions': completions,
      'completionsRequired': completionsRequired,
      'firstPlayedAt': firstPlayedAt?.toIso8601String(),
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }
}
