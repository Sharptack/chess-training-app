import 'package:flutter_test/flutter_test.dart';
import 'package:ChessTrainerApp/data/repositories/level_repository.dart';
import 'package:ChessTrainerApp/core/utils/result.dart';
import 'package:ChessTrainerApp/data/models/level.dart';

void main() {
  // Ensure Flutter binding is ready for asset loading
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LevelRepository', () {
    test('loads level_0001.json successfully', () async {
      final repo = const LevelRepository();
      final result = await repo.getLevelById('0001');

      expect(result.isError, isFalse, reason: 'Should load without error');
      expect(result.data, isA<Level>());

      final level = result.data!;
      expect(level.id, equals('level_0001'));
      expect(level.lessonVideo.title, isNotEmpty);
      expect(level.puzzleIds, isNotEmpty);
      expect(level.playBotIds, isNotEmpty);
      expect(level.boss, isNotNull);
      expect(level.boss.name, isNotEmpty);
    });

    test('returns error for missing level', () async {
      final repo = const LevelRepository();
      final result = await repo.getLevelById('9999');

      expect(result.isError, isTrue, reason: 'Missing file should return error');
    });
  });
}