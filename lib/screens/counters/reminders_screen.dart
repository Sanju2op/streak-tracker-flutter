import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../constants/app_theme.dart';
import '../../providers/counter_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../sheets/add_reminder_sheet.dart';
import '../../utils/notification_utils.dart';
import '../../utils/sheet_utils.dart';
import '../../widgets/error_state.dart';

class RemindersScreen extends ConsumerWidget {
  final String counterId;

  const RemindersScreen({super.key, required this.counterId});

  void _openAddReminderSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      fullHeight: true,
      child: AddReminderSheet(counterId: counterId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersNotifierProvider(counterId));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: kAccentBlue, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reminders',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          onRetry: () => ref.invalidate(remindersNotifierProvider(counterId)),
        ),
        data: (reminders) {
          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No reminders set',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => _openAddReminderSheet(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kAccentBlue,
                      side: const BorderSide(color: kAccentBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add Reminder'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Dismissible(
                key: Key(reminder.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Reminder'),
                      content: const Text(
                        'Are you sure you want to delete this reminder?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await cancelReminder(reminder.id);
                  ref
                      .read(remindersNotifierProvider(counterId).notifier)
                      .deleteReminder(reminder.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: kCardRadius,
                  ),
                  child: ListTile(
                    title: Text(
                      reminder.time.format(context),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      'Repeat: ${reminder.repeatMode[0].toUpperCase()}${reminder.repeatMode.substring(1)}',
                    ),
                    trailing: Switch(
                      value: reminder.isEnabled,
                      activeTrackColor: kAccentBlue.withValues(alpha: 0.5),
                      activeThumbColor: kAccentBlue,
                      onChanged: (val) async {
                        ref
                            .read(remindersNotifierProvider(counterId).notifier)
                            .toggleReminder(reminder.id);

                        if (val && reminder.repeatMode != 'none') {
                          final countersAsync = ref.read(
                            countersNotifierProvider,
                          );
                          final counter = countersAsync.value?.firstWhere(
                            (c) => c.id == counterId,
                          );
                          if (counter != null) {
                            final interval = reminder.repeatMode == 'weekly'
                                ? RepeatInterval.weekly
                                : RepeatInterval.daily;
                            await scheduleReminder(
                              id: reminder.id,
                              counterTitle: counter.title,
                              repeat: interval,
                            );
                          }
                        } else {
                          await cancelReminder(reminder.id);
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: remindersAsync.maybeWhen(
        data: (reminders) => reminders.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => _openAddReminderSheet(context),
                backgroundColor: kAccentBlue,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}
