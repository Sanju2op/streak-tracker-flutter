import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../constants/app_theme.dart';

import '../models/counter.dart';
import '../models/reset.dart';
import '../utils/time_utils.dart';
import 'edit_reset_sheet.dart';

void showResetDrawerSheet(
  BuildContext context, {
  required Counter counter,
  required Reset reset,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ResetDrawerSheet(counter: counter, reset: reset),
  );
}

class _ResetDrawerSheet extends StatelessWidget {
  final Counter counter;
  final Reset reset;

  const _ResetDrawerSheet({required this.counter, required this.reset});

  @override
  Widget build(BuildContext context) {
    final startDt = DateTime.fromMillisecondsSinceEpoch(
      reset.previousStartedAt,
    );
    final endDt = DateTime.fromMillisecondsSinceEpoch(reset.resetAt);
    const formatStr = 'd MMM yyyy';
    final dateRange =
        '${DateFormat(formatStr).format(startDt)} - ${DateFormat(formatStr).format(endDt)}';

    final elapsed = getElapsed(reset.previousStartedAt, reset.resetAt);
    final totalDays =
        (elapsed.years * 365.25 + elapsed.months * 30.44 + elapsed.days)
            .round();

    return Container(
      decoration: const BoxDecoration(
        color: kBgColor,
        borderRadius: kSheetRadius,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kTextSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: kAccentBlue, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.pop();
                      showEditResetSheet(
                        context,
                        counter: counter,
                        reset: reset,
                      );
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: kAccentBlue, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Card 1
              Container(
                decoration: const BoxDecoration(
                  color: kCardColor,
                  borderRadius: kCardRadius,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                counter.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateRange,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: kAccentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {},
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.ios_share,
                                      color: kAccentBlue,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Share',
                                      style: TextStyle(
                                        color: kAccentBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _StatCol(value: totalDays, label: 'Days'),
                        _StatCol(value: elapsed.hours, label: 'Hours'),
                        _StatCol(value: elapsed.minutes, label: 'Minutes'),
                        _StatCol(value: elapsed.seconds, label: 'Seconds'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 2
              Container(
                decoration: const BoxDecoration(
                  color: kCardColor,
                  borderRadius: kCardRadius,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Reset on',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('d MMM yyyy h:mm a').format(endDt),
                      style: const TextStyle(fontSize: 16, color: kTextPrimary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final int value;
  final String label;

  const _StatCol({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}
