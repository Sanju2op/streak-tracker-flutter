import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
class CounterCard extends StatefulWidget {
  final Counter counter;
  final int? lastResetDate;
  final bool isFullWidth;

  const CounterCard({
    super.key,
    required this.counter,
    this.lastResetDate,
    this.isFullWidth = false,
  });

  @override
  State<CounterCard> createState() => _CounterCardState();
}

class _CounterCardState extends State<CounterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(widget.counter.color);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () => context.push('/counters/${widget.counter.id}'),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: kCardRadius,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: kCardRadius,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              HSLColor.fromColor(color)
                                  .withLightness(
                                    (HSLColor.fromColor(color).lightness - 0.10)
                                        .clamp(0.0, 1.0),
                                  )
                                  .toColor(),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: -30,
                        bottom: -20,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -10,
                        bottom: 10,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LiveTimeDisplay(
                          startedAt: widget.counter.startedAt,
                          period: widget.counter.period,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.counter.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: context.textPrimary,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _subtitle(),
              style: TextStyle(color: context.textSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    if (widget.lastResetDate != null) {
      return 'Reset on ${formatShortDate(widget.lastResetDate!)}';
    }
    return 'Started on ${formatShortDate(widget.counter.startedAt)}';
  }
}
