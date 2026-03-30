class AppUser {
  final String id;
  final String email;
  final String? name;
  final DateTime createdAt;

  final String? avatarUrl;
  final bool academicProfileCompleted;
  final int? weeklyStudyGoal;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
    this.avatarUrl,
    this.academicProfileCompleted = false,
    this.weeklyStudyGoal,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      avatarUrl: json['avatar_url'],
      academicProfileCompleted: json['academic_profile_completed'] ?? false,
      weeklyStudyGoal: json['weekly_study_goal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'avatar_url': avatarUrl,
      'academic_profile_completed': academicProfileCompleted,
      'weekly_study_goal': weeklyStudyGoal,
    };
  }
}
