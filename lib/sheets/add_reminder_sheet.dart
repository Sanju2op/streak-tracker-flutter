import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_theme.dart';
import '../models/reminder.dart';
import '../providers/counter_provider.dart';
import '../providers/reminder_provider.dart';
import '../utils/notification_utils.dart';
import '../utils/uuid_utils.dart';

class AddReminderSheet extends ConsumerStatefulWidget {
  final String counterId;

  const AddReminderSheet({super.key, required this.counterId});

  @override
  ConsumerState<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<AddReminderSheet> {
  TimeOfDay _time = TimeOfDay.now();
  String _repeatMode = 'daily';

  final List<String> _repeatModes = ['none', 'daily', 'weekly'];

  void _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) {
      setState(() => _time = t);
    }
  }

  Future<void> _save() async {
    await requestPermission();

    final countersAsync = ref.read(countersNotifierProvider);
    final counter = countersAsync.value?.firstWhere(
      (c) => c.id == widget.counterId,
    );
    if (counter == null) return;

    final id = generateId();
    final reminder = Reminder(
      id: id,
      counterId: widget.counterId,
      time: _time,
      repeatMode: _repeatMode,
      isEnabled: true,
    );

    await ref
        .read(remindersNotifierProvider(widget.counterId).notifier)
        .addReminder(reminder);

    if (_repeatMode != 'none') {
      final interval = _repeatMode == 'weekly'
          ? RepeatInterval.weekly
          : RepeatInterval.daily;

      await scheduleReminder(
        id: id,
        counterTitle: counter.title,
        repeat: interval,
      );
    }

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
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
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
                  'Add Reminder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
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
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: kCardRadius,
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Time'),
                    trailing: ActionChip(
                      label: Text(_time.format(context)),
                      onPressed: _pickTime,
                      backgroundColor: context.bgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide.none,
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: context.dividerColor,
                  ),
                  ListTile(
                    title: const Text('Repeat'),
                    trailing: DropdownButton<String>(
                      value: _repeatMode,
                      underline: const SizedBox(),
                      items: _repeatModes.map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(
                            mode[0].toUpperCase() + mode.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _repeatMode = val);
                      },
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
