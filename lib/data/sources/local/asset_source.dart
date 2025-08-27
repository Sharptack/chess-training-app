// lib/data/sources/local/asset_source.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/errors/failure.dart';
import '../../../core/utils/result.dart';

class AssetSource {
  const AssetSource();

  /// Reads a JSON file from assets and returns it as a Map
  Future<Result<Map<String, dynamic>>> readJson(String assetPath) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      final map = json.decode(content) as Map<String, dynamic>;
      return Result.success(map);
    } on FormatException catch (e) {
      return Result.error(ParseFailure(
          'Invalid JSON format', details: '${e.message} (path: $assetPath)'));
    } catch (e) {
      return Result.error(UnexpectedFailure(
          'Unexpected error reading asset', details: '$e (path: $assetPath)'));
    }
  }

  /// Helper to read a JSON file and return a list of maps
  Future<Result<List<Map<String, dynamic>>>> readJsonList(String assetPath) async {
    final res = await readJson(assetPath);
    if (res.isError) return Result.error(res.failure!);

    final map = res.data!;
    final list = map.values.whereType<Map<String, dynamic>>().toList();
    return Result.success(list);
  }
}
