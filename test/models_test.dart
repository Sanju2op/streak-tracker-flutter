import 'package:flutter_test/flutter_test.dart';
import 'package:streak_tracker/models/counter.dart';
import 'package:streak_tracker/models/reset.dart';
import 'package:streak_tracker/models/goal.dart';
import 'package:streak_tracker/models/elapsed_time.dart';
import 'package:streak_tracker/models/stats.dart';

void main() {
  group('Counter model', () {
    test('fromMap and toMap are inverse operations', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final counter = Counter(
        id: 'test-id',
        title: 'No junk food',
        color: '#FF0000',
        startedAt: now,
        period: 'days',
        createdAt: now,
        updatedAt: now,
      );

      final map = counter.toMap();
      final restored = Counter.fromMap(map);

      expect(restored.id, counter.id);
      expect(restored.title, counter.title);
      expect(restored.color, counter.color);
      expect(restored.startedAt, counter.startedAt);
      expect(restored.period, counter.period);
      expect(restored.createdAt, counter.createdAt);
      expect(restored.updatedAt, counter.updatedAt);
    });

    test('copyWith creates a copy with changed fields', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final counter = Counter(
        id: 'test-id',
        title: 'Original',
        color: '#FF0000',
        startedAt: now,
        period: 'days',
        createdAt: now,
        updatedAt: now,
      );

      final updated = counter.copyWith(title: 'Updated', period: 'hours');
      expect(updated.title, 'Updated');
      expect(updated.period, 'hours');
      expect(updated.id, counter.id); // unchanged
      expect(updated.color, counter.color); // unchanged
    });

    test('all valid periods are accepted', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final period in ['hours', 'days', 'weeks', 'months', 'years']) {
        final counter = Counter(
          id: 'test',
          title: 'Test',
          color: '#000000',
          startedAt: now,
          period: period,
          createdAt: now,
          updatedAt: now,
        );
        expect(counter.period, period);
      }
    });
  });

  group('Reset model', () {
    test('fromMap and toMap are inverse', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final reset = Reset(
        id: 'r1',
        counterId: 'c1',
        resetAt: now,
        note: 'Birthday',
        previousStartedAt: now - 86400000,
        createdAt: now,
      );

      final map = reset.toMap();
      final restored = Reset.fromMap(map);

      expect(restored.id, reset.id);
      expect(restored.counterId, reset.counterId);
      expect(restored.resetAt, reset.resetAt);
      expect(restored.note, 'Birthday');
      expect(restored.previousStartedAt, reset.previousStartedAt);
    });

    test('note can be null', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final reset = Reset(
        id: 'r1',
        counterId: 'c1',
        resetAt: now,
        note: null,
        previousStartedAt: now - 86400000,
        createdAt: now,
      );

      final map = reset.toMap();
      final restored = Reset.fromMap(map);
      expect(restored.note, isNull);
    });
  });

  group('Goal model', () {
    test('fromMap and toMap are inverse', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final goal = Goal(
        id: 'g1',
        counterId: 'c1',
        targetValue: 30,
        targetUnit: 'days',
        note: 'First month',
        isCompleted: false,
        createdAt: now,
      );

      final map = goal.toMap();
      final restored = Goal.fromMap(map);

      expect(restored.id, goal.id);
      expect(restored.targetValue, 30);
      expect(restored.targetUnit, 'days');
      expect(restored.note, 'First month');
      expect(restored.isCompleted, false);
    });

    test('copyWith toggles isCompleted', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final goal = Goal(
        id: 'g1',
        counterId: 'c1',
        targetValue: 7,
        targetUnit: 'days',
        note: null,
        isCompleted: false,
        createdAt: now,
      );

      final completed = goal.copyWith(isCompleted: true);
      expect(completed.isCompleted, true);
      expect(completed.targetValue, 7); // unchanged
    });
  });

  group('ElapsedTime model', () {
    test('constructs correctly', () {
      const e = ElapsedTime(
        years: 1,
        months: 2,
        days: 3,
        hours: 4,
        minutes: 5,
        seconds: 6,
      );
      expect(e.years, 1);
      expect(e.months, 2);
      expect(e.days, 3);
      expect(e.hours, 4);
      expect(e.minutes, 5);
      expect(e.seconds, 6);
    });
  });

  group('Stats model', () {
    test('constructs correctly', () {
      const s = Stats(
        resetCount: 5,
        longestStreakDays: 100,
        averageStreakDays: 50,
        daysSinceStart: 200,
      );
      expect(s.resetCount, 5);
      expect(s.longestStreakDays, 100);
      expect(s.averageStreakDays, 50);
      expect(s.daysSinceStart, 200);
    });
  });
}
