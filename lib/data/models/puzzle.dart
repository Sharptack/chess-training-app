import 'package:equatable/equatable.dart';

class Puzzle extends Equatable {
  final String id;
  final String fen; // chess position in FEN format
  final List<String> solution; // solution sequence
  final String description;

  const Puzzle({
    required this.id,
    required this.fen,
    required this.solution,
    required this.description,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] as String,
      fen: json['fen'] as String,
      solution: List<String>.from(json['solution'] as List<dynamic>),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fen': fen,
      'solution': solution,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, fen, solution, description];
}
