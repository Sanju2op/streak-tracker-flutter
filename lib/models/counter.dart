const kCounterPeriods = {'hours', 'days', 'weeks', 'months', 'years'};

class Counter {
  final String id;
  final String title;
  final String color;
  final int startedAt;
  final String period;
  final int createdAt;
  final int updatedAt;

  const Counter({
    required this.id,
    required this.title,
    required this.color,
    required this.startedAt,
    required this.period,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(
         period == 'hours' ||
             period == 'days' ||
             period == 'weeks' ||
             period == 'months' ||
             period == 'years',
       );

  factory Counter.fromMap(Map<String, dynamic> map) {
    return Counter(
      id: map['id'] as String,
      title: map['title'] as String,
      color: map['color'] as String,
      startedAt: map['started_at'] as int,
      period: map['period'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'started_at': startedAt,
      'period': period,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Counter copyWith({
    String? id,
    String? title,
    String? color,
    int? startedAt,
    String? period,
    int? createdAt,
    int? updatedAt,
  }) {
    return Counter(
      id: id ?? this.id,
      title: title ?? this.title,
      color: color ?? this.color,
      startedAt: startedAt ?? this.startedAt,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
