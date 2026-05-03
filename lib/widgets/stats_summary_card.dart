import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../models/stats.dart';

/// Inline 2×2 stats grid shown at the bottom of the counter detail screen.
///
/// Always visible below the menu list card. Displays:
/// - Resets count
/// - Since started
/// - Longest Streak
/// - Average Streak
///
/// See `UI Images/counter_view_clicked_on_counter_detials_of_single_counter_2_scrolled.PNG`.
class StatsSummaryCard extends StatelessWidget {
  final Stats stats;

  const StatsSummaryCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: kCardColor,
        borderRadius: kCardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Top row
          Row(
            children: [
              Expanded(
                child: _StatCell(value: '${stats.resetCount}', label: 'Resets'),
              ),
              Expanded(
                child: _StatCell(
                  value: _formatDaysAsLargestUnit(stats.daysSinceStart),
                  label: 'Since started',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bottom row
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  value: _formatDaysAsLargestUnit(stats.longestStreakDays),
                  label: 'Longest Streak',
                ),
              ),
              Expanded(
                child: _StatCell(
                  value: _formatDaysAsLargestUnit(stats.averageStreakDays),
                  label: 'Average Streak',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Displays days in the largest human-friendly unit.
  /// E.g. 400 days → "1 year", 45 days → "1 month", 10 days → "10 days".
  /// Uses full unit labels as specified in ARCHITECTURE.md.
  String _formatDaysAsLargestUnit(int days) {
    if (days >= 365) {
      final years = days ~/ 365;
      return '$years ${years == 1 ? 'year' : 'years'}';
    } else if (days >= 30) {
      final months = days ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      return '$days ${days == 1 ? 'day' : 'days'}';
    }
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: kTextSecondary),
        ),
      ],
    );
  }
}
