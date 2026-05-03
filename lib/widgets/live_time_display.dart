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

class _LiveTimeDisplayState extends State<LiveTimeDisplay> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late ElapsedTime _elapsed;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

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
    _pulseController.forward().then((_) => _pulseController.reverse());
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
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
        ScaleTransition(
          scale: _pulseAnimation,
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
