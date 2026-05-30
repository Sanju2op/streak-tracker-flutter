import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

/// The 5-option segmented time-unit selector shown on the counter detail screen.
///
/// Options: Hours · Days · Weeks · Months · Years.
/// Active tab: black bold text wrapped in a rounded container with a thin border.
/// Inactive: grey text, no border.
///
/// See `UI Images/counter_view_clicked_on_counter_detials_of_single_counter_1.PNG`.
class TimeTabSelector extends StatelessWidget {
  /// The currently selected period: 'hours' | 'days' | 'weeks' | 'months' | 'years'.
  final String selected;

  /// Called with the newly tapped period value.
  final ValueChanged<String> onChanged;

  const TimeTabSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _tabs = [
    ('hours', 'Hours'),
    ('days', 'Days'),
    ('weeks', 'Weeks'),
    ('months', 'Months'),
    ('years', 'Years'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            context.bgColor, // Use context extension for theme-aware background
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (final (value, label) in _tabs)
            Expanded(
              child: _TabItem(
                label: label,
                isSelected: selected == value,
                onTap: () => onChanged(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? context.textPrimary : context.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
      ),
    );
  }
}
