import '../models/level.dart';
import '../models/puzzle.dart';
import '../models/bot.dart';
import '../sources/local/asset_source.dart';
import '../../core/errors/failure.dart';
import '../../core/utils/result.dart';

class LevelRepository {
  final AssetSource _assets;

  const LevelRepository({AssetSource? assets})
      : _assets = assets ?? const AssetSource();

  /// Load a level JSON by ID
  Future<Result<Level>> getLevelById(String id) async {
    final normalized = id.startsWith('level_') ? id : 'level_${id.padLeft(4, '0')}';
    final path = 'assets/data/levels/$normalized.json';

    final jsonRes = await _assets.readJson(path);
    if (jsonRes.isError) return Result.error(jsonRes.failure!);

    try {
      final levelJson = jsonRes.data!;
      final level = Level.fromJson(levelJson);

      // Phase 0.5: we don’t need the full puzzles/bots yet
      // Later: resolve puzzles/bots here with AssetSource.readJsonList()

      return Result.success(level);
    } on ArgumentError catch (e) {
      return Result.error(ParseFailure(
          'Missing required fields in level JSON',
          details: e.message.toString()));
    } catch (e) {
      return Result.error(UnexpectedFailure(
          'Failed to parse Level', details: e.toString()));
    }
  }
}