import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Calendar screen integration', () {
    testWidgets('Calendar tab shows calendar and day panel', (tester) async {
      final fakeDb = FakeDbAdapter();
      final now = DateTime.now().millisecondsSinceEpoch;
      await fakeDb.insertCounter(Counter(
        id: 'cal-counter',
        title: 'Calendar Test',
        color: '#FF0000',
        startedAt: now - 86400000 * 3, // 3 days ago
        period: 'days',
        createdAt: now - 86400000 * 3,
        updatedAt: now,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbAdapterProvider.overrideWithValue(fakeDb)],
          child: const StreakTrackerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to calendar tab
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      // Verify Calendar screen elements
      expect(find.text('Calendar'), findsWidgets);
      expect(find.text('Filter'), findsOneWidget);

      // Should show today's date in the day panel header
      final today = DateTime.now();
      // The month names are 3-letter abbreviations
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final expectedDate = '${today.day} ${months[today.month - 1]}';
      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('Calendar shows counter in day list', (tester) async {
      final fakeDb = FakeDbAdapter();
      final now = DateTime.now().millisecondsSinceEpoch;
      await fakeDb.insertCounter(Counter(
        id: 'cal-counter-2',
        title: 'My Streak',
        color: '#2ECC71',
        startedAt: now - 86400000 * 5, // 5 days ago
        period: 'days',
        createdAt: now - 86400000 * 5,
        updatedAt: now,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbAdapterProvider.overrideWithValue(fakeDb)],
          child: const StreakTrackerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to calendar tab
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      // The counter should appear in the day list panel for today
      expect(find.text('My Streak'), findsOneWidget);
    });
  });

  group('Counter detail screen integration', () {
    testWidgets('shows current streak card with correct labels', (tester) async {
      final fakeDb = FakeDbAdapter();
      final now = DateTime.now().millisecondsSinceEpoch;
      await fakeDb.insertCounter(Counter(
        id: 'detail-counter',
        title: 'Exercise',
        color: '#3A78ED',
        startedAt: now - 86400000 * 10, // 10 days ago
        period: 'days',
        createdAt: now - 86400000 * 10,
        updatedAt: now,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbAdapterProvider.overrideWithValue(fakeDb)],
          child: const StreakTrackerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to counter detail
      appRouter.push('/counters/detail-counter');
      await tester.pumpAndSettle();

      // Verify detail screen elements
      expect(find.text('Exercise'), findsWidgets);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Reset Counter'), findsOneWidget);
      expect(find.text('All Resets'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Stats'), findsWidgets);
      expect(find.text('Reminders'), findsOneWidget);
    });

    testWidgets('period tab selector changes the display', (tester) async {
      final fakeDb = FakeDbAdapter();
      final now = DateTime.now().millisecondsSinceEpoch;
      await fakeDb.insertCounter(Counter(
        id: 'period-counter',
        title: 'Period Test',
        color: '#FF0000',
        startedAt: now - 86400000 * 30, // 30 days ago
        period: 'years',
        createdAt: now - 86400000 * 30,
        updatedAt: now,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbAdapterProvider.overrideWithValue(fakeDb)],
          child: const StreakTrackerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to counter detail
      appRouter.push('/counters/period-counter');
      await tester.pumpAndSettle();

      // Should show 'Years' tab labels in the breakdown
      expect(find.text('Years'), findsWidgets);

      // Tap on 'Days' tab
      await tester.tap(find.text('Days').last);
      await tester.pumpAndSettle();

      // Should now show 'Days' in the breakdown
      expect(find.text('Days'), findsWidgets);
    });
  });

  group('Counter list screen integration', () {
    testWidgets('empty state shows when no counters', (tester) async {
      final fakeDb = FakeDbAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbAdapterProvider.overrideWithValue(fakeDb)],
          child: const StreakTrackerApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();

      expect(find.text('No counters yet'), findsOneWidget);
      expect(find.text('Add Counter'), findsOneWidget);
    });

    testWidgets('counter cards show in grid', (tester) async {
      final fakeDb = FakeDbAdapter();
      final now = DateTime.now().millisecondsSinceEpoch;

      await fakeDb.insertCounter(Counter(
        id: 'c1',
        title: 'Counter One',
        color: '#FF0000',
        startedAt: now,
        period: 'days',
        createdAt: now,
        updatedAt: now,
      ));
      await fakeDb.insertCounter(Counter(
        id: 'c2',
        title: 'Counter Two',
        color: '#00FF00',
        startedAt: now,
        period: 'weeks',
        createdAt: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbAdapterProvider.overrideWithValue(fakeDb)],
          child: const StreakTrackerApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();

      expect(find.text('Counter One'), findsOneWidget);
      expect(find.text('Counter Two'), findsOneWidget);
    });
  });

  group('Goals screen integration', () {
    testWidgets('goals screen shows empty state', (tester) async {
      final fakeDb = FakeDbAdapter();
      final now = DateTime.now().millisecondsSinceEpoch;
      await fakeDb.insertCounter(Counter(
        id: 'goal-counter',
        title: 'Goal Test',
        color: '#FF0000',
        startedAt: now,
        period: 'days',
        createdAt: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbAdapterProvider.overrideWithValue(fakeDb)],
          child: const StreakTrackerApp(),
        ),
      );
      await tester.pumpAndSettle();

      appRouter.push('/counters/goal-counter/goals');
      await tester.pumpAndSettle();

      expect(find.text('Goals'), findsWidgets);
      expect(find.text('No goals set'), findsOneWidget);
      expect(find.text('Challenge yourself'), findsOneWidget);
    });
  });

  group('Settings screen integration', () {
    testWidgets('settings screen shows all elements', (tester) async {
      final fakeDb = FakeDbAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbAdapterProvider.overrideWithValue(fakeDb)],
          child: const StreakTrackerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to settings tab
      appRouter.go('/settings');
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Tell a Friend'), findsOneWidget);
      expect(find.text('Streak Tracker 1.0.0 (build 1)'), findsOneWidget);
    });
  });
}
