import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../models/counter.dart';
import '../../models/elapsed_time.dart';
import '../../models/reset.dart';
import '../../providers/counter_provider.dart';
import '../../providers/db_provider.dart';
import '../../sheets/reset_drawer_sheet.dart';
import '../../utils/time_utils.dart';
import '../../widgets/error_state.dart';

/// All Resets screen — shows the history of resets for a single counter,
/// grouped by month, with the original start date at the bottom.
///
/// See `UI Images/from_clicked_on_single_counter_all_resets_button_view.PNG`.
class AllResetsScreen extends ConsumerStatefulWidget {
  final String counterId;
  const AllResetsScreen({super.key, required this.counterId});

  @override
  ConsumerState<AllResetsScreen> createState() => _AllResetsScreenState();
}

class _AllResetsScreenState extends ConsumerState<AllResetsScreen> {
  List<Reset> _resets = [];
  Counter? _counter;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final db = ref.read(dbAdapterProvider);
      final resets = await db.getResets(widget.counterId);

      // Sort most recent first
      resets.sort((a, b) => b.resetAt.compareTo(a.resetAt));

      // Get the counter from the provider
      final countersAsync = ref.read(countersNotifierProvider);
      final counter = countersAsync.whenOrNull(
        data: (list) {
          try {
            return list.firstWhere((c) => c.id == widget.counterId);
          } catch (_) {
            return null;
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _resets = resets;
        _counter = counter;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for counter updates (e.g. after returning from edit)
    final countersAsync = ref.watch(countersNotifierProvider);
    final counter =
        countersAsync.whenOrNull(
          data: (list) {
            try {
              return list.firstWhere((c) => c.id == widget.counterId);
            } catch (_) {
              return null;
            }
          },
        ) ??
        _counter;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leadingWidth: 100,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.chevron_left, color: kAccentBlue, size: 28),
              Flexible(
                child: Text(
                  counter?.title ?? '',
                  style: const TextStyle(
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
        title: Text(
          'All Resets',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(onRetry: _load)
          : _resets.isEmpty && counter != null
          ? _buildStartedOnlyView(counter)
          : _buildListView(counter),
    );
  }

  /// When there are no resets, just show the "Started on" entry.
  /// Computes the original start date, accounting for resets.
  /// After resets, counter.startedAt is updated — the true original
  /// is the earliest previousStartedAt from all resets.
  int _originalStartDate(Counter counter) {
    if (_resets.isEmpty) return counter.startedAt;
    return _resets
        .map((r) => r.previousStartedAt)
        .reduce((a, b) => a < b ? a : b);
  }

  Widget _buildStartedOnlyView(Counter counter) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [_StartedOnCard(startedAt: counter.startedAt)],
    );
  }

  /// Build the full list: grouped reset entries + "Started on" at the bottom.
  Widget _buildListView(Counter? counter) {
    // Group resets by month/year
    final groups = <String, List<Reset>>{};
    for (final reset in _resets) {
      final dt = DateTime.fromMillisecondsSinceEpoch(reset.resetAt);
      final key = DateFormat('MMM yyyy').format(dt).toUpperCase();
      groups.putIfAbsent(key, () => []).add(reset);
    }

    final groupKeys = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // +1 for "Started on" card at the bottom
      itemCount: groupKeys.length + (counter != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < groupKeys.length) {
          final key = groupKeys[index];
          final resetsInGroup = groups[key]!; // safe — key from groups map
          return _ResetGroupCard(
            counter: counter!,
            monthLabel: key,
            resets: resetsInGroup,
            resetCount: resetsInGroup.length,
          );
        } else {
          // "Started on" entry at the bottom — use original start date
          return _StartedOnCard(
            startedAt: _originalStartDate(counter!),
          ); // safe — guarded by counter != null check in itemCount
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Reset group card — one card per month
// ---------------------------------------------------------------------------

class _ResetGroupCard extends StatelessWidget {
  final Counter counter;
  final String monthLabel;
  final List<Reset> resets;
  final int resetCount;

  const _ResetGroupCard({
    required this.counter,
    required this.monthLabel,
    required this.resets,
    required this.resetCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: kCardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$resetCount',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Reset entries
            for (var i = 0; i < resets.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: context.dividerColor,
                  indent: 16,
                  endIndent: 16,
                ),
              _ResetEntry(counter: counter, reset: resets[i]),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ResetEntry extends StatelessWidget {
  final Counter counter;
  final Reset reset;

  const _ResetEntry({required this.counter, required this.reset});

  @override
  Widget build(BuildContext context) {
    // Compute previous streak duration
    final elapsed = getElapsed(reset.previousStartedAt, reset.resetAt);
    final durationText = _formatStreakDuration(elapsed);
    final resetDt = DateTime.fromMillisecondsSinceEpoch(reset.resetAt);
    final dateTimeText =
        '${DateFormat('d MMM yyyy').format(resetDt)} ${DateFormat('h:mm a').format(resetDt)}';

    return InkWell(
      onTap: () =>
          showResetDrawerSheet(context, counter: counter, reset: reset),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streak duration with clock icon
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: kAccentBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          durationText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kAccentBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Reset date + time
                  Text(
                    dateTimeText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                  // Note if present
                  if (reset.note != null &&
                      reset.note!.isNotEmpty) // safe — guarded by null check
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        reset.note!, // safe — guarded by null check above
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  /// Format elapsed time as a compact streak duration string.
  /// E.g. "27 years 3 months" or "5 days 2 hours".
  String _formatStreakDuration(ElapsedTime e) {
    final parts = <String>[];
    if (e.years > 0) {
      parts.add('${e.years} ${e.years == 1 ? 'year' : 'years'}');
    }
    if (e.months > 0) {
      parts.add('${e.months} ${e.months == 1 ? 'month' : 'months'}');
    }
    if (e.days > 0 && parts.length < 2) {
      parts.add('${e.days} ${e.days == 1 ? 'day' : 'days'}');
    }
    if (e.hours > 0 && parts.length < 2) {
      parts.add('${e.hours} ${e.hours == 1 ? 'hour' : 'hours'}');
    }
    if (e.minutes > 0 && parts.length < 2) {
      parts.add('${e.minutes} ${e.minutes == 1 ? 'minute' : 'minutes'}');
    }
    if (parts.isEmpty) {
      parts.add('0 seconds');
    }
    return parts.join(' ');
  }
}

// ---------------------------------------------------------------------------
// "Started on" card — the original start date at the bottom of the list
// ---------------------------------------------------------------------------

class _StartedOnCard extends StatelessWidget {
  final int startedAt;

  const _StartedOnCard({required this.startedAt});

  @override
  Widget build(BuildContext context) {
    final startDt = DateTime.fromMillisecondsSinceEpoch(startedAt);
    final monthLabel = DateFormat('MMM yyyy').format(startDt).toUpperCase();
    final dateTimeText =
        '${DateFormat('d MMM yyyy').format(startDt)} ${DateFormat('h:mm a').format(startDt)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: kCardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // "Started on" entry
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Started on',
                          style: TextStyle(
                            fontSize: 14,
                            color: kAccentBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateTimeText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
