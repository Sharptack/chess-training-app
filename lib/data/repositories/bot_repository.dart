import '../models/bot.dart';
import '../sources/local/asset_source.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failure.dart';

class BotRepository {
  final AssetSource _assets;
  final String botsAssetPath;

  const BotRepository({
    AssetSource? assets,
    this.botsAssetPath = 'assets/data/bots/bots.json',
  }) : _assets = assets ?? const AssetSource();

  Future<Result<Bot>> getBotById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return Result.error(EmptyDataFailure('Empty bot id'));
    }

    final res = await _assets.readJson(botsAssetPath);
    if (res.isError) return Result.error(res.failure!);

    final map = res.data!;
    final bjson = map[trimmed];
    if (bjson is! Map<String, dynamic>) {
      return Result.error(NotFoundFailure('Bot not found', details: 'id=$trimmed'));
    }

    try {
      return Result.success(Bot.fromJson(bjson));
    } catch (e) {
      return Result.error(ParseFailure('Invalid bot JSON', details: e.toString()));
    }
  }
}
