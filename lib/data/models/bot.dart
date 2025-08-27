import 'package:equatable/equatable.dart';

class Bot extends Equatable {
  final String id;
  final String name;
  final int elo;
  final String style;

  const Bot({
    required this.id,
    required this.name,
    required this.elo,
    required this.style,
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: json['id'] as String,
      name: json['name'] as String,
      elo: json['elo'] as int,
      style: json['style'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'elo': elo,
      'style': style,
    };
  }

  @override
  List<Object?> get props => [id, name, elo, style];
}
