import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../providers/goal_provider.dart';
import '../../sheets/set_goal_sheet.dart';
import '../../utils/sheet_utils.dart';
import '../../widgets/error_state.dart';

class GoalsScreen extends ConsumerWidget {
  final String counterId;

  const GoalsScreen({super.key, required this.counterId});

  void _openSetGoalSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      fullHeight: true,
      child: SetGoalSheet(counterId: counterId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsNotifierProvider(counterId));

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
          'Goals',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          onRetry: () => ref.invalidate(goalsNotifierProvider(counterId)),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No goals set',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Challenge yourself',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => _openSetGoalSheet(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kAccentBlue,
                      side: const BorderSide(color: kAccentBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add Goal'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return Dismissible(
                key: Key(goal.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Goal'),
                      content: const Text(
                        'Are you sure you want to delete this goal?',
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
                onDismissed: (_) {
                  ref
                      .read(goalsNotifierProvider(counterId).notifier)
                      .deleteGoal(goal.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: kCardRadius,
                  ),
                  child: ListTile(
                    title: Text(
                      '${goal.targetValue} ${goal.targetUnit[0].toUpperCase()}${goal.targetUnit.substring(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: goal.isCompleted
                            ? context.textSecondary
                            : context.textPrimary,
                        decoration: goal.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: goal.note != null && goal.note!.isNotEmpty
                        ? Text(
                            goal.note!,
                            style: TextStyle(
                              color: context.textSecondary,
                              decoration: goal.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          )
                        : null,
                    trailing: Checkbox(
                      value: goal.isCompleted,
                      activeColor: kAccentBlue,
                      onChanged: (_) {
                        ref
                            .read(goalsNotifierProvider(counterId).notifier)
                            .toggleComplete(goal.id);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: goalsAsync.maybeWhen(
        data: (goals) => goals.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => _openSetGoalSheet(context),
                backgroundColor: kAccentBlue,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}
