class StudentProfile {
  final String id;
  final String userId;
  final String? fullName;
  final String? universityName;
  final String? degreeType;
  final String? major;
  final int? academicYear;
  final int? currentSemester;
  final int? expectedGraduationYear;
  final String? preferredStudyTime;
  final String? breakPattern;
  final String? timezone;
  final String? country;
  final bool onboardingComplete;
  final DateTime createdAt;
  final DateTime updatedAt;


  StudentProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.universityName,
    this.degreeType,
    this.major,
    this.academicYear,
    this.currentSemester,
    this.expectedGraduationYear,
    this.preferredStudyTime,
    this.breakPattern,
    this.timezone,
    this.country,
    this.onboardingComplete = false,
    required this.createdAt,
    required this.updatedAt,
  });


  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      universityName: json['university_name'],
      degreeType: json['degree_type'],
      major: json['major'],
      academicYear: json['academic_year'],
      currentSemester: json['current_semester'],
      expectedGraduationYear: json['expected_graduation_year'],
      preferredStudyTime: json['preferred_study_time'],
      breakPattern: json['break_pattern'],
      timezone: json['timezone'],
      country: json['country'],
      onboardingComplete: json['onboarding_complete'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );

  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'university_name': universityName,
      'degree_type': degreeType,
      'major': major,
      'academic_year': academicYear,
      'current_semester': currentSemester,
      'expected_graduation_year': expectedGraduationYear,
      'preferred_study_time': preferredStudyTime,
      'break_pattern': breakPattern,
      'timezone': timezone,
      'country': country,
      'onboarding_complete': onboardingComplete,
    };

  }

  StudentProfile copyWith({
    String? fullName,
    String? universityName,
    String? degreeType,
    String? major,
    int? academicYear,
    int? currentSemester,
    int? expectedGraduationYear,
    String? preferredStudyTime,
    String? breakPattern,
    String? timezone,
    String? country,
    bool? onboardingComplete,
  }) {

    return StudentProfile(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      universityName: universityName ?? this.universityName,
      degreeType: degreeType ?? this.degreeType,
      major: major ?? this.major,
      academicYear: academicYear ?? this.academicYear,
      currentSemester: currentSemester ?? this.currentSemester,
      expectedGraduationYear: expectedGraduationYear ?? this.expectedGraduationYear,
      preferredStudyTime: preferredStudyTime ?? this.preferredStudyTime,
      breakPattern: breakPattern ?? this.breakPattern,
      timezone: timezone ?? this.timezone,
      country: country ?? this.country,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );

  }
}
