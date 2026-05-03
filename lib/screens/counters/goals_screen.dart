import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../providers/goal_provider.dart';
import '../../sheets/set_goal_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  final String counterId;

  const GoalsScreen({super.key, required this.counterId});

  void _openSetGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetGoalSheet(counterId: counterId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsNotifierProvider(counterId));

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: kAccentBlue, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Goals',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: kTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No goals set',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Challenge yourself',
                    style: TextStyle(fontSize: 14, color: kTextSecondary),
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
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref
                      .read(goalsNotifierProvider(counterId).notifier)
                      .deleteGoal(goal.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    color: kCardColor,
                    borderRadius: kCardRadius,
                  ),
                  child: ListTile(
                    title: Text(
                      '${goal.targetValue} ${goal.targetUnit[0].toUpperCase()}${goal.targetUnit.substring(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: goal.isCompleted ? kTextSecondary : kTextPrimary,
                        decoration: goal.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: goal.note != null && goal.note!.isNotEmpty
                        ? Text(
                            goal.note!,
                            style: TextStyle(
                              color: kTextSecondary,
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
