import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_theme.dart';
import '../models/goal.dart';
import '../providers/goal_provider.dart';
import '../utils/uuid_utils.dart';
import '../utils/sheet_utils.dart';

/// Half-height bottom sheet for creating a goal.
///
/// Shows "Target" row (value + unit selector) and an optional "Note" row.
class SetGoalSheet extends ConsumerStatefulWidget {
  final String counterId;

  const SetGoalSheet({super.key, required this.counterId});

  @override
  ConsumerState<SetGoalSheet> createState() => _SetGoalSheetState();
}

class _SetGoalSheetState extends ConsumerState<SetGoalSheet> {
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedUnit = 'Days';

  static const _units = ['Days', 'Weeks', 'Months', 'Years'];

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final val = int.tryParse(_valueController.text.trim());
    return val != null && val > 0;
  }

  Future<void> _save() async {
    if (!_canSave) return;

    final targetValue = int.parse(_valueController.text.trim());
    final note = _noteController.text.trim();
    final now = DateTime.now().millisecondsSinceEpoch;

    final goal = Goal(
      id: generateId(),
      counterId: widget.counterId,
      targetValue: targetValue,
      targetUnit: _selectedUnit.toLowerCase(),
      note: note.isEmpty ? null : note,
      isCompleted: false,
      createdAt: now,
    );

    await ref
        .read(goalsNotifierProvider(widget.counterId).notifier)
        .addGoal(goal);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showUnitPicker() {
    showAppBottomSheet(
      context: context,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: kSheetRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Select Unit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 16),
            ..._units.map((unit) {
              return ListTile(
                title: Text(unit, style: TextStyle(color: context.textPrimary)),
                trailing: unit == _selectedUnit
                    ? const Icon(Icons.check, color: kAccentBlue)
                    : null,
                onTap: () {
                  setState(() => _selectedUnit = unit);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.bgColor,
          borderRadius: kSheetRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: kAccentBlue, fontSize: 16),
                  ),
                ),
                Text(
                  'Set a goal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _canSave ? _save : null,
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: _canSave ? kAccentBlue : context.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Form card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: kCardRadius,
              ),
              child: Column(
                children: [
                  // Target Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text('Target', style: TextStyle(fontSize: 16, color: context.textPrimary)),
                        const Spacer(),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _valueController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Value',
                              hintStyle: TextStyle(color: context.textSecondary),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(color: context.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showUnitPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.bgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedUnit,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: context.dividerColor,
                    indent: 16,
                    endIndent: 16,
                  ),

                  // Note Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Note',
                        hintStyle: TextStyle(color: context.textSecondary),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(fontSize: 16, color: context.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
