import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../constants/app_theme.dart';
import '../models/counter.dart';
import '../providers/counter_provider.dart';

/// Half-height bottom sheet for resetting a counter.
///
/// Matches `UI Images/counter_view_clicked_on_counter_detials_of_single_counter_clicked_on_reset_counter_button.PNG`:
/// - Header: "Cancel" left · "Reset Counter" centered · "Done" right
/// - "Reset on" row with tappable date + time chips (defaults to now)
/// - Note text field (optional)
class ResetSheet extends ConsumerStatefulWidget {
  final Counter counter;
  const ResetSheet({super.key, required this.counter});

  @override
  ConsumerState<ResetSheet> createState() => _ResetSheetState();
}

class _ResetSheetState extends ConsumerState<ResetSheet> {
  late DateTime _resetDate;
  late TimeOfDay _resetTime;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _resetDate = DateTime(now.year, now.month, now.day);
    _resetTime = TimeOfDay(hour: now.hour, minute: now.minute);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _resetAtMs {
    final dt = DateTime(
      _resetDate.year,
      _resetDate.month,
      _resetDate.day,
      _resetTime.hour,
      _resetTime.minute,
    );
    return dt.millisecondsSinceEpoch;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _resetDate,
      firstDate: DateTime.fromMillisecondsSinceEpoch(widget.counter.startedAt),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _resetDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _resetTime,
    );
    if (picked != null) setState(() => _resetTime = picked);
  }

  Future<void> _doReset() async {
    final note = _noteController.text.trim();
    await ref
        .read(countersNotifierProvider.notifier)
        .resetCounter(
          widget.counter.id,
          note: note.isEmpty ? null : note,
          resetAt: _resetAtMs,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kTextSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // Header: Cancel / Reset Counter / Done
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
                const Text(
                  'Reset Counter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _doReset,
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

            const SizedBox(height: 12),

            // Form card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: kCardColor,
                borderRadius: kCardRadius,
              ),
              child: Column(
                children: [
                  // "Reset on" row with date + time chips
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Text('Reset on', style: TextStyle(fontSize: 16)),
                        const Spacer(),
                        _ChipButton(
                          label: DateFormat('d MMM yyyy').format(_resetDate),
                          onTap: _pickDate,
                        ),
                        const SizedBox(width: 8),
                        _ChipButton(
                          label: _resetTime.format(context),
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),

                  const Divider(
                    height: 1,
                    color: kDividerColor,
                    indent: 16,
                    endIndent: 16,
                  ),

                  // Note text field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'Note',
                        hintStyle: TextStyle(color: kTextSecondary),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16),
                      maxLines: 3,
                      minLines: 1,
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

// ---------------------------------------------------------------------------
// Chip button — outlined pill for date/time selection
// ---------------------------------------------------------------------------

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
