import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';

import 'database_factory.dart' as platform_database;

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(),
);

class AppDatabase {
  Database? _db;

  final StoreRef<int, Map<String, Object?>> _accounts = intMapStoreFactory
      .store('accounts');
  final StoreRef<int, Map<String, Object?>> _farms = intMapStoreFactory.store(
    'farms',
  );
  final StoreRef<int, Map<String, Object?>> _plots = intMapStoreFactory.store(
    'plots',
  );
  final StoreRef<int, Map<String, Object?>> _crops = intMapStoreFactory.store(
    'crops',
  );
  final StoreRef<int, Map<String, Object?>> _entries = intMapStoreFactory.store(
    'journal_entries',
  );
  final StoreRef<int, Map<String, Object?>> _tasks = intMapStoreFactory.store(
    'tasks',
  );

  Database get _database => _db!;

  Future<void> open() async {
    final path = kIsWeb
        ? 'organic_farming_journal'
        : p.join(
            (await getApplicationDocumentsDirectory()).path,
            'organic_farming_journal.db',
          );
    _db = await platform_database.openDatabase(path);
  }

  Future<Map<String, dynamic>?> accountByUsername(String username) async {
    final matches = await _accounts.find(
      _database,
      finder: Finder(
        filter: Filter.equals('username_key', username.trim().toLowerCase()),
        limit: 1,
      ),
    );
    return matches.isEmpty
        ? null
        : _record(matches.first.key, matches.first.value);
  }

  Future<int> registerAccount({
    required String username,
    required String name,
    required String passwordHash,
  }) async {
    final normalizedUsername = username.trim();
    final existing = await accountByUsername(normalizedUsername);
    if (existing != null) throw StateError('USERNAME_TAKEN');

    return _database.transaction((transaction) async {
      final id = await _accounts.add(transaction, {
        'username': normalizedUsername,
        'username_key': normalizedUsername.toLowerCase(),
        'name': name.trim(),
        'password_hash': passwordHash,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _farms.add(transaction, {
        'account_id': id,
        'name': '',
        'location': '',
        'area': null,
        'area_unit': 'acres',
        'certification': 'None',
      });
      return id;
    });
  }

  Future<Map<String, dynamic>?> accountById(int id) async {
    final value = await _accounts.record(id).get(_database);
    return value == null ? null : _record(id, value);
  }

  Future<Map<String, dynamic>> dashboardData(int accountId) async {
    final account = await accountById(accountId);
    if (account == null) throw StateError('ACCOUNT_NOT_FOUND');

    final farmRows = await _accountRows(_farms, accountId);
    final plots = await _accountRows(_plots, accountId);
    final allCrops = await _accountRows(_crops, accountId);
    final activeCrops = allCrops
        .where((crop) => crop['status'] != 'Harvested')
        .toList();
    final cropsById = {for (final crop in allCrops) crop['id']: crop};
    final plotsById = {for (final plot in plots) plot['id']: plot};
    final entries = await _accountRows(_entries, accountId)
      ..sort(
        (a, b) =>
            (b['occurred_at'] as String).compareTo(a['occurred_at'] as String),
      );
    final enrichedEntries = entries
        .map((entry) {
          final crop = cropsById[entry['crop_id']];
          final plot = plotsById[entry['plot_id']];
          return {
            ...entry,
            'crop_name': crop?['name'],
            'plot_name': plot?['name'],
          };
        })
        .take(20)
        .toList();
    final openTasks =
        (await _accountRows(
          _tasks,
          accountId,
        )).where((task) => task['done'] != true).toList()..sort(
          (a, b) => (a['due_at'] as String? ?? '').compareTo(
            b['due_at'] as String? ?? '',
          ),
        );

    return {
      'account': account,
      'farm': farmRows.isEmpty ? null : farmRows.first,
      'entries': enrichedEntries,
      'crops': activeCrops,
      'plots': plots,
      'tasks': openTasks,
    };
  }

  Future<void> addJournalEntry({
    required int accountId,
    required String activity,
    required String notes,
  }) async {
    await _entries.add(_database, {
      'account_id': accountId,
      'activity': activity,
      'occurred_at': DateTime.now().toIso8601String(),
      'notes': notes,
    });
  }

  Future<void> addJournalActivity({
    required int accountId,
    required String activity,
    required String notes,
  }) => addJournalEntry(accountId: accountId, activity: activity, notes: notes);

  Future<void> addCrop({required int accountId, required String name}) async {
    await _crops.add(_database, {
      'account_id': accountId,
      'name': name,
      'status': 'Growing',
      'sowing_date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addPlot({required int accountId, required String name}) async {
    await _plots.add(_database, {'account_id': accountId, 'name': name});
  }

  Future<void> addTask({required int accountId, required String title}) async {
    await _tasks.add(_database, {
      'account_id': accountId,
      'title': title,
      'due_at': DateTime.now().toIso8601String(),
      'priority': 'Normal',
      'done': false,
    });
  }

  Future<void> completeTask(int accountId, int taskId) async {
    final task = await _tasks.record(taskId).get(_database);
    if (task == null || task['account_id'] != accountId) return;
    await _tasks.record(taskId).update(_database, {'done': true});
  }

  Future<void> updateFarm({
    required int accountId,
    required String name,
    required String location,
    required double? area,
  }) async {
    final farms = await _accountRows(_farms, accountId);
    if (farms.isEmpty) {
      await _farms.add(_database, {
        'account_id': accountId,
        'name': name,
        'location': location,
        'area': area,
        'area_unit': 'acres',
        'certification': 'None',
      });
      return;
    }
    await _farms.record(farms.first['id'] as int).update(_database, {
      'name': name,
      'location': location,
      'area': area,
    });
  }

  Future<List<Map<String, dynamic>>> _accountRows(
    StoreRef<int, Map<String, Object?>> store,
    int accountId,
  ) async {
    final query = Finder(filter: Filter.equals('account_id', accountId));
    final records = await store.find(_database, finder: query);
    return records.map((record) => _record(record.key, record.value)).toList();
  }

  Map<String, dynamic> _record(int id, Map<String, Object?> value) => {
    'id': id,
    for (final entry in value.entries) entry.key: entry.value,
  };
}
