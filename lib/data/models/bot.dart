// lib/data/models/bot.dart
import 'package:equatable/equatable.dart';

class Bot extends Equatable {
  final String id;
  final String name;
  final int elo;
  final String style;
  final List<String> weaknesses;
  final Map<String, dynamic>? engineSettings;
  final String? startingFen;
  final Map<int, List<String>>? allowedMoves; // Move number -> list of allowed SAN moves
  final int minMovesForCompletion;
  final bool allowUndo; // Whether undo button is available for this game

  const Bot({
    required this.id,
    required this.name,
    required this.elo,
    required this.style,
    this.weaknesses = const [],
    this.engineSettings,
    this.startingFen,
    this.allowedMoves,
    this.minMovesForCompletion = 10,
    this.allowUndo = true, // Default: undo is allowed
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
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

    return Bot(
      id: json['id'] as String,
      name: json['name'] as String,
      elo: json['elo'] as int,
      style: json['style'] as String,
      weaknesses: json['weaknesses'] != null
          ? List<String>.from(json['weaknesses'] as List)
          : [],
      engineSettings: json['engineSettings'] as Map<String, dynamic>?,
      startingFen: json['startingFen'] as String?,
      allowedMoves: allowedMoves,
      minMovesForCompletion: json['minMovesForCompletion'] as int? ?? 10,
      allowUndo: json['allowUndo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert allowedMoves back to JSON format
    Map<String, dynamic>? movesJson;
    if (allowedMoves != null) {
      movesJson = {};
      allowedMoves!.forEach((key, value) {
        movesJson![key.toString()] = value;
      });
    }

    return {
      'id': id,
      'name': name,
      'elo': elo,
      'style': style,
      'weaknesses': weaknesses,
      'engineSettings': engineSettings,
      'startingFen': startingFen,
      'allowedMoves': movesJson,
      'minMovesForCompletion': minMovesForCompletion,
      'allowUndo': allowUndo,
    };
  }

  /// Convert ELO to difficulty level (1-5)
  int get difficultyLevel {
    if (elo <= 400) return 1;
    if (elo <= 600) return 2; 
    if (elo <= 800) return 3;
    if (elo <= 1000) return 4;
    return 5;
  }

  @override
  List<Object?> get props => [id, name, elo, style, weaknesses, engineSettings, startingFen, allowedMoves, minMovesForCompletion, allowUndo];
}