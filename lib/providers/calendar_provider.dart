import 'package:flutter_riverpod/flutter_riverpod.dart';

final calendarNotifierProvider =
    NotifierProvider<CalendarNotifier, CalendarState>(CalendarNotifier.new);

class CalendarState {
  final DateTime selectedDate;
  final List<String> filterIds;

  const CalendarState({required this.selectedDate, required this.filterIds});

  CalendarState copyWith({DateTime? selectedDate, List<String>? filterIds}) {
    return CalendarState(
      selectedDate: selectedDate ?? this.selectedDate,
      filterIds: filterIds ?? this.filterIds,
    );
  }
}

class CalendarNotifier extends Notifier<CalendarState> {
  @override
  CalendarState build() {
    return CalendarState(
      selectedDate: _dateOnly(DateTime.now()),
      filterIds: const [],
    );
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: _dateOnly(date));
  }

  void setFilter(List<String> ids) {
    state = state.copyWith(filterIds: List.unmodifiable(ids));
  }

  void clearFilter() {
    state = state.copyWith(filterIds: const []);
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
