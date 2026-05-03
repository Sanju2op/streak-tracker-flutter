import 'package:intl/intl.dart';

import '../models/elapsed_time.dart';

String formatDate(int ms) {
  return DateFormat(
    'd MMM yyyy',
  ).format(DateTime.fromMillisecondsSinceEpoch(ms));
}

String formatShortDate(int ms) {
  return DateFormat('d MMM').format(DateTime.fromMillisecondsSinceEpoch(ms));
}

String formatTime(int ms) {
  return DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(ms));
}

String formatDuration(ElapsedTime elapsed) {
  final parts = <String>[
    if (elapsed.years > 0) _unit(elapsed.years, 'Year'),
    if (elapsed.months > 0) _unit(elapsed.months, 'Month'),
    if (elapsed.days > 0) _unit(elapsed.days, 'Day'),
    if (elapsed.hours > 0) _unit(elapsed.hours, 'Hour'),
    if (elapsed.minutes > 0) _unit(elapsed.minutes, 'Minute'),
    if (elapsed.seconds > 0) _unit(elapsed.seconds, 'Second'),
  ];

  return parts.isEmpty ? '0 Seconds' : parts.join(', ');
}

String formatPeriodLabel(String period) {
  return switch (period) {
    'hours' => 'Hours',
    'days' => 'Days',
    'weeks' => 'Weeks',
    'months' => 'Months',
    'years' => 'Years',
    _ => period,
  };
}

String _unit(int value, String singular) {
  return '$value $singular${value == 1 ? '' : 's'}';
}
