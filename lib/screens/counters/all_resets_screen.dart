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
import '../../utils/time_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

    if (mounted) {
      setState(() {
        _resets = resets;
        _counter = counter;
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
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
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
        title: const Text(
          'All Resets',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: kTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _resets.isEmpty && counter != null
          ? _buildStartedOnlyView(counter)
          : _buildListView(counter),
    );
  }

  /// When there are no resets, just show the "Started on" entry.
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
            monthLabel: key,
            resets: resetsInGroup,
            resetCount: resetsInGroup.length,
          );
        } else {
          // "Started on" entry at the bottom
          return _StartedOnCard(
            startedAt: counter!.startedAt,
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
  final String monthLabel;
  final List<Reset> resets;
  final int resetCount;

  const _ResetGroupCard({
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
        decoration: const BoxDecoration(
          color: kCardColor,
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$resetCount',
                    style: const TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                ],
              ),
            ),

            // Reset entries
            for (var i = 0; i < resets.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  color: kDividerColor,
                  indent: 16,
                  endIndent: 16,
                ),
              _ResetEntry(reset: resets[i]),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ResetEntry extends StatelessWidget {
  final Reset reset;

  const _ResetEntry({required this.reset});

  @override
  Widget build(BuildContext context) {
    // Compute previous streak duration
    final elapsed = getElapsed(reset.previousStartedAt, reset.resetAt);
    final durationText = _formatStreakDuration(elapsed);
    final resetDt = DateTime.fromMillisecondsSinceEpoch(reset.resetAt);
    final dateTimeText =
        '${DateFormat('d MMM yyyy').format(resetDt)} ${DateFormat('h:mm a').format(resetDt)}';

    return Padding(
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
                    const Icon(Icons.access_time, color: kAccentBlue, size: 16),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: kTextPrimary,
                  ),
                ),
                // Note if present
                if (reset.note != null &&
                    reset.note!.isNotEmpty) // safe — guarded by null check
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      reset.note!, // safe — guarded by null check above
                      style: const TextStyle(
                        fontSize: 13,
                        color: kTextSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: kTextSecondary, size: 22),
        ],
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
        decoration: const BoxDecoration(
          color: kCardColor,
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextSecondary,
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
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: kTextSecondary,
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
