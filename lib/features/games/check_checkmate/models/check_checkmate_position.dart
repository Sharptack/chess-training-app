// lib/features/games/check_checkmate/models/check_checkmate_position.dart

class CheckCheckmatePosition {
  final int id;
  final String fen;
  final String answer; // "check" or "checkmate"
  final String description;

  CheckCheckmatePosition({
    required this.id,
    required this.fen,
    required this.answer,
    required this.description,
  });

  factory CheckCheckmatePosition.fromJson(Map<String, dynamic> json) {
    return CheckCheckmatePosition(
      id: json['id'] as int,
      fen: json['fen'] as String,
      answer: json['answer'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fen': fen,
      'answer': answer,
      'description': description,
    };
  }

  bool isCorrectAnswer(String userAnswer) {
    return answer.toLowerCase() == userAnswer.toLowerCase();
  }
}
