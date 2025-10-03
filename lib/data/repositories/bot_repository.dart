// lib/data/repositories/bot_repository.dart
import '../sources/local/asset_source.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failure.dart';
import '../models/bot.dart';

class BotRepository {
  final AssetSource _assetSource = const AssetSource();

  Future<Result<List<Bot>>> getAllBots() async {
    try {
      final result = await _assetSource.readJson('assets/data/bots/bots.json');
      if (result.isError) {
        return Result.error(result.failure!);
      }

      final data = result.data!;
      final bots = <Bot>[];

      for (final entry in data.entries) {
        // Skip metadata keys like $schema
        if (entry.key.startsWith(r'$')) continue;

        final botData = entry.value as Map<String, dynamic>;
        bots.add(Bot.fromJson(botData));
      }

      return Result.success(bots);
    } catch (e) {
      return Result.error(UnexpectedFailure('Failed to load bots: $e'));
    }
  }

  Future<Result<Bot>> getBotById(String id) async {
    try {
      final result = await _assetSource.readJson('assets/data/bots/bots.json');
      if (result.isError) {
        return Result.error(result.failure!);
      }

      final data = result.data!;
      final botData = data[id];
      
      if (botData == null) {
        return Result.error(NotFoundFailure('Bot not found: $id'));
      }

      final bot = Bot.fromJson(botData as Map<String, dynamic>);
      return Result.success(bot);
    } catch (e) {
      return Result.error(UnexpectedFailure('Failed to load bot: $e'));
    }
  }
}