import 'package:flutter_test/flutter_test.dart';
import 'package:ChessTrainerApp/data/repositories/bot_repository.dart';
import 'package:ChessTrainerApp/core/errors/failure.dart';
import 'package:ChessTrainerApp/data/models/bot.dart';
import 'package:ChessTrainerApp/core/utils/result.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BotRepository', () {
    test('valid ID returns Bot', () async {
      const repo = BotRepository();
      final res = await repo.getBotById('bot_001');

      expect(res.isSuccess, true);
      final b = res.data!;
      expect(b, isA<Bot>());
      expect(b.id, 'bot_001');
      expect(b.name, isNotEmpty);
      expect(b.elo, greaterThan(0));
    });

    test('missing ID returns NotFoundFailure', () async {
      const repo = BotRepository();
      final res = await repo.getBotById('bot_DOES_NOT_EXIST');

      expect(res.isError, true);
      expect(res.failure, isA<NotFoundFailure>());
    });

    test('empty id returns EmptyDataFailure', () async {
      const repo = BotRepository();
      final res = await repo.getBotById('');

      expect(res.isError, true);
      expect(res.failure, isA<EmptyDataFailure>());
    });

    test('missing bots file returns Failure (path override)', () async {
      const repo = BotRepository(botsAssetPath: 'assets/data/bots/__missing.json');
      final res = await repo.getBotById('bot_001');

      expect(res.isError, true);
      expect(res.failure, isA<Failure>());
    });
  });
}
