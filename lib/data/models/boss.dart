// lib/data/models/boss.dart
class Boss {
  final String id;
  final String name;
  final int elo;
  final String style;
  final Map<String, dynamic>? engineSettings;
  final String? startingFen;
  final Map<int, List<String>>? allowedMoves;
  final int? minMovesForCompletion;
  final bool? allowUndo;

  Boss({
    required this.id,
    required this.name,
    required this.elo,
    required this.style,
    this.engineSettings,
    this.startingFen,
    this.allowedMoves,
    this.minMovesForCompletion,
    this.allowUndo,
  });

  factory Boss.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      throw ArgumentError('Boss.fromJson received empty JSON');
    }

    // Parse allowedMoves if present
    Map<int, List<String>>? allowedMoves;
    if (json['allowedMoves'] != null) {
      final movesJson = json['allowedMoves'] as Map<String, dynamic>;
      allowedMoves = {};
      movesJson.forEach((key, value) {
        final moveNumber = int.parse(key);
        allowedMoves![moveNumber] = List<String>.from(value as List);
      });
    }

    return Boss(
      id: json['id'] as String,
      name: json['name'] as String,
      elo: json['elo'] as int,
      style: json['style'] as String,
      engineSettings: json['engineSettings'] as Map<String, dynamic>?,
      startingFen: json['startingFen'] as String?,
      allowedMoves: allowedMoves,
      minMovesForCompletion: json['minMovesForCompletion'] as int?,
      allowUndo: json['allowUndo'] as bool?,
    );
  }
}
