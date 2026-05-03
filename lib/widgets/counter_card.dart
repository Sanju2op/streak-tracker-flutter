import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_theme.dart';
import '../constants/colors.dart';
import '../models/counter.dart';
import '../utils/format_utils.dart';
import 'live_time_display.dart';

/// A colored card showing the primary elapsed-time value for a counter.
///
/// Matches the design in `UI Images/Counters_Tab.PNG`:
/// - Square card (aspect ratio 1:1) with accent-color background
/// - Translucent white circle decoration (bottom-right, clipped)
/// - Large white number + unit label (top-left area)
/// - Below the card: bold title, grey subtitle
///
/// `lastResetDate` is the most recent reset timestamp (ms). When non-null
/// the subtitle reads "Reset on [date]" instead of "Started on [date]".
class CounterCard extends StatelessWidget {
  final Counter counter;

  /// Unix ms of the most recent reset (null if never reset).
  final int? lastResetDate;

  const CounterCard({
    super.key,
    required this.counter,
    this.lastResetDate,
  });

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(counter.color);

    return GestureDetector(
      onTap: () => context.push('/counters/${counter.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Square card ---
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: kCardRadius,
              child: Stack(
                children: [
                  // Solid accent background
                  Container(color: color),

                  // Translucent white circle — bottom-right, overflows
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),

                  // Number + unit label
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: LiveTimeDisplay(
                      startedAt: counter.startedAt,
                      period: counter.period,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Title + subtitle below the card ---
          const SizedBox(height: 6),
          Text(
            counter.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _subtitle(),
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// "Started on 10 Jan" or "Reset on 22 Feb"
  String _subtitle() {
    if (lastResetDate != null) {
      return 'Reset on ${formatShortDate(lastResetDate!)}'; // safe — guarded by null check
    }
    return 'Started on ${formatShortDate(counter.startedAt)}';
  }
}
