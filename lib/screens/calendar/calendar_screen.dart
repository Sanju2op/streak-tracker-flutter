import 'dart:ui';

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
import '../../utils/sheet_utils.dart';
import '../../widgets/calendar_day_cell.dart';
import '../../widgets/calendar_streak_list_item.dart';
import '../../widgets/error_state.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  void _openFilterSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      fullHeight: true,
      child: const FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countersAsync = ref.watch(countersNotifierProvider);
    final resetsAsync = ref.watch(allResetsProvider);
    final calendarState = ref.watch(calendarNotifierProvider);

    if (countersAsync.isLoading || resetsAsync.isLoading) {
      return Scaffold(
        backgroundColor: context.bgColor,
        body: CustomScrollView(
          slivers: [
            _CalendarAppBar(onFilter: () => _openFilterSheet(context)),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    final error = countersAsync.error ?? resetsAsync.error;
    if (error != null) {
      return Scaffold(
        backgroundColor: context.bgColor,
        body: CustomScrollView(
          slivers: [
            _CalendarAppBar(onFilter: () => _openFilterSheet(context)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorState(
                onRetry: () {
                  ref.invalidate(countersNotifierProvider);
                  ref.invalidate(allResetsProvider);
                },
              ),
            ),
          ],
        ),
      );
    }

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
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        slivers: [
          _CalendarAppBar(onFilter: () => _openFilterSheet(context)),
          SliverToBoxAdapter(
            child: TableCalendar(
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
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: false,
                leftChevronVisible: false,
                rightChevronVisible: false,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: context.textSecondary,
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
                  return CalendarDayCell(
                    day: day,
                    isToday: true,
                    colors: colors,
                  );
                },
                outsideBuilder: (context, day, focusedDay) => const SizedBox(),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      '${calendarState.selectedDate.day} '
                      '${_monthName(calendarState.selectedDate.month)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildDayList(
                      context,
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
    BuildContext context,
    List<Counter> counters,
    Map<DateTime, List<Color>> dayColors,
    DateTime selectedDate,
    List<String> filterIds,
  ) {
    final selectedKey = _dateOnly(selectedDate);
    final colorsForDay = dayColors[selectedKey] ?? [];

    if (selectedDate.isAfter(DateTime.now())) {
      return Center(
        child: Text(
          'No counters on this day',
          style: TextStyle(color: context.textSecondary),
        ),
      );
    }

    final activeCounters = counters.where((c) {
      if (filterIds.isNotEmpty && !filterIds.contains(c.id)) {
        return false;
      }
      final counterColor = hexToColor(c.color);
      return colorsForDay.contains(counterColor);
    }).toList();

    if (activeCounters.isEmpty) {
      return Center(
        child: Text(
          'No counters on this day',
          style: TextStyle(color: context.textSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: activeCounters.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 40, color: context.dividerColor),
      itemBuilder: (context, index) {
        return CalendarStreakListItem(counter: activeCounters[index]);
      },
    );
  }
}

class _CalendarAppBar extends StatelessWidget {
  final VoidCallback onFilter;

  const _CalendarAppBar({required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: context.bgColor.withValues(alpha: 0.1),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        'Calendar',
        style: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      actions: [
        TextButton(
          onPressed: onFilter,
          child: const Text(
            'Filter',
            style: TextStyle(
              color: kAccentBlue,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.dividerColor.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
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
