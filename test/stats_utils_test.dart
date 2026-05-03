import 'package:flutter_test/flutter_test.dart';
import 'package:streak_tracker/models/counter.dart';
import 'package:streak_tracker/models/reset.dart';
import 'package:streak_tracker/models/stats.dart';
import 'package:streak_tracker/utils/stats_utils.dart';

void main() {
  group('computeStats', () {
    test('counter with no resets returns correct stats', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final startMs = now - 86400000 * 10; // 10 days ago

      final counter = Counter(
        id: 'c1',
        title: 'Test',
        color: '#FF0000',
        startedAt: startMs,
        period: 'days',
        createdAt: startMs,
        updatedAt: now,
      );

      final stats = computeStats(counter, []);

      expect(stats.resetCount, 0);
      expect(stats.daysSinceStart, 10);
      expect(stats.longestStreakDays, 10);
      expect(stats.averageStreakDays, 10);
    });

    test('counter with resets computes correct stats', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final day = 86400000;
      final start = now - day * 20; // 20 days ago

      final counter = Counter(
        id: 'c1',
        title: 'Test',
        color: '#FF0000',
        startedAt: now - day * 5, // Reset 5 days ago
        period: 'days',
        createdAt: start,
        updatedAt: now - day * 5,
      );

      final resets = [
        Reset(
          id: 'r1',
          counterId: 'c1',
          resetAt: now - day * 10, // Reset 10 days ago
          note: null,
          previousStartedAt: start, // Started 20 days ago
          createdAt: now - day * 10,
        ),
        Reset(
          id: 'r2',
          counterId: 'c1',
          resetAt: now - day * 5, // Reset 5 days ago
          note: null,
          previousStartedAt: now - day * 10, // Started at first reset
          createdAt: now - day * 5,
        ),
      ];

      final stats = computeStats(counter, resets);

      expect(stats.resetCount, 2);
      // daysSinceStart should be from the original start (20 days ago)
      // not from current startedAt (5 days ago)
      expect(stats.daysSinceStart, 20);
      // Streaks: 10 days (first), 5 days (second), 5 days (current)
      expect(stats.longestStreakDays, 10);
    });

    test('daysSinceStart reflects original start, not last reset', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final day = 86400000;
      final originalStart = now - day * 100; // 100 days ago

      final counter = Counter(
        id: 'c1',
        title: 'Test',
        color: '#FF0000',
        startedAt: now - day * 2, // Reset 2 days ago
        period: 'days',
        createdAt: originalStart,
        updatedAt: now - day * 2,
      );

      final resets = [
        Reset(
          id: 'r1',
          counterId: 'c1',
          resetAt: now - day * 2,
          note: null,
          previousStartedAt: originalStart,
          createdAt: now - day * 2,
        ),
      ];

      final stats = computeStats(counter, resets);

      // daysSinceStart should be ~100 (from original start), not 2
      expect(stats.daysSinceStart, 100);
      // Current streak is 2 days
      expect(stats.longestStreakDays, greaterThanOrEqualTo(98)); // 98 or more from original range
    });
  });

  group('buildBarChartData', () {
    test('daily groups resets by day of week', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final day = 86400000;

      final resets = [
        Reset(
          id: 'r1',
          counterId: 'c1',
          resetAt: now,
          note: null,
          previousStartedAt: now - day,
          createdAt: now,
        ),
        Reset(
          id: 'r2',
          counterId: 'c1',
          resetAt: now - day,
          note: null,
          previousStartedAt: now - day * 2,
          createdAt: now - day,
        ),
      ];

      final groups = buildBarChartData(resets, 'daily');
      expect(groups, hasLength(7)); // Mon-Sun
    });

    test('weekly returns 12 week groups', () {
      final groups = buildBarChartData([], 'weekly');
      expect(groups, hasLength(12));
    });

    test('yearly with no resets returns one group', () {
      final groups = buildBarChartData([], 'yearly');
      expect(groups, hasLength(1));
    });

    test('yearly with resets groups by year', () {
      final resets = [
        Reset(
          id: 'r1',
          counterId: 'c1',
          resetAt: DateTime(2024, 6, 15).millisecondsSinceEpoch,
          note: null,
          previousStartedAt: DateTime(2024, 1, 1).millisecondsSinceEpoch,
          createdAt: DateTime(2024, 6, 15).millisecondsSinceEpoch,
        ),
        Reset(
          id: 'r2',
          counterId: 'c1',
          resetAt: DateTime(2025, 3, 10).millisecondsSinceEpoch,
          note: null,
          previousStartedAt: DateTime(2024, 6, 15).millisecondsSinceEpoch,
          createdAt: DateTime(2025, 3, 10).millisecondsSinceEpoch,
        ),
      ];

      final groups = buildBarChartData(resets, 'yearly');
      // Should have years from 2024 to current year
      expect(groups.length, greaterThanOrEqualTo(2));
    });

    test('invalid period returns empty list', () {
      final groups = buildBarChartData([], 'invalid');
      expect(groups, isEmpty);
    });
  });
}
