class AppUser {
  final String id;
  final String email;
  final String? name;
  final DateTime createdAt;

  final String? avatarUrl;
  final bool academicProfileCompleted;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
    this.avatarUrl,
    this.academicProfileCompleted = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      // public.users.email is nullable in the DB (e.g. rows created before
      // the signup path wrote it); falling back instead of crashing here
      // matters because an uncaught error puts currentAppUserProvider into
      // AsyncError, which the router's redirect logic treats identically to
      // "no profile yet" — permanently trapping the user on academic
      // onboarding regardless of what they submit.
      email: json['email'] as String? ?? '',
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      avatarUrl: json['avatar_url'],
      academicProfileCompleted: json['academic_profile_completed'] ?? false,
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
    };
  }
}
