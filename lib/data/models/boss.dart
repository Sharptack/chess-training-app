// lib/data/models/boss.dart
class Boss {
  final String id;
  final String name;
  final int elo;
  final String style;
  final Map<String, dynamic>? engineSettings;

  Boss({
    required this.id,
    required this.name,
    required this.elo,
    required this.style,
    this.engineSettings,
  });

  factory Boss.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      throw ArgumentError('Boss.fromJson received empty JSON');
    }
    return Boss(
      id: json['id'] as String,
      name: json['name'] as String,
      elo: json['elo'] as int,
      style: json['style'] as String,
      engineSettings: json['engineSettings'] as Map<String, dynamic>?,
    );
  }
}
