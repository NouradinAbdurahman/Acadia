class MoodModel {
  final String id;
  final String userId;
  final String? mood;
  final int? stressLevel;
  final String? note;
  final DateTime date;

  MoodModel({
    required this.id,
    required this.userId,
    this.mood,
    this.stressLevel,
    this.note,
    required this.date,
  });

  factory MoodModel.fromJson(Map<String, dynamic> json) {
    return MoodModel(
      id: json['id'],
      userId: json['user_id'],
      mood: json['mood'],
      stressLevel: json['stress_level'],
      note: json['note'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (mood != null) 'mood': mood,
      if (stressLevel != null) 'stress_level': stressLevel,
      if (note != null) 'note': note,
      'date': date.toIso8601String(),
    };
  }
}
