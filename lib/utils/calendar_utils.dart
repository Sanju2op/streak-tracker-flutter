import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/counter.dart';
import '../models/reset.dart';

Map<DateTime, List<Color>> buildDayColorMap(
  List<Counter> counters,
  List<Reset> resets,
  List<String> filterIds,
) {
  final filterSet = filterIds.toSet();
  final colorsByDay = <DateTime, List<Color>>{};
  final now = DateTime.now().millisecondsSinceEpoch;

  for (final counter in counters) {
    if (filterSet.isNotEmpty && !filterSet.contains(counter.id)) continue;

    final color = hexToColor(counter.color);
    final counterResets = resets.where(
      (reset) => reset.counterId == counter.id,
    );
    for (final reset in counterResets) {
      _addRange(colorsByDay, reset.previousStartedAt, reset.resetAt, color);
    }
    _addRange(colorsByDay, counter.startedAt, now, color);
  }

  return colorsByDay;
}

void _addRange(
  Map<DateTime, List<Color>> colorsByDay,
  int startMs,
  int endMs,
  Color color,
) {
  if (endMs < startMs) return;

  var day = _dateOnly(DateTime.fromMillisecondsSinceEpoch(startMs));
  final endDay = _dateOnly(DateTime.fromMillisecondsSinceEpoch(endMs));

  while (!day.isAfter(endDay)) {
    final colors = colorsByDay.putIfAbsent(day, () => <Color>[]);
    if (!colors.contains(color)) colors.add(color);
    day = day.add(const Duration(days: 1));
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
