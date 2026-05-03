import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../constants/app_theme.dart';
import '../../constants/colors.dart';
import '../../models/counter.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/counter_provider.dart';
import '../../sheets/filter_sheet.dart';
import '../../utils/calendar_utils.dart';
import '../../widgets/calendar_day_cell.dart';
import '../../widgets/calendar_streak_list_item.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countersAsync = ref.watch(countersNotifierProvider);
    final resetsAsync = ref.watch(allResetsProvider);
    final calendarState = ref.watch(calendarNotifierProvider);

    final counters = countersAsync.value ?? [];
    final resets = resetsAsync.value ?? [];

    DateTime firstDay = DateTime.now().subtract(const Duration(days: 365 * 2));
    if (counters.isNotEmpty) {
      final earliest = counters
          .map((c) => c.startedAt)
          .reduce((a, b) => a < b ? a : b);
      final earliestDate = DateTime.fromMillisecondsSinceEpoch(earliest);
      if (earliestDate.isBefore(firstDay)) {
        firstDay = earliestDate;
      }
    }

    final dayColors = buildDayColorMap(
      counters,
      resets,
      calendarState.filterIds,
    );

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.w600, color: kTextPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => _openFilterSheet(context),
            child: const Text(
              'Filter',
              style: TextStyle(color: kAccentBlue, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: firstDay,
            lastDay: DateTime.now(),
            focusedDay: calendarState.selectedDate,
            currentDay: DateTime.now(),
            selectedDayPredicate: (day) =>
                isSameDay(day, calendarState.selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              ref
                  .read(calendarNotifierProvider.notifier)
                  .setSelectedDate(selectedDay);
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: false,
              leftChevronVisible: false,
              rightChevronVisible: false,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              weekendStyle: TextStyle(
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final colors = dayColors[_dateOnly(day)] ?? [];
                return CalendarDayCell(day: day, colors: colors);
              },
              selectedBuilder: (context, day, focusedDay) {
                final colors = dayColors[_dateOnly(day)] ?? [];
                return CalendarDayCell(
                  day: day,
                  isSelected: true,
                  colors: colors,
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final colors = dayColors[_dateOnly(day)] ?? [];
                return CalendarDayCell(day: day, isToday: true, colors: colors);
              },
              outsideBuilder: (context, day, focusedDay) => const SizedBox(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      top: 20,
                      bottom: 8,
                    ),
                    child: Text(
                      '${calendarState.selectedDate.day} ${_monthName(calendarState.selectedDate.month)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildDayList(
                      counters,
                      dayColors,
                      calendarState.selectedDate,
                      calendarState.filterIds,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayList(
    List<Counter> counters,
    Map<DateTime, List<Color>> dayColors,
    DateTime selectedDate,
    List<String> filterIds,
  ) {
    // Use the dayColors map to determine which counters are active on this day.
    // The dayColors map was built by buildDayColorMap which correctly handles
    // all streak ranges including reset history.
    final selectedKey = _dateOnly(selectedDate);
    final colorsForDay = dayColors[selectedKey] ?? [];

    // If day is in the future, show nothing
    if (selectedDate.isAfter(DateTime.now())) {
      return const Center(
        child: Text(
          'No counters on this day',
          style: TextStyle(color: kTextSecondary),
        ),
      );
    }

    // Filter counters that are active on this day by checking if their color
    // appears in the dayColors map for the selected date
    final activeCounters = counters.where((c) {
      if (filterIds.isNotEmpty && !filterIds.contains(c.id)) {
        return false;
      }
      final counterColor = hexToColor(c.color);
      return colorsForDay.contains(counterColor);
    }).toList();

    if (activeCounters.isEmpty) {
      return const Center(
        child: Text(
          'No counters on this day',
          style: TextStyle(color: kTextSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: activeCounters.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 40, color: kDividerColor),
      itemBuilder: (context, index) {
        return CalendarStreakListItem(counter: activeCounters[index]);
      },
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _monthName(int month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[month - 1];
}
