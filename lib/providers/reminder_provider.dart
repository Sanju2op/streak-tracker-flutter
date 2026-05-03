import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder.dart';

final remindersNotifierProvider =
    AsyncNotifierProviderFamily<RemindersNotifier, List<Reminder>, String>(
      RemindersNotifier.new,
    );

class RemindersNotifier extends FamilyAsyncNotifier<List<Reminder>, String> {
  @override
  FutureOr<List<Reminder>> build(String arg) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reminders_$arg';
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => Reminder.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> _save(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reminders_$arg';
    final jsonString = jsonEncode(reminders.map((e) => e.toJson()).toList());
    await prefs.setString(key, jsonString);
    state = AsyncData(reminders);
  }

  Future<void> addReminder(Reminder reminder) async {
    final current = state.value ?? [];
    await _save([...current, reminder]);
  }

  Future<void> deleteReminder(String id) async {
    final current = state.value ?? [];
    await _save(current.where((r) => r.id != id).toList());
  }

  Future<void> toggleReminder(String id) async {
    final current = state.value ?? [];
    await _save(
      current.map((r) {
        if (r.id == id) {
          return r.copyWith(isEnabled: !r.isEnabled);
        }
        return r;
      }).toList(),
    );
  }
}
