import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/counter.dart';
import '../models/reset.dart';
import '../utils/uuid_utils.dart';
import 'db_provider.dart';

final countersNotifierProvider =
    AsyncNotifierProvider<CountersNotifier, List<Counter>>(
      CountersNotifier.new,
    );

class CountersNotifier extends AsyncNotifier<List<Counter>> {
  @override
  Future<List<Counter>> build() async {
    final db = ref.read(dbAdapterProvider);
    await db.init();
    return db.getCounters();
  }

  Future<void> addCounter(Counter counter) async {
    await ref.read(dbAdapterProvider).insertCounter(counter);
    ref.invalidateSelf();
  }

  Future<void> updateCounter(Counter counter) async {
    await ref.read(dbAdapterProvider).updateCounter(counter);
    ref.invalidateSelf();
  }

  Future<void> deleteCounter(String id) async {
    await ref.read(dbAdapterProvider).deleteCounter(id);
    ref.invalidateSelf();
  }

  Future<void> resetCounter(String id, {String? note, int? resetAt}) async {
    final db = ref.read(dbAdapterProvider);
    final counter = await db.getCounter(id);
    if (counter == null) return;

    final now = resetAt ?? DateTime.now().millisecondsSinceEpoch;
    final reset = Reset(
      id: generateId(),
      counterId: id,
      resetAt: now,
      note: note,
      previousStartedAt: counter.startedAt,
      createdAt: now,
    );

    await db.insertReset(reset);
    await db.updateCounter(counter.copyWith(startedAt: now, updatedAt: now));
    ref.invalidateSelf();
  }
}
