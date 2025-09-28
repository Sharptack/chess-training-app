// lib/data/models/bot.dart
import 'package:equatable/equatable.dart';

class Bot extends Equatable {
  final String id;
  final String name;
  final int elo;
  final String style;
  final List<String> weaknesses;
  final Map<String, dynamic>? engineSettings;


  const Bot({
    required this.id,
    required this.name,
    required this.elo,
    required this.style,
    this.weaknesses = const [],
    this.engineSettings,
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: json['id'] as String,
      name: json['name'] as String,
      elo: json['elo'] as int,
      style: json['style'] as String,
      weaknesses: json['weaknesses'] != null 
          ? List<String>.from(json['weaknesses'] as List)
          : [],
          engineSettings: json['engineSettings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'elo': elo,
      'style': style,
      'weaknesses': weaknesses,
      'engineSettings': engineSettings,
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
  List<Object?> get props => [id, name, elo, style, weaknesses, engineSettings];
}