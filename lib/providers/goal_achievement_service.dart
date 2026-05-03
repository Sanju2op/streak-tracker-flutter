import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/counter.dart';
import '../models/goal.dart';
import '../providers/counter_provider.dart';
import '../providers/goal_provider.dart';
import '../utils/notification_utils.dart';

final goalAchievementServiceProvider = Provider<GoalAchievementService>((ref) {
  final service = GoalAchievementService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class GoalAchievementService extends WidgetsBindingObserver {
  final Ref ref;
  Timer? _timer;

  GoalAchievementService(this.ref) {
    WidgetsBinding.instance.addObserver(this);
    // Don't start timer in tests
    if (!kDebugMode ||
        WidgetsBinding.instance.runtimeType.toString() !=
            'AutomatedTestWidgetsFlutterBinding') {
      _startPeriodicCheck();
      // Do an initial check after a short delay to allow providers to initialize
      Future.delayed(const Duration(seconds: 3), _checkGoals);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkGoals();
    }
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkGoals();
    });
  }

  Future<void> _checkGoals() async {
    final countersAsync = ref.read(countersNotifierProvider);
    final counters = countersAsync.value ?? [];

    for (final counter in counters) {
      final goalsAsync = await ref.read(
        goalsNotifierProvider(counter.id).future,
      );

      for (final goal in goalsAsync) {
        if (!goal.isCompleted) {
          final achieved = _isGoalAchieved(counter, goal);
          if (achieved) {
            // Mark as complete
            await ref
                .read(goalsNotifierProvider(counter.id).notifier)
                .toggleComplete(goal.id);
            // Send notification
            await showGoalAchievedNotification(
              goalId: goal.id,
              counterTitle: counter.title,
              goalText: '${goal.targetValue} ${goal.targetUnit}',
            );
          }
        }
      }
    }
  }

  bool _isGoalAchieved(Counter counter, Goal goal) {
    final now = DateTime.now();
    final start = DateTime.fromMillisecondsSinceEpoch(counter.startedAt);

    DateTime targetDate;
    switch (goal.targetUnit) {
      case 'days':
        targetDate = start.add(Duration(days: goal.targetValue));
        break;
      case 'weeks':
        targetDate = start.add(Duration(days: goal.targetValue * 7));
        break;
      case 'months':
        targetDate = DateTime(
          start.year,
          start.month + goal.targetValue,
          start.day,
          start.hour,
          start.minute,
          start.second,
        );
        break;
      case 'years':
        targetDate = DateTime(
          start.year + goal.targetValue,
          start.month,
          start.day,
          start.hour,
          start.minute,
          start.second,
        );
        break;
      default:
        targetDate = now;
    }

    return now.isAfter(targetDate) || now.isAtSameMomentAs(targetDate);
  }
}
