import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/bot_repository.dart';
import '../data/repositories/puzzle_repository.dart';
import '../data/models/bot.dart';
import '../core/utils/result.dart';
import '../data/models/puzzle.dart';

final puzzleByIdProvider = FutureProvider.family<Result<Puzzle>, String>((ref, id) async {
  final repo = ref.watch(puzzleRepositoryProvider);
  return await repo.getPuzzleById(id);
});

final botByIdProvider = FutureProvider.family<Result<Bot>, String>((ref, id) async {
  final repo = ref.watch(botRepositoryProvider);
  return await repo.getBotById(id);
});

final botRepositoryProvider = Provider<BotRepository>((ref) {
  return const BotRepository();
});

final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  return PuzzleRepository();
});
