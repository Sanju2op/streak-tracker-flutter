import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/counter.dart';
import '../models/goal.dart';
import '../models/reset.dart';
import 'db_adapter.dart';

class WebAdapter implements DbAdapter {
  static const _countersKey = 'st_counters';
  static const _resetsKey = 'st_resets';
  static const _goalsKey = 'st_goals';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    final existing = _prefs;
    if (existing != null) return existing;
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }

  @override
  Future<void> init() async {
    await _preferences;
  }

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await _preferences;
    final raw = prefs.getString(key);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> rows) async {
    final prefs = await _preferences;
    await prefs.setString(key, jsonEncode(rows));
  }

  @override
  Future<List<Counter>> getCounters() async {
    final rows = await _readList(_countersKey);
    rows.sort(
      (a, b) => (a['created_at'] as int).compareTo(b['created_at'] as int),
    );
    return rows.map(Counter.fromMap).toList();
  }

  @override
  Future<Counter?> getCounter(String id) async {
    final rows = await _readList(_countersKey);
    for (final row in rows) {
      if (row['id'] == id) return Counter.fromMap(row);
    }
    return null;
  }

  @override
  Future<void> insertCounter(Counter counter) async {
    final rows = await _readList(_countersKey);
    rows.add(counter.toMap());
    await _writeList(_countersKey, rows);
  }

  @override
  Future<void> updateCounter(Counter counter) async {
    final rows = await _readList(_countersKey);
    final updatedRows = rows
        .map((row) => row['id'] == counter.id ? counter.toMap() : row)
        .toList();
    await _writeList(_countersKey, updatedRows);
  }

  @override
  Future<void> deleteCounter(String id) async {
    final counters = await _readList(_countersKey);
    final resets = await _readList(_resetsKey);
    final goals = await _readList(_goalsKey);

    await _writeList(
      _countersKey,
      counters.where((row) => row['id'] != id).toList(),
    );
    await _writeList(
      _resetsKey,
      resets.where((row) => row['counter_id'] != id).toList(),
    );
    await _writeList(
      _goalsKey,
      goals.where((row) => row['counter_id'] != id).toList(),
    );
  }

  @override
  Future<List<Reset>> getResets(String counterId) async {
    final rows = await _readList(_resetsKey);
    final filtered =
        rows.where((row) => row['counter_id'] == counterId).toList()..sort(
          (a, b) => (b['reset_at'] as int).compareTo(a['reset_at'] as int),
        );
    return filtered.map(Reset.fromMap).toList();
  }

  @override
  Future<void> insertReset(Reset reset) async {
    final rows = await _readList(_resetsKey);
    rows.add(reset.toMap());
    await _writeList(_resetsKey, rows);
  }

  @override
  Future<List<Goal>> getGoals(String counterId) async {
    final rows = await _readList(_goalsKey);
    final filtered =
        rows.where((row) => row['counter_id'] == counterId).toList()..sort(
          (a, b) => (a['created_at'] as int).compareTo(b['created_at'] as int),
        );
    return filtered.map(Goal.fromMap).toList();
  }

  @override
  Future<void> insertGoal(Goal goal) async {
    final rows = await _readList(_goalsKey);
    rows.add(goal.toMap());
    await _writeList(_goalsKey, rows);
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    final rows = await _readList(_goalsKey);
    final updatedRows = rows
        .map((row) => row['id'] == goal.id ? goal.toMap() : row)
        .toList();
    await _writeList(_goalsKey, updatedRows);
  }

  @override
  Future<void> deleteGoal(String id) async {
    final rows = await _readList(_goalsKey);
    await _writeList(_goalsKey, rows.where((row) => row['id'] != id).toList());
  }
}
