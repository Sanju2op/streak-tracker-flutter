const kGoalTargetUnits = {'days', 'weeks', 'months', 'years'};

class Goal {
  final String id;
  final String counterId;
  final int targetValue;
  final String targetUnit;
  final String? note;
  final bool isCompleted;
  final int createdAt;

  const Goal({
    required this.id,
    required this.counterId,
    required this.targetValue,
    required this.targetUnit,
    required this.note,
    required this.isCompleted,
    required this.createdAt,
  }) : assert(
         targetUnit == 'days' ||
             targetUnit == 'weeks' ||
             targetUnit == 'months' ||
             targetUnit == 'years',
       );

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      counterId: map['counter_id'] as String,
      targetValue: map['target_value'] as int,
      targetUnit: map['target_unit'] as String,
      note: map['note'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'counter_id': counterId,
      'target_value': targetValue,
      'target_unit': targetUnit,
      'note': note,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
    };
  }

  Goal copyWith({
    String? id,
    String? counterId,
    int? targetValue,
    String? targetUnit,
    String? note,
    bool? isCompleted,
    int? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      counterId: counterId ?? this.counterId,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
