import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streak_tracker/db/web_adapter.dart';
import 'package:streak_tracker/models/counter.dart';
import 'package:streak_tracker/models/goal.dart';
import 'package:streak_tracker/models/reset.dart';

void main() {
  test('web adapter smoke test stores counters, resets, and goals', () async {
    SharedPreferences.setMockInitialValues({});

    final db = WebAdapter();
    await db.init();

    final now = DateTime(2026, 5, 3, 10).millisecondsSinceEpoch;
    final counterA = Counter(
      id: 'counter-a',
      title: 'No junk food',
      color: '#2ECC71',
      startedAt: now,
      period: 'days',
      createdAt: now,
      updatedAt: now,
    );
    final counterB = Counter(
      id: 'counter-b',
      title: 'Exercise',
      color: '#3A78ED',
      startedAt: now,
      period: 'weeks',
      createdAt: now + 1,
      updatedAt: now + 1,
    );

    await db.insertCounter(counterA);
    await db.insertCounter(counterB);
    await db.insertReset(
      Reset(
        id: 'reset-a',
        counterId: counterA.id,
        resetAt: now + Duration.millisecondsPerDay,
        note: 'Birthday',
        previousStartedAt: counterA.startedAt,
        createdAt: now + Duration.millisecondsPerDay,
      ),
    );
    await db.insertGoal(
      Goal(
        id: 'goal-a',
        counterId: counterA.id,
        targetValue: 30,
        targetUnit: 'days',
        note: 'First month',
        isCompleted: false,
        createdAt: now,
      ),
    );

    final counters = await db.getCounters();
    final resets = await db.getResets(counterA.id);
    final goals = await db.getGoals(counterA.id);

    debugPrint(
      'Smoke counters: ${counters.map((counter) => counter.title).join(', ')}',
    );
    debugPrint(
      'Smoke resets: ${resets.map((reset) => reset.note ?? '').join(', ')}',
    );
    debugPrint(
      'Smoke goals: ${goals.map((goal) => '${goal.targetValue} ${goal.targetUnit}').join(', ')}',
    );

    expect(counters, hasLength(2));
    expect(resets.single.note, 'Birthday');
    expect(goals.single.targetValue, 30);
  });
}
