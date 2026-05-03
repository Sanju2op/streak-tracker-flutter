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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (final (value, label) in _tabs) ...[
          _TabItem(
            label: label,
            isSelected: selected == value,
            onTap: () => onChanged(value),
          ),
          if (value != 'years') const SizedBox(width: 4),
        ],
      ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kTextPrimary, width: 1.2),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? kTextPrimary : kTextSecondary,
          ),
        ),
      ),
    );
  }
}
