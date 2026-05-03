import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_theme.dart';
import '../../models/counter.dart';
import '../../providers/counter_provider.dart';
import '../../providers/db_provider.dart';
import '../../widgets/counter_card.dart';
import '../../sheets/create_edit_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../utils/widget_utils.dart';

// ---------------------------------------------------------------------------
// Sort preference — persistent Notifier
// ---------------------------------------------------------------------------

enum CounterSortOption { dateAdded, nameAZ, streakLength }

final counterSortProvider = NotifierProvider<CounterSortNotifier, CounterSortOption>(
  CounterSortNotifier.new,
);

class CounterSortNotifier extends Notifier<CounterSortOption> {
  static const _key = 'st_counter_sort';

  @override
  CounterSortOption build() {
    // Initial state is dateAdded, will be updated by load()
    _load();
    return CounterSortOption.dateAdded;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key);
    if (index != null && index < CounterSortOption.values.length) {
      state = CounterSortOption.values[index];
    }
  }

  Future<void> setSort(CounterSortOption option) async {
    state = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, option.index);
  }
}

// ---------------------------------------------------------------------------
// Counters Screen
// ---------------------------------------------------------------------------

class CountersScreen extends ConsumerWidget {
  const CountersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countersAsync = ref.watch(countersNotifierProvider);
    final sortOption = ref.watch(counterSortProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: countersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (counters) {
          final sorted = _sortCounters(counters, sortOption);
          updateHomeWidgets(sorted);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: context.bgColor.withValues(alpha: 0.8),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.sort, color: kAccentBlue),
                  onPressed: () => _showSortDialog(context, ref),
                ),
                title: Text(
                  'Counters',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add, color: kAccentBlue),
                    onPressed: () => _openCreateSheet(context),
                  ),
                ],
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              if (counters.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(onAddCounter: () => _openCreateSheet(context)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 32),
                  sliver: _CounterGrid(counters: sorted, ref: ref),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    openCreateEditSheet(context);
  }

  void _showSortDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(counterSortProvider);
    showDialog<CounterSortOption>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Sort Counters'),
        children: [
          _sortOption(ctx, 'Date added', CounterSortOption.dateAdded, current),
          _sortOption(ctx, 'Name A→Z', CounterSortOption.nameAZ, current),
          _sortOption(
            ctx,
            'Streak length',
            CounterSortOption.streakLength,
            current,
          ),
        ],
      ),
    ).then((selected) {
      if (selected != null) {
        ref.read(counterSortProvider.notifier).setSort(selected);
      }
    });
  }

  Widget _sortOption(
    BuildContext ctx,
    String label,
    CounterSortOption option,
    CounterSortOption current,
  ) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(ctx, option),
      child: Row(
        children: [
          if (option == current)
            const Icon(Icons.check, color: kAccentBlue, size: 20)
          else
            const SizedBox(width: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  List<Counter> _sortCounters(
    List<Counter> counters,
    CounterSortOption option,
  ) {
    final copy = List<Counter>.from(counters);
    switch (option) {
      case CounterSortOption.dateAdded:
        // newest first (largest createdAt first)
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case CounterSortOption.nameAZ:
        copy.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case CounterSortOption.streakLength:
        // longest streak = smallest startedAt (started earliest)
        copy.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    }
    return copy;
  }
}

// ---------------------------------------------------------------------------
// Counter Grid — loads last-reset dates for subtitle display
// ---------------------------------------------------------------------------

class _CounterGrid extends ConsumerStatefulWidget {
  final List<Counter> counters;
  final WidgetRef ref;

  const _CounterGrid({required this.counters, required this.ref});

  @override
  ConsumerState<_CounterGrid> createState() => _CounterGridState();
}

class _CounterGridState extends ConsumerState<_CounterGrid> with SingleTickerProviderStateMixin {
  /// Cache of last reset date per counter id.
  final Map<String, int?> _lastResetDates = {};
  bool _loaded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadLastResetDates();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CounterGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-load if counter list changed (e.g. after a reset)
    if (oldWidget.counters != widget.counters) {
      _loadLastResetDates();
    }
  }

  Future<void> _loadLastResetDates() async {
    final db = ref.read(dbAdapterProvider);
    final dates = <String, int?>{};
    for (final counter in widget.counters) {
      final resets = await db.getResets(counter.id);
      if (resets.isNotEmpty) {
        // Most recent reset
        resets.sort((a, b) => b.resetAt.compareTo(a.resetAt));
        dates[counter.id] = resets.first.resetAt;
      } else {
        dates[counter.id] = null;
      }
    }
    if (mounted) {
      setState(() {
        _lastResetDates
          ..clear()
          ..addAll(dates);
        _loaded = true;
        _animationController.forward(from: 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rowCount = (widget.counters.length / 2).ceil();

    return SliverList.builder(
      itemCount: rowCount,
      itemBuilder: (_, rowIndex) {
        final index1 = rowIndex * 2;
        final index2 = index1 + 1;

        final hasSecond = index2 < widget.counters.length;

        final counter1 = widget.counters[index1];
        final card1 = CounterCard(
          counter: counter1,
          lastResetDate: _loaded ? _lastResetDates[counter1.id] : null,
          isFullWidth: !hasSecond,
        );

        Widget row;
        if (!hasSecond) {
          row = Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: card1,
          );
        } else {
          final counter2 = widget.counters[index2];
          final card2 = CounterCard(
            counter: counter2,
            lastResetDate: _loaded ? _lastResetDates[counter2.id] : null,
            isFullWidth: false,
          );

          row = Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: card1),
                const SizedBox(width: 12),
                Expanded(child: card2),
              ],
            ),
          );
        }

        final start = rowIndex * 0.1;
        final end = (start + 0.5).clamp(0.0, 1.0);

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final curve = CurvedAnimation(
              parent: _animationController,
              curve: Interval(start, end, curve: Curves.easeOutCubic),
            );

            return Opacity(
              opacity: curve.value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - curve.value)),
                child: child,
              ),
            );
          },
          child: row,
        );
      },
    );
  }
}
