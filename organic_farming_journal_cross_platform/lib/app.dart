import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';

final sessionProvider = StateProvider<int?>((ref) => null);

class OrganicJournalApp extends ConsumerWidget {
  const OrganicJournalApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(sessionProvider);
    return MaterialApp(
        title: 'Organic Farming Journal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF386641)),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF6F7F1)),
        home: id == null ? const AuthScreen() : HomeScreen(accountId: id));
  }
}
