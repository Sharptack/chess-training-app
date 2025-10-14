// lib/data/models/campaign.dart
import 'package:ChessTrainerApp/data/models/boss.dart';

class Campaign {
  final String id;
  final String title;
  final String description;
  final List<String> levelIds;
  final Boss boss;

  Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.levelIds,
    required this.boss,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      throw ArgumentError('Campaign.fromJson received empty JSON');
    }

    // Parse level IDs
    final levelIds = (json['levelIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    if (levelIds.isEmpty) {
      throw ArgumentError('Campaign must have at least one level');
    }

    // Parse boss
    final bossJson = json['boss'] as Map<String, dynamic>?;
    if (bossJson == null) {
      throw ArgumentError('Missing "boss" object in campaign JSON');
    }
    final boss = Boss.fromJson(bossJson);

    return Campaign(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      levelIds: levelIds,
      boss: boss,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'levelIds': levelIds,
      'boss': boss.toJson(),
    };
  }
}
