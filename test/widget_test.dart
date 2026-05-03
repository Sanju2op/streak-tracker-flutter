import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak_tracker/app.dart';
import 'package:streak_tracker/db/db_adapter.dart';
import 'package:streak_tracker/models/counter.dart';
import 'package:streak_tracker/models/goal.dart';
import 'package:streak_tracker/models/reset.dart';
import 'package:streak_tracker/providers/db_provider.dart';
import 'package:streak_tracker/router/app_router.dart';

/// In-memory fake adapter for widget tests — no sqflite or shared_preferences.
class FakeDbAdapter implements DbAdapter {
  final List<Counter> _counters = [];
  final List<Reset> _resets = [];
  final List<Goal> _goals = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<Counter>> getCounters() async => List.unmodifiable(_counters);

  @override
  Future<Counter?> getCounter(String id) async {
    try {
      return _counters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertCounter(Counter counter) async => _counters.add(counter);

  @override
  Future<void> updateCounter(Counter counter) async {
    _counters.removeWhere((c) => c.id == counter.id);
    _counters.add(counter);
  }

  @override
  Future<void> deleteCounter(String id) async {
    _counters.removeWhere((c) => c.id == id);
    _resets.removeWhere((r) => r.counterId == id);
    _goals.removeWhere((g) => g.counterId == id);
  }

  @override
  Future<List<Reset>> getResets(String counterId) async =>
      _resets.where((r) => r.counterId == counterId).toList();

  @override
  Future<void> insertReset(Reset reset) async => _resets.add(reset);

  @override
  Future<void> updateReset(Reset reset) async {
    _resets.removeWhere((r) => r.id == reset.id);
    _resets.add(reset);
  }

  @override
  Future<void> deleteReset(String id) async {
    _resets.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<Goal>> getGoals(String counterId) async =>
      _goals.where((g) => g.counterId == counterId).toList();

  @override
  Future<void> insertGoal(Goal goal) async => _goals.add(goal);

  @override
  Future<void> updateGoal(Goal goal) async {
    _goals.removeWhere((g) => g.id == goal.id);
    _goals.add(goal);
  }

  @override
  Future<void> deleteGoal(String id) async =>
      _goals.removeWhere((g) => g.id == id);
}

void main() {
  testWidgets('tab shell switches between primary screens', (tester) async {
    final fakeDb = FakeDbAdapter();
    final now = DateTime.now().millisecondsSinceEpoch;
    await fakeDb.insertCounter(
      Counter(
        id: 'demo-counter',
        title: 'Demo Counter',
        color: '#FF0000',
        startedAt: now,
        period: 'years',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbAdapterProvider.overrideWithValue(fakeDb)],
        child: const StreakTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Counters tab is active by default
    expect(find.text('Counters'), findsWidgets);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Switch to Calendar
    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsWidgets);

    // Switch to Settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);

    // Navigate to counter detail
    appRouter.go('/counters');
    await tester.pumpAndSettle();

    appRouter.push('/counters/demo-counter');
    await tester.pumpAndSettle();

    // With the new implementation, it shows the counter title and "Current Streak"
    expect(find.text('Demo Counter'), findsWidgets);
    expect(find.text('Current Streak'), findsOneWidget);

    // Pop back to counters
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('Counters'), findsWidgets);
  });
}
