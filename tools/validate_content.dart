import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final levelsDir = Directory('assets/data/levels');
  final puzzlesIndexFile = File('assets/data/puzzles/index.json');
  final botsFile = File('assets/data/bots/bots.json');

  if (!levelsDir.existsSync()) {
    stderr.writeln('❌ assets/data/levels not found');
    exit(1);
  }
  if (!puzzlesIndexFile.existsSync()) {
    stderr.writeln('❌ assets/data/puzzles/index.json not found');
    exit(1);
  }
  if (!botsFile.existsSync()) {
    stderr.writeln('❌ assets/data/bots/bots.json not found');
    exit(1);
  }

  // Load reference data
  final puzzlesIndexJson =
      json.decode(await puzzlesIndexFile.readAsString());
  final puzzlesIndex = <String>{};
  if (puzzlesIndexJson is Map) {
    puzzlesIndex.addAll(puzzlesIndexJson.keys.cast<String>());
  } else {
    stderr.writeln('❌ puzzles/index.json should be a JSON object with puzzle IDs as keys.');
    exit(1);
  }

  final botsJson = json.decode(await botsFile.readAsString());
  final bots = <String>{};
  if (botsJson is Map) {
    bots.addAll(botsJson.keys.cast<String>());
  } else {
    stderr.writeln('❌ bots.json should be a JSON object with bot IDs as keys.');
    exit(1);
  }

  // Validate levels
  final levelFiles = levelsDir
      .listSync()
      .where((f) => f is File && f.path.endsWith('.json'))
      .cast<File>();

  if (levelFiles.isEmpty) {
    stderr.writeln('⚠️ No level JSON files found in assets/data/levels');
    exit(1);
  }

  var successCount = 0;
  var failureCount = 0;

  for (final file in levelFiles) {
    try {
      final content = await file.readAsString();
      final jsonData = json.decode(content);

      if (jsonData is! Map || !jsonData.containsKey('id')) {
        throw FormatException('Level file missing "id" field');
      }

      final levelId = jsonData['id'];
      final puzzles = (jsonData['puzzles'] as List?)?.cast<String>() ?? [];
      final levelBots = (jsonData['bots'] as List?)?.cast<String>() ?? [];

      // Cross-check puzzle IDs
      for (final pid in puzzles) {
        if (!puzzlesIndex.contains(pid)) {
          stderr.writeln(
              '❌ ${file.path} (level $levelId) references missing puzzle ID: $pid');
          failureCount++;
        }
      }

      // Cross-check bot IDs
      for (final bid in levelBots) {
        if (!bots.contains(bid)) {
          stderr.writeln(
              '❌ ${file.path} (level $levelId) references missing bot ID: $bid');
          failureCount++;
        }
      }

      if (failureCount == 0) {
        stdout.writeln('✅ ${file.path} (level $levelId) is valid');
        successCount++;
      }
    } catch (e) {
      stderr.writeln('❌ Error parsing ${file.path}: $e');
      failureCount++;
    }
  }

  stdout.writeln(
      '\nValidation complete: $successCount valid, $failureCount errors.');

  if (failureCount > 0) {
    exit(1);
  }
}
