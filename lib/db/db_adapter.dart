import '../models/counter.dart';
import '../models/goal.dart';
import '../models/reset.dart';

abstract class DbAdapter {
  Future<void> init();

  // Counters
  Future<List<Counter>> getCounters();
  Future<Counter?> getCounter(String id);
  Future<void> insertCounter(Counter counter);
  Future<void> updateCounter(Counter counter);
  Future<void> deleteCounter(String id);

  // Resets
  Future<List<Reset>> getResets(String counterId);
  Future<void> insertReset(Reset reset);
  Future<void> updateReset(Reset reset);
  Future<void> deleteReset(String id);

  // Goals
  Future<List<Goal>> getGoals(String counterId);
  Future<void> insertGoal(Goal goal);
  Future<void> updateGoal(Goal goal);
  Future<void> deleteGoal(String id);
}
