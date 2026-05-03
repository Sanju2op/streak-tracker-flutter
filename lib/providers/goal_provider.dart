import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import 'db_provider.dart';

final goalsNotifierProvider =
    AsyncNotifierProvider.family<GoalsNotifier, List<Goal>, String>(
      GoalsNotifier.new,
    );

class GoalsNotifier extends FamilyAsyncNotifier<List<Goal>, String> {
  @override
  Future<List<Goal>> build(String counterId) async {
    final db = ref.read(dbAdapterProvider);
    await db.init();
    return db.getGoals(counterId);
  }

  Future<void> addGoal(Goal goal) async {
    await ref.read(dbAdapterProvider).insertGoal(goal);
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(String id) async {
    final db = ref.read(dbAdapterProvider);
    final goals = await db.getGoals(arg);
    final goal = goals.where((item) => item.id == id).firstOrNull;
    if (goal == null) return;

    await db.updateGoal(goal.copyWith(isCompleted: !goal.isCompleted));
    ref.invalidateSelf();
  }

  Future<void> deleteGoal(String id) async {
    await ref.read(dbAdapterProvider).deleteGoal(id);
    ref.invalidateSelf();
  }
}
