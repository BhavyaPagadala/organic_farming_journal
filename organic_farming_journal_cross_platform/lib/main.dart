import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  await database.open();
  runApp(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const OrganicJournalApp()));
}
