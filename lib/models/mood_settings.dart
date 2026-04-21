class MoodSettings {
  final String userId;
  final bool trackingEnabled;
  final bool reminderEnabled;
  final String? reminderTime;
  final String reminderType;

  const MoodSettings({
    required this.userId,
    this.trackingEnabled = true,
    this.reminderEnabled = true,
    this.reminderTime,
    this.reminderType = 'both',
  });

  factory MoodSettings.fromJson(Map<String, dynamic> json) {
    return MoodSettings(
      userId: json['user_id'] as String,
      trackingEnabled: json['tracking_enabled'] as bool? ?? true,
      reminderEnabled: json['reminder_enabled'] as bool? ?? true,
      reminderTime: json['reminder_time'] as String?,
      reminderType: (json['reminder_type'] as String?) ?? 'both',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tracking_enabled': trackingEnabled,
      'reminder_enabled': reminderEnabled,
      'reminder_time': reminderTime,
      'reminder_type': reminderType,
    };
  }
}
