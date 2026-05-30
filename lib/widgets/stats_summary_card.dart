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
  final String period;

  const StatsSummaryCard({
    super.key,
    required this.stats,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: kCardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Top row
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatCell(
                    value: '${stats.resetCount}',
                    label: 'Resets',
                  ),
                ),
                VerticalDivider(
                  color: context.dividerColor.withValues(alpha: 0.5),
                  thickness: 1,
                  width: 32,
                ),
                Expanded(
                  child: _StatCell(
                    value: _formatDays(stats.daysSinceStart, period),
                    label: 'Since started',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: context.dividerColor.withValues(alpha: 0.5),
              thickness: 1,
            ),
          ),
          // Bottom row
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatCell(
                    value: _formatDays(stats.longestStreakDays, period),
                    label: 'Longest Streak',
                  ),
                ),
                VerticalDivider(
                  color: context.dividerColor.withValues(alpha: 0.5),
                  thickness: 1,
                  width: 32,
                ),
                Expanded(
                  child: _StatCell(
                    value: _formatDays(stats.averageStreakDays, period),
                    label: 'Average Streak',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formats the days into the requested period.
  String _formatDays(int days, String period) {
    if (days == 0) {
      final unit = period == 'days' ? 'days' : period;
      return '0 $unit';
    }

    switch (period) {
      case 'hours':
        final h = days * 24;
        return '$h ${h == 1 ? 'hour' : 'hours'}';
      case 'weeks':
        final w = (days / 7).round();
        return '$w ${w == 1 ? 'week' : 'weeks'}';
      case 'months':
        final m = (days / 30.44).round();
        return '$m ${m == 1 ? 'month' : 'months'}';
      case 'years':
        final y = (days / 365.25).round();
        return '$y ${y == 1 ? 'year' : 'years'}';
      case 'days':
      default:
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: context.textSecondary),
        ),
      ],
    );
  }
}
