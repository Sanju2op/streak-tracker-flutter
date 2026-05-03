import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../constants/app_theme.dart';

import '../models/counter.dart';
import '../models/reset.dart';
import '../providers/counter_provider.dart';

void showEditResetSheet(
  BuildContext context, {
  required Counter counter,
  required Reset reset,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditResetSheet(counter: counter, reset: reset),
  );
}

class _EditResetSheet extends ConsumerStatefulWidget {
  final Counter counter;
  final Reset reset;

  const _EditResetSheet({required this.counter, required this.reset});

  @override
  ConsumerState<_EditResetSheet> createState() => _EditResetSheetState();
}

class _EditResetSheetState extends ConsumerState<_EditResetSheet> {
  late DateTime _resetDate;
  late TimeOfDay _resetTime;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final dt = DateTime.fromMillisecondsSinceEpoch(widget.reset.resetAt);
    _resetDate = DateTime(dt.year, dt.month, dt.day);
    _resetTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    _noteController = TextEditingController(text: widget.reset.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _resetDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _resetDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _resetTime,
    );
    if (picked != null) {
      setState(() => _resetTime = picked);
    }
  }

  Future<void> _save() async {
    final dt = DateTime(
      _resetDate.year,
      _resetDate.month,
      _resetDate.day,
      _resetTime.hour,
      _resetTime.minute,
    );

    final updatedReset = Reset(
      id: widget.reset.id,
      counterId: widget.reset.counterId,
      resetAt: dt.millisecondsSinceEpoch,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      previousStartedAt: widget.reset.previousStartedAt,
      createdAt: widget.reset.createdAt,
    );

    await ref.read(countersNotifierProvider.notifier).updateReset(updatedReset);

    if (mounted) {
      context.pop(); // close this edit sheet
      context.pop(); // close the reset drawer sheet too
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reset'),
        content: const Text(
          'Are you sure you want to delete this reset? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(countersNotifierProvider.notifier)
          .deleteReset(widget.reset.id, widget.counter.id);

      if (mounted) {
        context.pop(); // close this edit sheet
        context.pop(); // close the reset drawer sheet too
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: kBgColor,
        borderRadius: kSheetRadius,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kTextSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: kAccentBlue, fontSize: 16),
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

              // Card 1
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: const BoxDecoration(
                    color: kCardColor,
                    borderRadius: kCardRadius,
                  ),
                  child: Column(
                    children: [
                      // "Reset on" row with chips
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Reset on',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            _ChipButton(
                              label: DateFormat(
                                'd MMM yyyy',
                              ).format(_resetDate),
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

                      // Note field
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card 2
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: kCardColor,
                    borderRadius: kCardRadius,
                  ),
                  child: TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Delete Reset',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

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
