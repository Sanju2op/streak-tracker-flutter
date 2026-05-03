import '../models/elapsed_time.dart';

/// Computes the elapsed time between two Unix-millisecond timestamps,
/// accounting for variable month and year lengths via DateTime arithmetic.
///
/// Returns an [ElapsedTime] with years, months, days, hours, minutes, seconds
/// — each field is the *remainder* after extracting the larger units.
ElapsedTime getElapsed(int startMs, int nowMs) {
  // Guard: if start is in the future, return all zeros.
  if (nowMs <= startMs) {
    return const ElapsedTime(
      years: 0,
      months: 0,
      days: 0,
      hours: 0,
      minutes: 0,
      seconds: 0,
    );
  }

  final start = DateTime.fromMillisecondsSinceEpoch(startMs);
  final now = DateTime.fromMillisecondsSinceEpoch(nowMs);

  // --- Years ---
  int years = now.year - start.year;
  // Adjust if we haven't reached the anniversary month/day/time yet.
  DateTime anniversary = _addYears(start, years);
  if (anniversary.isAfter(now)) {
    years--;
    anniversary = _addYears(start, years);
  }

  // --- Months ---
  int months =
      (now.year - anniversary.year) * 12 + (now.month - anniversary.month);
  DateTime monthMark = _addMonths(anniversary, months);
  if (monthMark.isAfter(now)) {
    months--;
    monthMark = _addMonths(anniversary, months);
  }

  // --- Days, hours, minutes, seconds from the remaining Duration ---
  final remaining = now.difference(monthMark);
  int totalSeconds = remaining.inSeconds;

  final int days = totalSeconds ~/ 86400;
  totalSeconds -= days * 86400;
  final int hours = totalSeconds ~/ 3600;
  totalSeconds -= hours * 3600;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds - minutes * 60;

  return ElapsedTime(
    years: years,
    months: months,
    days: days,
    hours: hours,
    minutes: minutes,
    seconds: seconds,
  );
}

// ---------------------------------------------------------------------------
// Unit-specific helpers — return the total elapsed time expressed as a single
// fractional unit.  Used by TimeTabSelector for single-unit display.
// ---------------------------------------------------------------------------

/// Total elapsed time expressed in hours (fractional).
double getElapsedInHours(int startMs, int nowMs) {
  if (nowMs <= startMs) return 0.0;
  return (nowMs - startMs) / (1000 * 60 * 60);
}

/// Total elapsed time expressed in days (fractional).
double getElapsedInDays(int startMs, int nowMs) {
  if (nowMs <= startMs) return 0.0;
  return (nowMs - startMs) / (1000 * 60 * 60 * 24);
}

/// Total elapsed time expressed in weeks (fractional).
double getElapsedInWeeks(int startMs, int nowMs) {
  if (nowMs <= startMs) return 0.0;
  return (nowMs - startMs) / (1000 * 60 * 60 * 24 * 7);
}

// ---------------------------------------------------------------------------
// Private helpers — safe month/year addition that clamps the day to the last
// valid day of the target month (e.g. Jan 31 + 1 month → Feb 28/29).
// ---------------------------------------------------------------------------

DateTime _addYears(DateTime dt, int years) {
  final targetYear = dt.year + years;
  final maxDay = _daysInMonth(targetYear, dt.month);
  final day = dt.day > maxDay ? maxDay : dt.day;
  return DateTime(
    targetYear,
    dt.month,
    day,
    dt.hour,
    dt.minute,
    dt.second,
    dt.millisecond,
  );
}

DateTime _addMonths(DateTime dt, int months) {
  final totalMonths = dt.month - 1 + months;
  final targetYear = dt.year + totalMonths ~/ 12;
  final targetMonth = totalMonths % 12 + 1;
  final maxDay = _daysInMonth(targetYear, targetMonth);
  final day = dt.day > maxDay ? maxDay : dt.day;
  return DateTime(
    targetYear,
    targetMonth,
    day,
    dt.hour,
    dt.minute,
    dt.second,
    dt.millisecond,
  );
}

int _daysInMonth(int year, int month) {
  // DateTime(year, month + 1, 0) gives the last day of `month`.
  return DateTime(year, month + 1, 0).day;
}
