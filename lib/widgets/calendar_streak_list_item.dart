import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_theme.dart';
import '../constants/colors.dart';
import '../models/counter.dart';

class CalendarStreakListItem extends StatelessWidget {
  final Counter counter;

  const CalendarStreakListItem({super.key, required this.counter});

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(counter.color);

    final startMs = counter.startedAt;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diff = nowMs - startMs;

    final totalDays = diff ~/ 86400000;
    final remainderMs = diff % 86400000;
    final hours = remainderMs ~/ 3600000;
    final minutes = (remainderMs % 3600000) ~/ 60000;

    return InkWell(
      onTap: () => context.push('/counters/${counter.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counter.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day $totalDays of $totalDays Days, $hours Hours, $minutes Minutes',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
