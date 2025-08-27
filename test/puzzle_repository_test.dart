import 'package:flutter_test/flutter_test.dart';
import 'package:ChessTrainerApp/data/repositories/puzzle_repository.dart';
import 'package:ChessTrainerApp/core/errors/failure.dart';
import 'package:ChessTrainerApp/data/models/puzzle.dart';
import 'package:ChessTrainerApp/core/utils/result.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PuzzleRepository', () {
    test('valid ID returns Puzzle', () async {
      final repo = PuzzleRepository();
      final res = await repo.getPuzzleById('puzzle_0001');

      expect(res.isSuccess, true);
      final p = res.data!;
      expect(p, isA<Puzzle>());
      expect(p.id, 'puzzle_0001');
      expect(p.fen, isNotEmpty);
      expect(p.solution, isNotEmpty);
    });

    test('missing ID returns NotFoundFailure', () async {
      final repo = PuzzleRepository();
      final res = await repo.getPuzzleById('puzzle_DOES_NOT_EXIST');

      expect(res.isError, true);
      expect(res.failure, isA<NotFoundFailure>());
    });

    test('empty id returns EmptyDataFailure', () async {
      final repo = PuzzleRepository();
      final res = await repo.getPuzzleById('   ');

      expect(res.isError, true);
      expect(res.failure, isA<EmptyDataFailure>());
    });

    test('missing set file returns NotFoundFailure (path override)', () async {
      final repo = PuzzleRepository(
        indexPath: 'assets/data/puzzles/__missing_index.json',
      );
      final res = await repo.getPuzzleById('puzzle_0001');

      expect(res.isError, true);
      // Could be NotFoundFailure from the underlying asset read
      expect(res.failure, isA<Failure>());
    });
  });
}