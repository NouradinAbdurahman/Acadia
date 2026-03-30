class Semester {
  final String id;
  final String userId;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final DateTime createdAt;

  Semester({
    required this.id,
    required this.userId,
    required this.name,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    required this.createdAt,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isCurrent: json['is_current'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'user_id': userId,
      'name': name,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_current': isCurrent,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }

  Semester copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    DateTime? createdAt,
  }) {
    return Semester(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
