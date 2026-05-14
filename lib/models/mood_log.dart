class MoodLog {
  final String id;
  final String userId;
  final String semesterId;
  final int moodLevel;
  final int stressLevel;
  final int? energyLevel;
  final String? note;
  final List<String> factors;
  final String source;
  final DateTime createdAt;

  MoodLog({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.moodLevel,
    required this.stressLevel,
    this.energyLevel,
    this.note,
    this.factors = const [],
    this.source = 'manual',
    required this.createdAt,
  });

  factory MoodLog.fromJson(Map<String, dynamic> json) {
    final rawFactors = json['factors'];
    final factors = rawFactors is List
        ? rawFactors.map((item) => item.toString()).toList()
        : <String>[];

    final moodLevel =
        ((json['mood_level'] as num?)?.toInt()) ??
        _legacyMoodToLevel(json['mood']?.toString()) ??
        3;

    final stressLevel = ((json['stress_level'] as num?)?.toInt()) ?? 5;

    final createdAtRaw = json['created_at']?.toString();
    final parsed = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw)
        : null;
    // Treat the stored wall-clock as the user's local time. Construct a naive
    // local DateTime from the raw components so that displays don't shift by
    // the device's UTC offset.
    final createdAt = parsed == null
        ? null
        : DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
          );

    return MoodLog(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      semesterId: json['semester_id']?.toString() ?? '',
      moodLevel: moodLevel,
      stressLevel: stressLevel,
      energyLevel: (json['energy_level'] as num?)?.toInt(),
      note: json['note'] as String?,
      factors: factors,
      source: (json['source'] as String?) ?? 'manual',
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static int? _legacyMoodToLevel(String? mood) {
    if (mood == null) return null;
    switch (mood.toLowerCase()) {
      case 'very_bad':
        return 1;
      case 'bad':
        return 2;
      case 'neutral':
        return 3;
      case 'good':
        return 4;
      case 'very_good':
        return 5;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'semester_id': semesterId,
      'mood_level': moodLevel,
      'stress_level': stressLevel,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (note != null && note!.trim().isNotEmpty) 'note': note,
      'factors': factors,
      'source': source,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
