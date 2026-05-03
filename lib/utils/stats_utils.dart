import 'dart:math';

import 'package:fl_chart/fl_chart.dart';

import '../models/counter.dart';
import '../models/reset.dart';
import '../models/stats.dart';

Stats computeStats(Counter counter, List<Reset> resets) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final currentStreakDays = _daysBetween(counter.startedAt, now);
  final streakDays = <int>[
    for (final reset in resets)
      _daysBetween(reset.previousStartedAt, reset.resetAt),
    currentStreakDays,
  ];

  final totalDays = streakDays.fold<int>(0, (sum, days) => sum + days);

  // daysSinceStart uses createdAt (the original counter creation date)
  // not startedAt which gets updated on every reset
  final originalStartMs = resets.isEmpty
      ? counter.startedAt
      : resets.map((r) => r.previousStartedAt).reduce((a, b) => a < b ? a : b);

  return Stats(
    resetCount: resets.length,
    longestStreakDays: streakDays.isEmpty ? 0 : streakDays.reduce(max),
    averageStreakDays: streakDays.isEmpty ? 0 : totalDays ~/ streakDays.length,
    daysSinceStart: _daysBetween(originalStartMs, now),
  );
}

List<BarChartGroupData> buildBarChartData(List<Reset> resets, String period) {
  return switch (period) {
    'daily' => _buildDailyGroups(resets),
    'weekly' => _buildWeeklyGroups(resets),
    'yearly' => _buildYearlyGroups(resets),
    _ => <BarChartGroupData>[],
  };
}

List<BarChartGroupData> _buildDailyGroups(List<Reset> resets) {
  final counts = List<int>.filled(7, 0);
  for (final reset in resets) {
    final date = DateTime.fromMillisecondsSinceEpoch(reset.resetAt);
    counts[date.weekday - 1]++;
  }

  return [
    for (var index = 0; index < counts.length; index++)
      _barGroup(index, counts[index]),
  ];
}

List<BarChartGroupData> _buildWeeklyGroups(List<Reset> resets) {
  final now = _dateOnly(DateTime.now());
  final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStarts = [
    for (var offset = 11; offset >= 0; offset--)
      currentWeekStart.subtract(Duration(days: offset * 7)),
  ];
  final counts = List<int>.filled(weekStarts.length, 0);

  for (final reset in resets) {
    final date = _dateOnly(DateTime.fromMillisecondsSinceEpoch(reset.resetAt));
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final index = weekStarts.indexWhere((start) => start == weekStart);
    if (index >= 0) counts[index]++;
  }

  return [
    for (var index = 0; index < counts.length; index++)
      _barGroup(index, counts[index]),
  ];
}

List<BarChartGroupData> _buildYearlyGroups(List<Reset> resets) {
  final nowYear = DateTime.now().year;
  if (resets.isEmpty) {
    return [_barGroup(nowYear, 0)];
  }

  final firstYear = resets
      .map((reset) => DateTime.fromMillisecondsSinceEpoch(reset.resetAt).year)
      .reduce(min);
  final counts = <int, int>{
    for (var year = firstYear; year <= nowYear; year++) year: 0,
  };

  for (final reset in resets) {
    final year = DateTime.fromMillisecondsSinceEpoch(reset.resetAt).year;
    counts[year] = (counts[year] ?? 0) + 1;
  }

  return [
    for (final entry in counts.entries) _barGroup(entry.key, entry.value),
  ];
}

BarChartGroupData _barGroup(int x, int count) {
  return BarChartGroupData(
    x: x,
    barRods: [BarChartRodData(toY: count.toDouble())],
  );
}

int _daysBetween(int startMs, int endMs) {
  if (endMs <= startMs) return 0;
  return DateTime.fromMillisecondsSinceEpoch(
    endMs,
  ).difference(DateTime.fromMillisecondsSinceEpoch(startMs)).inDays;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
