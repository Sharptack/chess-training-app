import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow all orientations (portrait and landscape)
  // No orientation lock - let device rotate freely

  // Initialize Hive
  await Hive.initFlutter();

  // Open the progress box
  await Hive.openBox('progressBox');

  runApp(
    const ProviderScope(
      child: ChessTrainerApp(),
    ),
  );
}
