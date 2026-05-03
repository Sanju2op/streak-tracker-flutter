import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String counterId;
  final TimeOfDay time;
  final String repeatMode; // 'none', 'daily', 'weekly'
  final bool isEnabled;

  const Reminder({
    required this.id,
    required this.counterId,
    required this.time,
    required this.repeatMode,
    required this.isEnabled,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'counterId': counterId,
    'time_hour': time.hour,
    'time_minute': time.minute,
    'repeatMode': repeatMode,
    'isEnabled': isEnabled,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    counterId: json['counterId'],
    time: TimeOfDay(hour: json['time_hour'], minute: json['time_minute']),
    repeatMode: json['repeatMode'],
    isEnabled: json['isEnabled'],
  );

  Reminder copyWith({
    String? id,
    String? counterId,
    TimeOfDay? time,
    String? repeatMode,
    bool? isEnabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      counterId: counterId ?? this.counterId,
      time: time ?? this.time,
      repeatMode: repeatMode ?? this.repeatMode,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
