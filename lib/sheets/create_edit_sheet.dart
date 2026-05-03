import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../constants/app_theme.dart';
import '../constants/colors.dart';
import '../models/counter.dart';
import '../providers/counter_provider.dart';
import '../utils/uuid_utils.dart';
import '../widgets/live_time_display.dart';
import '../utils/sheet_utils.dart';
import 'color_picker_sheet.dart';

/// Opens the create / edit counter sheet as a full-height modal bottom sheet.
///
/// When [counter] is null → create mode (form blank, all zeros).
/// When [counter] is provided → edit mode (form pre-filled, Delete button visible).
///
/// See `UI Images/Create-edit_Counters_view_slide_up.PNG` and
/// `create_edit_counters_view_2_filled.PNG`.
void openCreateEditSheet(BuildContext context, {Counter? counter}) {
  showAppBottomSheet(
    context: context,
    fullHeight: true,
    child: _CreateEditSheet(counter: counter),
  );
}

class _CreateEditSheet extends ConsumerStatefulWidget {
  final Counter? counter;
  const _CreateEditSheet({this.counter});

  @override
  ConsumerState<_CreateEditSheet> createState() => _CreateEditSheetState();
}

class _CreateEditSheetState extends ConsumerState<_CreateEditSheet> {
  late TextEditingController _titleController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late Color _color;
  bool get _isEditing => widget.counter != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.counter!; // safe — guarded by _isEditing
      _titleController = TextEditingController(text: c.title);
      final dt = DateTime.fromMillisecondsSinceEpoch(c.startedAt);
      _startDate = DateTime(dt.year, dt.month, dt.day);
      _startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      _color = hexToColor(c.color);
    } else {
      _titleController = TextEditingController();
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day);
      _startTime = TimeOfDay(hour: now.hour, minute: now.minute);
      _color = randomColor();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  int get _startedAtMs {
    final dt = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    return dt.millisecondsSinceEpoch;
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    final title = _titleController.text.trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    final hexColor = colorToHex(_color);

    if (_isEditing) {
      final updated = widget.counter!.copyWith(
        // safe — guarded by _isEditing
        title: title,
        color: hexColor,
        startedAt: _startedAtMs,
        updatedAt: now,
      );
      await ref.read(countersNotifierProvider.notifier).updateCounter(updated);
    } else {
      final counter = Counter(
        id: generateId(),
        title: title,
        color: hexColor,
        startedAt: _startedAtMs,
        period: 'years', // default display period
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(countersNotifierProvider.notifier).addCounter(counter);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Counter'),
        content: const Text(
          'Are you sure you want to delete this counter? This cannot be undone.',
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
          .deleteCounter(widget.counter!.id); // safe — guarded by _isEditing
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickColor() async {
    final picked = await showColorPickerSheet(context, currentColor: _color);
    if (picked != null) setState(() => _color = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: kSheetRadius,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          children: [
            // --- Drag handle ---
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),

            // --- Header: Cancel / Done ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: kAccentBlue, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: _canSave ? _save : null,
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: _canSave ? context.textPrimary : context.textSecondary,
                        fontSize: 16,
                        fontWeight: _canSave
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Scrollable body ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // --- Preview card ---
                    _PreviewCard(
                      color: _color,
                      title: _isEditing ? _titleController.text : null,
                      startedAt: _startedAtMs,
                    ),

                    const SizedBox(height: 16),

                    // --- Form card ---
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: kCardRadius,
                      ),
                      child: Column(
                        children: [
                          // Title field
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: TextField(
                              controller: _titleController,
                              maxLength: 50,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'e.g. No junk food',
                                hintStyle: TextStyle(color: context.textSecondary),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: context.textPrimary,
                              ),
                            ),
                          ),

                          Divider(
                            height: 1,
                            color: context.dividerColor,
                            indent: 16,
                            endIndent: 16,
                          ),

                          // "Started on" row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Started on',
                                  style: TextStyle(fontSize: 16, color: context.textPrimary),
                                ),
                                const Spacer(),
                                _ChipButton(
                                  label: DateFormat(
                                    'd MMM yyyy',
                                  ).format(_startDate),
                                  onTap: _pickDate,
                                ),
                                const SizedBox(width: 8),
                                _ChipButton(
                                  label: _startTime.format(context),
                                  onTap: _pickTime,
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

                          // "Pick a color" row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Pick a color',
                                  style: TextStyle(fontSize: 16, color: context.textPrimary),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _pickColor,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Delete Counter button (edit mode only) ---
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: kCardRadius,
                        ),
                        child: TextButton(
                          onPressed: _delete,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Delete Counter',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview card — accent color bg with translucent circle + 4-column live time
// ---------------------------------------------------------------------------

class _PreviewCard extends StatelessWidget {
  final Color color;
  final String? title;
  final int startedAt;

  const _PreviewCard({
    required this.color,
    this.title,
    required this.startedAt,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: kCardRadius,
      child: Container(
        width: double.infinity,
        height: 200,
        color: color,
        child: Stack(
          children: [
            // Translucent circle
            Positioned(
              left: -40,
              top: -20,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (edit mode only)
                  if (title != null &&
                      title!.isNotEmpty) // safe — guarded by null check
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        title!, // safe — guarded by null check above
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const Spacer(),

                  // 4-column live display
                  LiveTimeDisplay(
                    startedAt: startedAt,
                    period: 'years', // doesn't matter — we use custom builder
                    builder: (context, elapsed) {
                      return Row(
                        children: [
                          _TimeColumn(
                            value:
                                elapsed.days +
                                elapsed.months * 30 +
                                elapsed.years * 365,
                            label: 'Days',
                          ),
                          _TimeColumn(value: elapsed.hours, label: 'Hours'),
                          _TimeColumn(value: elapsed.minutes, label: 'Minutes'),
                          _TimeColumn(value: elapsed.seconds, label: 'Seconds'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final int value;
  final String label;

  const _TimeColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
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
          color: context.bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textPrimary),
        ),
      ),
    );
  }
}
