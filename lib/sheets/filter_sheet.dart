import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_theme.dart';
import '../constants/colors.dart';
import '../providers/calendar_provider.dart';
import '../providers/counter_provider.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(ref.read(calendarNotifierProvider).filterIds);
  }

  void _toggleAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _toggleCounter(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _save() {
    ref.read(calendarNotifierProvider.notifier).setFilter(_selectedIds);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final countersAsync = ref.watch(countersNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        color: kBgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kTextSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 60), // balance the Done button
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: kAccentBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: countersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (counters) {
                final isAll = _selectedIds.isEmpty;

                return ListView(
                  children: [
                    ListTile(
                      onTap: _toggleAll,
                      title: const Text(
                        'All Counters',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: isAll
                          ? const Icon(Icons.check, color: kAccentBlue)
                          : null,
                    ),
                    const Divider(height: 1, color: kDividerColor),
                    ...counters.map((c) {
                      final isSelected = _selectedIds.contains(c.id);
                      return ListTile(
                        onTap: () => _toggleCounter(c.id),
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: hexToColor(c.color),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        title: Text(c.title),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleCounter(c.id),
                          activeColor: kAccentBlue,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
