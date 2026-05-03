import 'package:flutter_test/flutter_test.dart';
import 'package:streak_tracker/models/elapsed_time.dart';
import 'package:streak_tracker/utils/format_utils.dart';

void main() {
  group('formatDate', () {
    test('formats correctly', () {
      final ms = DateTime(1999, 1, 10).millisecondsSinceEpoch;
      expect(formatDate(ms), '10 Jan 1999');
    });

    test('formats single-digit day', () {
      final ms = DateTime(2026, 3, 5).millisecondsSinceEpoch;
      expect(formatDate(ms), '5 Mar 2026');
    });
  });

  group('formatShortDate', () {
    test('formats correctly', () {
      final ms = DateTime(2026, 1, 10).millisecondsSinceEpoch;
      expect(formatShortDate(ms), '10 Jan');
    });
  });

  group('formatTime', () {
    test('formats AM time correctly', () {
      final ms = DateTime(2026, 1, 10, 7, 26).millisecondsSinceEpoch;
      expect(formatTime(ms), '7:26 AM');
    });

    test('formats PM time correctly', () {
      final ms = DateTime(2026, 1, 10, 19, 26).millisecondsSinceEpoch;
      expect(formatTime(ms), '7:26 PM');
    });
  });

  group('formatDuration', () {
    test('formats full duration', () {
      const e = ElapsedTime(
        years: 27,
        months: 3,
        days: 22,
        hours: 0,
        minutes: 0,
        seconds: 0,
      );
      expect(formatDuration(e), '27 Years, 3 Months, 22 Days');
    });

    test('returns 0 Seconds for zero elapsed', () {
      const e = ElapsedTime(
        years: 0,
        months: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
      );
      expect(formatDuration(e), '0 Seconds');
    });

    test('handles singular units', () {
      const e = ElapsedTime(
        years: 1,
        months: 1,
        days: 1,
        hours: 1,
        minutes: 1,
        seconds: 1,
      );
      expect(formatDuration(e),
          '1 Year, 1 Month, 1 Day, 1 Hour, 1 Minute, 1 Second');
    });
  });

  group('formatPeriodLabel', () {
    test('capitalizes period names', () {
      expect(formatPeriodLabel('hours'), 'Hours');
      expect(formatPeriodLabel('days'), 'Days');
      expect(formatPeriodLabel('weeks'), 'Weeks');
      expect(formatPeriodLabel('months'), 'Months');
      expect(formatPeriodLabel('years'), 'Years');
    });

    test('passes through unknown period', () {
      expect(formatPeriodLabel('custom'), 'custom');
    });
  });
}
