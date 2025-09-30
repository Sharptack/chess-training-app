//lib/data/models/progress.dart
class Progress {
  final String levelId;
  final String videoId;
  final bool started;
  final bool completed;
  final DateTime? startedAt;
  final DateTime? completedAt;

  Progress({
    required this.levelId,
    required this.videoId,
    this.started = false,
    this.completed = false,
    this.startedAt,
    this.completedAt,
  });

    Progress copyWith({
    String? levelId,
    String? videoId,
    bool? started,
    bool? completed,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return Progress(
      levelId: levelId ?? this.levelId,
      videoId: videoId ?? this.videoId,
      started: started ?? this.started,
      completed: completed ?? this.completed,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory Progress.fromJson(Map<String, dynamic> json) {
  return Progress(
    levelId: json['levelId'] as String,
    videoId: json['videoId'] as String,
    started: json['started'] ?? false,
    completed: json['completed'] ?? false,
    startedAt: json['startedAt'] != null
        ? DateTime.tryParse(json['startedAt'])
        : null,
    completedAt: json['completedAt'] != null
        ? DateTime.tryParse(json['completedAt'])
        : null,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'started': started,
      'completed': completed,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}