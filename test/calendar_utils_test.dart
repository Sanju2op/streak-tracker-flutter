import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak_tracker/models/counter.dart';
import 'package:streak_tracker/models/reset.dart';
import 'package:streak_tracker/utils/calendar_utils.dart';

void main() {
  group('buildDayColorMap', () {
    test('counter with no resets: colors all days from startedAt to now', () {
      final startMs =
          DateTime(2026, 5, 1).millisecondsSinceEpoch; // May 1, 2026
      final counter = Counter(
        id: 'c1',
        title: 'Test',
        color: '#FF0000',
        startedAt: startMs,
        period: 'days',
        createdAt: startMs,
        updatedAt: startMs,
      );

      final map = buildDayColorMap([counter], [], []);

      // Should have entries from May 1 to today
      final may1 = DateTime(2026, 5, 1);
      expect(map.containsKey(may1), isTrue);
      expect(map[may1]!.length, 1);

      // The day before start should not exist
      final apr30 = DateTime(2026, 4, 30);
      expect(map.containsKey(apr30), isFalse);
    });

    test('counter with resets: colors previous ranges correctly', () {
      // Counter was started on Apr 20, reset on Apr 25, now running from Apr 25
      final startMs = DateTime(2026, 4, 20).millisecondsSinceEpoch;
      final resetMs = DateTime(2026, 4, 25).millisecondsSinceEpoch;
      final counter = Counter(
        id: 'c1',
        title: 'Test',
        color: '#00FF00',
        startedAt: resetMs, // Updated to reset time
        period: 'days',
        createdAt: startMs,
        updatedAt: resetMs,
      );

      final reset = Reset(
        id: 'r1',
        counterId: 'c1',
        resetAt: resetMs,
        note: null,
        previousStartedAt: startMs, // Original start
        createdAt: resetMs,
      );

      final map = buildDayColorMap([counter], [reset], []);

      // Apr 20 should have the color (from the old range via the reset)
      expect(map.containsKey(DateTime(2026, 4, 20)), isTrue);
      // Apr 22 should have the color
      expect(map.containsKey(DateTime(2026, 4, 22)), isTrue);
      // Apr 19 should NOT have color
      expect(map.containsKey(DateTime(2026, 4, 19)), isFalse);
    });

    test('filterIds: only includes matching counters', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final c1 = Counter(
        id: 'c1',
        title: 'A',
        color: '#FF0000',
        startedAt: now - 86400000,
        period: 'days',
        createdAt: now - 86400000,
        updatedAt: now,
      );
      final c2 = Counter(
        id: 'c2',
        title: 'B',
        color: '#00FF00',
        startedAt: now - 86400000,
        period: 'days',
        createdAt: now - 86400000,
        updatedAt: now,
      );

      final map = buildDayColorMap([c1, c2], [], ['c1']);
      final todayColors = map[DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      )];

      // Only c1's color should be present
      expect(todayColors, isNotNull);
      expect(todayColors!.length, 1);
    });

    test('empty filter list includes all counters', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final c1 = Counter(
        id: 'c1',
        title: 'A',
        color: '#FF0000',
        startedAt: now - 86400000,
        period: 'days',
        createdAt: now - 86400000,
        updatedAt: now,
      );
      final c2 = Counter(
        id: 'c2',
        title: 'B',
        color: '#00FF00',
        startedAt: now - 86400000,
        period: 'days',
        createdAt: now - 86400000,
        updatedAt: now,
      );

      final map = buildDayColorMap([c1, c2], [], []);
      final todayColors = map[DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      )];

      expect(todayColors, isNotNull);
      expect(todayColors!.length, 2);
    });

    test('no duplicate colors for same counter on same day', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final counter = Counter(
        id: 'c1',
        title: 'Test',
        color: '#FF0000',
        startedAt: now - 86400000 * 2,
        period: 'days',
        createdAt: now - 86400000 * 2,
        updatedAt: now,
      );

      // Two resets but same counter
      final reset1 = Reset(
        id: 'r1',
        counterId: 'c1',
        resetAt: now - 86400000,
        note: null,
        previousStartedAt: now - 86400000 * 2,
        createdAt: now - 86400000,
      );

      final map = buildDayColorMap([counter], [reset1], []);
      for (final entry in map.entries) {
        final colors = entry.value;
        // Each color should appear at most once per day
        expect(colors.toSet().length, colors.length,
            reason: 'Duplicate color on ${entry.key}');
      }
    });
  });
}
