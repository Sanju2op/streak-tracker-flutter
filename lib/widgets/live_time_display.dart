import 'dart:async';

import 'package:flutter/material.dart';

import '../models/elapsed_time.dart';
import '../utils/time_utils.dart';

/// A live-ticking display that shows the elapsed time since [startedAt].
///
/// On the counter card it shows the primary unit value only (e.g. "27" with
/// "years" below) based on [period]. When used in other contexts (e.g. the
/// create/edit sheet preview) it can expose the full [ElapsedTime] via
/// [builder].
///
/// **Always cancel timer in `dispose()`** — memory leak if missed.
class LiveTimeDisplay extends StatefulWidget {
  /// Unix milliseconds — the streak start timestamp.
  final int startedAt;

  /// The counter's display period: 'hours' | 'days' | 'weeks' | 'months' | 'years'.
  final String period;

  /// Optional custom builder that receives the current [ElapsedTime].
  /// When provided, the default card display is bypassed.
  final Widget Function(BuildContext context, ElapsedTime elapsed)? builder;

  const LiveTimeDisplay({
    super.key,
    required this.startedAt,
    required this.period,
    this.builder,
  });

  @override
  State<LiveTimeDisplay> createState() => _LiveTimeDisplayState();
}

class _LiveTimeDisplayState extends State<LiveTimeDisplay> {
  late Timer _timer;
  late ElapsedTime _elapsed;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant LiveTimeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt) {
      _tick();
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _elapsed = getElapsed(
        widget.startedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(context, _elapsed);
    }

    final (value, label) = _primaryValueAndLabel(_elapsed, widget.period);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$value',
            style:
                Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(color: Colors.white) ??
                const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -2.0,
                ),
          ),
        ),
        const SizedBox(height: 0),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

/// Returns the primary value and its label for the given [period].
///
/// For example, a counter with `period = 'years'` shows the total years as
/// the big number and "years" as the label — matching the UI reference where
/// each card shows "27 / years".
(int, String) _primaryValueAndLabel(ElapsedTime e, String period) {
  switch (period) {
    case 'hours':
      // Total hours = years→months→days→hours collapsed
      final totalHours =
          ((e.years * 365.25 + e.months * 30.44 + e.days) * 24 + e.hours)
              .round();
      return (totalHours, totalHours == 1 ? 'hour' : 'hours');
    case 'days':
      final totalDays = (e.years * 365.25 + e.months * 30.44 + e.days).round();
      return (totalDays, totalDays == 1 ? 'day' : 'days');
    case 'weeks':
      final totalWeeks = ((e.years * 365.25 + e.months * 30.44 + e.days) / 7)
          .round();
      return (totalWeeks, totalWeeks == 1 ? 'week' : 'weeks');
    case 'months':
      final totalMonths = e.years * 12 + e.months;
      return (totalMonths, totalMonths == 1 ? 'month' : 'months');
    case 'years':
    default:
      return (e.years, e.years == 1 ? 'year' : 'years');
  }
}
