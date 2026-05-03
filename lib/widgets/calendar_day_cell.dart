import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final List<Color> colors;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.isSelected = false,
    this.isToday = false,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? kAccentBlue.withValues(alpha: 0.1)
            : Colors.transparent,
        border: isSelected
            ? Border.all(color: kAccentBlue, width: 1.5)
            : isToday
            ? Border.all(color: context.textSecondary.withValues(alpha: 0.3), width: 1)
            : null,
        borderRadius: BorderRadius.circular(6),
      ),
      margin: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: TextStyle(
              fontWeight: (isToday || isSelected)
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isSelected ? kAccentBlue : context.textPrimary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Column(
            children: colors.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                height: 2,
                width: double.infinity,
                color: c,
              );
            }).toList(),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
