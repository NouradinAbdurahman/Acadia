class NotificationModel {
  final String id;
  final String userId;
  final String? referenceId;
  final String title;
  final String message;
  final String type;
  final String? semesterId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.referenceId,
    required this.title,
    required this.message,
    required this.type,
    this.semesterId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      referenceId: json['reference_id'] as String?,
      title: json['title'],
      message: json['message'],
      type: json['type'],
      semesterId: json['semester_id'] as String?,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (referenceId != null) 'reference_id': referenceId,
      'title': title,
      'message': message,
      'type': type,
      if (semesterId != null) 'semester_id': semesterId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? referenceId,
    String? title,
    String? message,
    String? type,
    String? semesterId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      referenceId: referenceId ?? this.referenceId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      semesterId: semesterId ?? this.semesterId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
