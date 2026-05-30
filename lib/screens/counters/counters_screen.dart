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
import '../../widgets/error_state.dart';

// ---------------------------------------------------------------------------
// Sort preference — persistent Notifier
// ---------------------------------------------------------------------------

enum CounterSortOption { dateAdded, nameAZ, streakLength }

final counterSortProvider =
    NotifierProvider<CounterSortNotifier, CounterSortOption>(
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
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(countersNotifierProvider)),
        data: (counters) {
          final sorted = _sortCounters(counters, sortOption);
          updateHomeWidgets(sorted);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.sort, color: kAccentBlue, size: 22),
                  onPressed: () => _showSortDialog(context, ref),
                ),
                title: Text(
                  'Counters',
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add, color: kAccentBlue, size: 26),
                    onPressed: () => _openCreateSheet(context),
                  ),
                ],
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.bgColor.withValues(alpha: 0.80),
                        border: Border(
                          bottom: BorderSide(
                            color: context.dividerColor.withValues(alpha: 0.4),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (counters.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    onAddCounter: () => _openCreateSheet(context),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
    showGeneralDialog<CounterSortOption>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.8,
              decoration: BoxDecoration(
                color: context.cardColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort Counters',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sortOption(
                    ctx,
                    'Date added',
                    CounterSortOption.dateAdded,
                    current,
                  ),
                  _sortOption(
                    ctx,
                    'Name A→Z',
                    CounterSortOption.nameAZ,
                    current,
                  ),
                  _sortOption(
                    ctx,
                    'Streak length',
                    CounterSortOption.streakLength,
                    current,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12 * anim1.value,
            sigmaY: 12 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(scale: curve, child: child),
          ),
        );
      },
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
    final isSelected = option == current;
    return InkWell(
      onTap: () => Navigator.pop(ctx, option),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? kAccentBlue.withValues(alpha: 0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? kAccentBlue
                      : ctx.textSecondary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: kAccentBlue, size: 14)
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? ctx.textPrimary : ctx.textSecondary,
              ),
            ),
          ],
        ),
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

class _CounterGridState extends ConsumerState<_CounterGrid>
    with SingleTickerProviderStateMixin {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900
        ? 4
        : screenWidth > 600
        ? 3
        : 2;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final counter = widget.counters[index];
        final start = (index * 0.05).clamp(0.0, 0.30);
        final end = (start + 0.4).clamp(0.0, 1.0);

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
                offset: Offset(0, 20 * (1 - curve.value)),
                child: Transform.scale(
                  scale: 0.95 + (0.05 * curve.value),
                  child: child,
                ),
              ),
            );
          },
          child: CounterCard(
            counter: counter,
            lastResetDate: _loaded ? _lastResetDates[counter.id] : null,
            isFullWidth: false,
          ),
        );
      }, childCount: widget.counters.length),
    );
  }
}
