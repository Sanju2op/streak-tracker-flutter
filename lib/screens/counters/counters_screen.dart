import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_theme.dart';
import '../../models/counter.dart';
import '../../providers/counter_provider.dart';
import '../../providers/db_provider.dart';
import '../../widgets/counter_card.dart';
import '../../widgets/empty_state.dart';

// ---------------------------------------------------------------------------
// Sort preference — simple StateProvider, no persistence yet (Phase 10.5)
// ---------------------------------------------------------------------------

enum CounterSortOption { dateAdded, nameAZ, streakLength }

final counterSortProvider = StateProvider<CounterSortOption>(
  (ref) => CounterSortOption.dateAdded,
);

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
      backgroundColor: kBgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.sort, color: kAccentBlue),
          onPressed: () => _showSortDialog(context, ref),
        ),
        title: const Text('Counters'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: kAccentBlue),
            onPressed: () => _openCreateSheet(context),
          ),
        ],
      ),
      body: countersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (counters) {
          if (counters.isEmpty) {
            return EmptyState(onAddCounter: () => _openCreateSheet(context));
          }

          final sorted = _sortCounters(counters, sortOption);
          return _CounterGrid(counters: sorted, ref: ref);
        },
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    // TODO(3.7): Wire to CreateEditSheet via showModalBottomSheet
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
        ref.read(counterSortProvider.notifier).state = selected;
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

class _CounterGridState extends ConsumerState<_CounterGrid> {
  /// Cache of last reset date per counter id.
  final Map<String, int?> _lastResetDates = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadLastResetDates();
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 4,
        childAspectRatio: 0.78, // square card + title + subtitle below
      ),
      itemCount: widget.counters.length,
      itemBuilder: (_, index) {
        final counter = widget.counters[index];
        return CounterCard(
          counter: counter,
          lastResetDate: _loaded ? _lastResetDates[counter.id] : null,
        );
      },
    );
  }
}
