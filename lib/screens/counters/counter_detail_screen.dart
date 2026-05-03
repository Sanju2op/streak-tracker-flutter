import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../constants/colors.dart';
import '../../models/counter.dart';
import '../../models/elapsed_time.dart';
import '../../models/reset.dart';
import '../../models/stats.dart';
import '../../providers/counter_provider.dart';
import '../../providers/db_provider.dart';
import '../../sheets/create_edit_sheet.dart';
import '../../sheets/reset_sheet.dart';
import '../../utils/format_utils.dart';
import '../../utils/stats_utils.dart';
import '../../utils/time_utils.dart';
import '../../widgets/stats_summary_card.dart';
import '../../widgets/time_tab_selector.dart';

/// Full counter detail screen.
///
/// See `UI Images/counter_view_clicked_on_counter_detials_of_single_counter_1.PNG`
/// and `..._2_scrolled.PNG`.
class CounterDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const CounterDetailScreen({super.key, required this.id});

  @override
  ConsumerState<CounterDetailScreen> createState() =>
      _CounterDetailScreenState();
}

class _CounterDetailScreenState extends ConsumerState<CounterDetailScreen> {
  List<Reset> _resets = [];
  Stats _stats = const Stats(
    resetCount: 0,
    longestStreakDays: 0,
    averageStreakDays: 0,
    daysSinceStart: 0,
  );

  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _loadResets();
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 40;
      if (shouldShow != _showTitle) {
        setState(() => _showTitle = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadResets() async {
    final db = ref.read(dbAdapterProvider);
    final resets = await db.getResets(widget.id);
    if (!mounted) return;

    // We need the counter to compute stats — try to read from the provider
    final countersAsync = ref.read(countersNotifierProvider);
    final counter = countersAsync.whenOrNull(
      data: (list) {
        try {
          return list.firstWhere((c) => c.id == widget.id);
        } catch (_) {
          return null;
        }
      },
    );

    setState(() {
      _resets = resets;
      if (counter != null) {
        _stats = computeStats(counter, resets);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final countersAsync = ref.watch(countersNotifierProvider);

    return countersAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (counters) {
        final counter = counters.where((c) => c.id == widget.id).firstOrNull;
        if (counter == null) {
          // Counter was deleted — pop back
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Recompute stats when counter data changes
        _stats = computeStats(counter, _resets);

        final int? lastResetDate = _resets.isNotEmpty
            ? _resets.map((r) => r.resetAt).reduce((a, b) => a > b ? a : b)
            : null;

        final accentColor = hexToColor(counter.color);

        return Scaffold(
          backgroundColor: kBgColor,
          appBar: _buildAppBar(context, counter, accentColor),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // 1. Title block
                _TitleBlock(counter: counter, accentColor: accentColor),

                const SizedBox(height: 16),

                // 2. Current Streak card
                _CurrentStreakCard(
                  counter: counter,
                  lastResetDate: lastResetDate,
                  selectedPeriod: counter.period,
                  onPeriodChanged: (p) {
                    ref
                        .read(countersNotifierProvider.notifier)
                        .updateCounter(counter.copyWith(period: p));
                  },
                ),

                const SizedBox(height: 16),

                // 3. Reset Counter button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _openResetSheet(context, counter),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Reset Counter',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Menu list card
                _MenuListCard(counterId: counter.id, accentColor: accentColor),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StatsSummaryCard(
                    stats: _stats,
                    period: counter.period,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    Counter counter,
    Color accentColor,
  ) {
    return AppBar(
      backgroundColor: kBgColor,
      elevation: 0,
      leadingWidth: 120,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: const Row(
          children: [
            SizedBox(width: 8),
            Icon(Icons.chevron_left, color: kAccentBlue, size: 28),
            Flexible(
              child: Text(
                'Counters',
                style: TextStyle(
                  color: kAccentBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showTitle ? 1.0 : 0.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                counter.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () => openCreateEditSheet(context, counter: counter),
          child: const Text(
            'Edit',
            style: TextStyle(
              color: kAccentBlue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _openResetSheet(BuildContext context, Counter counter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(borderRadius: kSheetRadius),
      builder: (_) => ResetSheet(counter: counter),
    ).then((_) {
      // Reload resets after the sheet closes
      _loadResets();
    });
  }
}

// ---------------------------------------------------------------------------
// Title block — accent strip + counter name + start date
// ---------------------------------------------------------------------------

class _TitleBlock extends StatelessWidget {
  final Counter counter;
  final Color accentColor;

  const _TitleBlock({required this.counter, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent-colored vertical strip
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counter.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Started on ${formatDate(counter.startedAt)}',
                  style: const TextStyle(fontSize: 14, color: kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Current Streak card — header row, tab selector, 4-column breakdown
// ---------------------------------------------------------------------------

class _CurrentStreakCard extends StatefulWidget {
  final Counter counter;
  final int? lastResetDate;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const _CurrentStreakCard({
    required this.counter,
    this.lastResetDate,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  State<_CurrentStreakCard> createState() => _CurrentStreakCardState();
}

class _CurrentStreakCardState extends State<_CurrentStreakCard> {
  late Timer _timer;
  late ElapsedTime _elapsed;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _CurrentStreakCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.counter.startedAt != widget.counter.startedAt) {
      _tick();
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _elapsed = getElapsed(
        widget.counter.startedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // REQUIRED — memory leak if missing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = _buildColumnsForPeriod(widget.selectedPeriod, _elapsed);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: kCardColor,
          borderRadius: kCardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title + share button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Streak',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.lastResetDate != null
                            ? 'Reset on ${formatDate(widget.lastResetDate!)}'
                            : 'Started on ${formatDate(widget.counter.startedAt)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // Share functionality — placeholder for now
                  },
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kAccentBlue,
                    side: const BorderSide(color: kAccentBlue, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tab selector
            TimeTabSelector(
              selected: widget.selectedPeriod,
              onChanged: widget.onPeriodChanged,
            ),

            const SizedBox(height: 20),

            // 4-column breakdown
            Row(
              children: [
                for (final col in columns)
                  if (col.$2.isNotEmpty)
                    Expanded(
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${col.$1}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            col.$2,
                            style: const TextStyle(
                              fontSize: 13,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Returns 4 columns of (value, label) tuples based on the selected period.
  ///
  /// Per TASKS.md spec:
  /// - Hours: total hours / minutes / seconds / —
  /// - Days: days / hours / minutes / seconds
  /// - Weeks: weeks / days / hours / minutes
  /// - Months: months / days / hours / minutes
  /// - Years: years / months / days / hours  ← default
  List<(int, String)> _buildColumnsForPeriod(String period, ElapsedTime e) {
    switch (period) {
      case 'hours':
        final totalHours =
            ((e.years * 365.25 + e.months * 30.44 + e.days) * 24 + e.hours)
                .round();
        return [
          (totalHours, 'Hours'),
          (e.minutes, 'Minutes'),
          (e.seconds, 'Seconds'),
          (0, ''),
        ];
      case 'days':
        final totalDays = (e.years * 365.25 + e.months * 30.44 + e.days)
            .round();
        return [
          (totalDays, 'Days'),
          (e.hours, 'Hours'),
          (e.minutes, 'Minutes'),
          (e.seconds, 'Seconds'),
        ];
      case 'weeks':
        final totalDays = (e.years * 365.25 + e.months * 30.44 + e.days)
            .round();
        final weeks = totalDays ~/ 7;
        final remainingDays = totalDays % 7;
        return [
          (weeks, 'Weeks'),
          (remainingDays, 'Days'),
          (e.hours, 'Hours'),
          (e.minutes, 'Minutes'),
        ];
      case 'months':
        final totalMonths = e.years * 12 + e.months;
        return [
          (totalMonths, 'Months'),
          (e.days, 'Days'),
          (e.hours, 'Hours'),
          (e.minutes, 'Minutes'),
        ];
      case 'years':
      default:
        return [
          (e.years, 'Years'),
          (e.months, 'Months'),
          (e.days, 'Days'),
          (e.hours, 'Hours'),
        ];
    }
  }
}

// ---------------------------------------------------------------------------
// Menu list card — All Resets, Goals, Stats, Reminders
// ---------------------------------------------------------------------------

class _MenuListCard extends StatelessWidget {
  final String counterId;
  final Color accentColor;

  const _MenuListCard({required this.counterId, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: const BoxDecoration(
          color: kCardColor,
          borderRadius: kCardRadius,
        ),
        child: Column(
          children: [
            _MenuRow(
              icon: Icons.layers,
              label: 'All Resets',
              accentColor: accentColor,
              onTap: () => context.push('/counters/$counterId/resets'),
            ),
            const Divider(height: 1, color: kDividerColor, indent: 56),
            _MenuRow(
              icon: Icons.adjust,
              label: 'Goals',
              accentColor: accentColor,
              onTap: () => context.push('/counters/$counterId/goals'),
            ),
            const Divider(height: 1, color: kDividerColor, indent: 56),
            _MenuRow(
              icon: Icons.bar_chart,
              label: 'Stats',
              accentColor: accentColor,
              onTap: () => context.push('/counters/$counterId/stats'),
            ),
            const Divider(height: 1, color: kDividerColor, indent: 56),
            _MenuRow(
              icon: Icons.notifications,
              label: 'Reminders',
              accentColor: accentColor,
              onTap: () => context.push('/counters/$counterId/reminders'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container with rounded square accent background
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kTextPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: kTextSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}
