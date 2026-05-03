import 'package:flutter_test/flutter_test.dart';
import 'package:streak_tracker/utils/time_utils.dart';

void main() {
  group('getElapsed', () {
    test('returns all zeros when start equals now', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final e = getElapsed(now, now);
      expect(e.years, 0);
      expect(e.months, 0);
      expect(e.days, 0);
      expect(e.hours, 0);
      expect(e.minutes, 0);
      expect(e.seconds, 0);
    });

    test('returns all zeros when start is in the future', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final future = now + 86400000;
      final e = getElapsed(future, now);
      expect(e.years, 0);
      expect(e.months, 0);
      expect(e.days, 0);
    });

    test('correctly computes days', () {
      final start = DateTime(2026, 5, 1).millisecondsSinceEpoch;
      final end = DateTime(2026, 5, 4).millisecondsSinceEpoch;
      final e = getElapsed(start, end);
      expect(e.years, 0);
      expect(e.months, 0);
      expect(e.days, 3);
      expect(e.hours, 0);
    });

    test('correctly computes months and days', () {
      final start = DateTime(2026, 1, 15).millisecondsSinceEpoch;
      final end = DateTime(2026, 3, 20).millisecondsSinceEpoch;
      final e = getElapsed(start, end);
      expect(e.years, 0);
      expect(e.months, 2);
      expect(e.days, 5);
    });

    test('correctly computes years, months, days', () {
      final start = DateTime(1999, 1, 10).millisecondsSinceEpoch;
      final end = DateTime(2026, 4, 2).millisecondsSinceEpoch;
      final e = getElapsed(start, end);
      expect(e.years, 27);
      expect(e.months, 2);
      expect(e.days, 23);
    });

    test('handles leap year correctly', () {
      final start = DateTime(2024, 2, 28).millisecondsSinceEpoch;
      final end = DateTime(2024, 3, 1).millisecondsSinceEpoch;
      final e = getElapsed(start, end);
      // Feb 28 to Mar 1 in 2024 (leap year) = 2 days
      expect(e.days, 2);
      expect(e.months, 0);
    });

    test('handles non-leap year February correctly', () {
      final start = DateTime(2025, 2, 28).millisecondsSinceEpoch;
      final end = DateTime(2025, 3, 1).millisecondsSinceEpoch;
      final e = getElapsed(start, end);
      // Feb 28 to Mar 1 in 2025 (non-leap) = 1 day
      expect(e.days, 1);
      expect(e.months, 0);
    });

    test('correctly computes hours, minutes, seconds', () {
      final start = DateTime(2026, 5, 1, 10, 30, 0).millisecondsSinceEpoch;
      final end = DateTime(2026, 5, 1, 14, 45, 30).millisecondsSinceEpoch;
      final e = getElapsed(start, end);
      expect(e.hours, 4);
      expect(e.minutes, 15);
      expect(e.seconds, 30);
    });
  });

  group('getElapsedInHours', () {
    test('returns 0 when start is in the future', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(getElapsedInHours(now + 1000, now), 0.0);
    });

    test('returns correct hours for 1 day', () {
      final start = DateTime.now().millisecondsSinceEpoch;
      final end = start + 86400000;
      expect(getElapsedInHours(start, end), closeTo(24.0, 0.01));
    });
  });

  group('getElapsedInDays', () {
    test('returns 0 when start is in the future', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(getElapsedInDays(now + 1000, now), 0.0);
    });

    test('returns correct days for 1 week', () {
      final start = DateTime.now().millisecondsSinceEpoch;
      final end = start + 86400000 * 7;
      expect(getElapsedInDays(start, end), closeTo(7.0, 0.01));
    });
  });

  group('getElapsedInWeeks', () {
    test('returns 0 when start is in the future', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(getElapsedInWeeks(now + 1000, now), 0.0);
    });

    test('returns correct weeks for 14 days', () {
      final start = DateTime.now().millisecondsSinceEpoch;
      final end = start + 86400000 * 14;
      expect(getElapsedInWeeks(start, end), closeTo(2.0, 0.01));
    });
  });
}
