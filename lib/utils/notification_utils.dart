import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  if (kIsWeb) return;

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await _plugin.initialize(initSettings);
}

Future<void> requestPermission() async {
  if (kIsWeb) return;
  await Permission.notification.request();
}

Future<void> scheduleReminder({
  required String id,
  required String counterTitle,
  required RepeatInterval repeat,
}) async {
  if (kIsWeb) return;

  const androidDetails = AndroidNotificationDetails(
    'streak_reminders',
    'Streak Reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  await _plugin.periodicallyShow(
    id.hashCode,
    'Streak Reminder',
    counterTitle,
    repeat,
    const NotificationDetails(android: androidDetails),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

Future<void> cancelReminder(String id) async {
  if (kIsWeb) return;
  await _plugin.cancel(id.hashCode);
}

Future<void> showGoalAchievedNotification({
  required String goalId,
  required String counterTitle,
  required String goalText,
}) async {
  if (kIsWeb) return;

  const androidDetails = AndroidNotificationDetails(
    'goal_achievements',
    'Goal Achievements',
    importance: Importance.high,
    priority: Priority.high,
  );

  await _plugin.show(
    goalId.hashCode,
    'Goal Achieved! 🎉',
    '$counterTitle: $goalText',
    const NotificationDetails(android: androidDetails),
  );
}
