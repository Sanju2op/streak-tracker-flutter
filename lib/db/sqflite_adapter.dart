import 'package:sqflite/sqflite.dart';

import '../models/counter.dart';
import '../models/goal.dart';
import '../models/reset.dart';
import 'db_adapter.dart';
import 'schema.dart';

class SqfliteAdapter implements DbAdapter {
  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;

    final databasePath = '${await getDatabasesPath()}/streak_tracker.db';
    final database = await openDatabase(
      databasePath,
      version: 1,
      onConfigure: (db) async => db.execute(enableForeignKeysSql),
      onCreate: (db, version) async {
        for (final statement in schemaSql) {
          await db.execute(statement);
        }
      },
      onOpen: (db) async => db.execute(enableForeignKeysSql),
    );
    _db = database;
    return database;
  }

  @override
  Future<void> init() async {
    await _database;
  }

  @override
  Future<List<Counter>> getCounters() async {
    final db = await _database;
    final rows = await db.query('counters', orderBy: 'created_at ASC');
    return rows.map(Counter.fromMap).toList();
  }

  @override
  Future<Counter?> getCounter(String id) async {
    final db = await _database;
    final rows = await db.query(
      'counters',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Counter.fromMap(rows.first);
  }

  @override
  Future<void> insertCounter(Counter counter) async {
    final db = await _database;
    await db.insert('counters', counter.toMap());
  }

  @override
  Future<void> updateCounter(Counter counter) async {
    final db = await _database;
    await db.update(
      'counters',
      counter.toMap(),
      where: 'id = ?',
      whereArgs: [counter.id],
    );
  }

  @override
  Future<void> deleteCounter(String id) async {
    final db = await _database;
    await db.delete('counters', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Reset>> getResets(String counterId) async {
    final db = await _database;
    final rows = await db.query(
      'resets',
      where: 'counter_id = ?',
      whereArgs: [counterId],
      orderBy: 'reset_at DESC',
    );
    return rows.map(Reset.fromMap).toList();
  }

  @override
  Future<void> insertReset(Reset reset) async {
    final db = await _database;
    await db.insert('resets', reset.toMap());
  }

  @override
  Future<List<Goal>> getGoals(String counterId) async {
    final db = await _database;
    final rows = await db.query(
      'goals',
      where: 'counter_id = ?',
      whereArgs: [counterId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Goal.fromMap).toList();
  }

  @override
  Future<void> insertGoal(Goal goal) async {
    final db = await _database;
    await db.insert('goals', goal.toMap());
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    final db = await _database;
    await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  @override
  Future<void> deleteGoal(String id) async {
    final db = await _database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }
}
