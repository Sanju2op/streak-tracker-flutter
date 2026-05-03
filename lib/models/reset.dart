class Reset {
  final String id;
  final String counterId;
  final int resetAt;
  final String? note;
  final int previousStartedAt;
  final int createdAt;

  const Reset({
    required this.id,
    required this.counterId,
    required this.resetAt,
    required this.note,
    required this.previousStartedAt,
    required this.createdAt,
  });

  factory Reset.fromMap(Map<String, dynamic> map) {
    return Reset(
      id: map['id'] as String,
      counterId: map['counter_id'] as String,
      resetAt: map['reset_at'] as int,
      note: map['note'] as String?,
      previousStartedAt: map['previous_started_at'] as int,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'counter_id': counterId,
      'reset_at': resetAt,
      'note': note,
      'previous_started_at': previousStartedAt,
      'created_at': createdAt,
    };
  }
}
