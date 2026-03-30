// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String helloUser(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get academicOverview => 'Your academic overview';

  @override
  String get academicRisk => 'Academic Risk';

  @override
  String get lowRisk => 'Low Risk';

  @override
  String get score => 'Score';

  @override
  String get tasksToday => 'Tasks Today';

  @override
  String tasksPending(int count) {
    return '$count tasks pending';
  }

  @override
  String get upcomingDeadlines => 'Upcoming Deadlines';

  @override
  String thisWeek(int count) {
    return '$count this week';
  }

  @override
  String get noDeadlinesWeek => 'No deadlines this week';

  @override
  String get studyTimeToday => 'Study Time Today';

  @override
  String get noStudyLogged => 'No study logged today';

  @override
  String get profile => 'Profile';

  @override
  String get account => 'Account';

  @override
  String get preferences => 'Preferences';

  @override
  String get support => 'Support';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Dark Mode';

  @override
  String get aboutApp => 'About App';

  @override
  String get privacy => 'Privacy';

  @override
  String get logout => 'Logout';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get notificationsCaughtUp => 'You\'re all caught up';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get earlier => 'Earlier';

  @override
  String get home => 'Home';

  @override
  String get overview => 'Overview';

  @override
  String get searchHint => 'Search tasks, exams or insights';

  @override
  String get email => 'Email';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get tasks => 'Tasks';

  @override
  String get all => 'All';

  @override
  String get pending => 'Pending';

  @override
  String get deadlines => 'Deadlines';

  @override
  String get completed => 'Completed';

  @override
  String get overdue => 'Overdue';

  @override
  String get createTask => 'Create Task';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get course => 'Course';

  @override
  String get priority => 'Priority';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get estimatedStudyTime => 'Est. Study Time';

  @override
  String get notes => 'Notes';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get study => 'Study';

  @override
  String get startStudySession => 'Study Session';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get stop => 'Stop';

  @override
  String get sessionCompleted => 'Session completed';

  @override
  String get recentStudySessions => 'Recent Study Sessions';

  @override
  String get stayOrganized => 'Stay organized';

  @override
  String get createFirstTask =>
      'Create your first task to start tracking your assignments.';

  @override
  String get couldNotLoadTasks => 'Could not load tasks.';

  @override
  String get couldNotLoadDeadlines => 'Could not load deadlines.';

  @override
  String get delete => 'Delete';

  @override
  String get complete => 'Complete';

  @override
  String due(String date) {
    return 'Due: $date';
  }

  @override
  String estStudy(num time) {
    return 'Est. Study: ${time}h';
  }

  @override
  String get noDeadlinesYet => 'No deadlines yet';

  @override
  String get createFirstDeadline =>
      'Create your first academic deadline to stay ahead.';

  @override
  String get createDeadline => 'Create Deadline';

  @override
  String get dueToday => 'Due today';

  @override
  String daysRemaining(int count) {
    return '$count days left';
  }

  @override
  String get exam => 'Exam';

  @override
  String get quiz => 'Quiz';

  @override
  String get project => 'Project';

  @override
  String get assignment => 'Assignment';

  @override
  String get noDeadline => 'No deadline';

  @override
  String get newAcademicTask => 'New Academic Task';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get optional => 'optional';

  @override
  String get newAcademicDeadline => 'New Academic Deadline';

  @override
  String get pleaseSelectDate => 'Please select a date';

  @override
  String get saving => 'Saving...';

  @override
  String get title => 'Title';

  @override
  String get deadlineDate => 'Deadline Date';

  @override
  String get type => 'Type';

  @override
  String get studySession => 'Study Session';

  @override
  String get saveSession => 'Save Session';

  @override
  String get noStudySessionsYet => 'No study sessions yet.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String minutes(int count) {
    return '$count minutes';
  }

  @override
  String get duration => 'Duration';

  @override
  String get pomodoro => 'Pomodoro';

  @override
  String get review => 'Review';

  @override
  String get deepFocus => 'Deep Focus';

  @override
  String get analytics => 'Analytics';

  @override
  String get studyHours => 'Study hours';

  @override
  String get taskCompletionRate => 'Task completion rate';

  @override
  String get stressTrends => 'Stress trends';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get taskDetail => 'Task Detail';

  @override
  String get deadlineDetail => 'Deadline Detail';

  @override
  String get taskNotFound => 'Task not found.';

  @override
  String get deadlineNotFound => 'Deadline not found.';

  @override
  String get noDeadlineSet => 'No deadline set';

  @override
  String overdueByDays(int count) {
    return 'Overdue by $count days';
  }

  @override
  String dueInDays(int count) {
    return 'Due in $count days';
  }

  @override
  String get editTask => 'Edit Task';

  @override
  String get editDeadline => 'Edit Deadline';

  @override
  String get markAsPending => 'Mark as Pending';

  @override
  String get markAsComplete => 'Mark as Complete';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get deleteDeadline => 'Delete Deadline';

  @override
  String get notSet => 'Not set';

  @override
  String get estimated => 'Estimated';

  @override
  String get updateTask => 'Update Task';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get welcome => 'Welcome back';

  @override
  String get password => 'Password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get login => 'Login';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signup => 'Create Account';

  @override
  String get invalidCredentials => 'Incorrect email or password.';

  @override
  String get tooManyRequests => 'Too many requests. Please try again later.';

  @override
  String get networkError => 'Connection error. Try again.';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get fullName => 'Full Name';

  @override
  String get requiredField => 'This field is required';

  @override
  String get passwordStrong => 'Strong';

  @override
  String get passwordFair => 'Fair';

  @override
  String get passwordWeak => 'Weak';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get emailAlreadyInUse =>
      'This email is already registered. Try logging in instead.';

  @override
  String get otpExpired => 'Code expired. Request a new one.';

  @override
  String get tooManyAttempts => 'Too many attempts. Please try again later.';

  @override
  String get invalidOtp => 'Invalid verification code';

  @override
  String get codeResent => 'Code sent!';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get enterOtp => 'Enter the 6-digit code sent to your email';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordPrompt =>
      'Enter your email address to receive a 6-digit verification code.';

  @override
  String get sendResetLink => 'Send Code';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get passwordSameAsOld =>
      'New password must be different from your current password.';

  @override
  String resendIn(Object count) {
    return 'Resend in $count seconds';
  }

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Turkish';

  @override
  String get continueText => 'Continue';

  @override
  String get onboardingTitle1 => 'Master your academic life';

  @override
  String get onboardingDesc1 =>
      'Track your tasks, exams, and study sessions in one intelligent workspace.';

  @override
  String get onboardingTitle2 => 'Stay on top of your tasks';

  @override
  String get onboardingDesc2 =>
      'Organize assignments and deadlines so nothing slips through the cracks.';

  @override
  String get onboardingTitle3 => 'Understand your progress';

  @override
  String get onboardingDesc3 =>
      'Visual insights show your study patterns, productivity, and academic trends.';

  @override
  String get onboardingTitle4 => 'Balance performance and wellbeing';

  @override
  String get onboardingDesc4 =>
      'Monitor stress levels and build smarter study habits.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get workloadBalanced => 'Workload Balanced';

  @override
  String get student => 'Student';

  @override
  String get hoursAbbreviation => 'h';

  @override
  String get minutesAbbreviation => 'm';

  @override
  String get avatarUpdated => 'Avatar updated successfully';

  @override
  String get avatarUploadFailed => 'Failed to upload avatar';

  @override
  String get mediumRisk => 'Medium Risk';

  @override
  String get highRisk => 'High Risk';

  @override
  String get riskScore => 'Risk Score';

  @override
  String get remaining => 'remaining';

  @override
  String get studyLogged => 'Study logged';

  @override
  String get allTasksCompleted => 'All tasks completed!';

  @override
  String get dontForgetTasks => 'Don\'t forget to finish them';

  @override
  String get academicProfileOnboarding => 'Academic Profile';

  @override
  String get basicIdentity => 'Basic Identity';

  @override
  String get academicProgram => 'Academic Program';

  @override
  String get currentSemesterLoad => 'Current Semester Load';

  @override
  String get learningPatternCalibration => 'Learning Patterns';

  @override
  String get universityName => 'University Name';

  @override
  String get degreeType => 'Degree Type';

  @override
  String get major => 'Major';

  @override
  String get minor => 'Minor';

  @override
  String get academicYear => 'Academic Year';

  @override
  String get expectedGraduationYear => 'Expected Graduation Year';

  @override
  String get currentSemesterNumber => 'Current Semester';

  @override
  String get coursesThisSemester => 'Expected Courses';

  @override
  String get studyHoursPerWeek => 'Weekly Study Goal (Hours)';

  @override
  String get preferredStudyTime => 'Preferred Study Time';

  @override
  String get breakPattern => 'Break Pattern';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get night => 'Night';

  @override
  String get deepWork => 'Deep Work';

  @override
  String get mixed => 'Mixed';

  @override
  String get bachelor => 'Bachelor';

  @override
  String get master => 'Master';

  @override
  String get phd => 'PhD';

  @override
  String get addSemester => 'Add Semester';

  @override
  String get editSemester => 'Edit Semester';

  @override
  String get semesterName => 'Semester Name';

  @override
  String get semesterNameHint => 'e.g. Fall 2024';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get createSemester => 'Create Semester';

  @override
  String get updateSemester => 'Update Semester';

  @override
  String get courseManagement => 'Course Management';

  @override
  String get myCourses => 'My Courses';

  @override
  String get manageSemesters => 'Manage Semesters';

  @override
  String get addCourse => 'Add Course';

  @override
  String get editCourse => 'Edit Course';

  @override
  String get courseCode => 'Course Code';

  @override
  String get courseNameHint => 'e.g. Advanced Mathematics';

  @override
  String get courseCodeHint => 'e.g. CS204';

  @override
  String get details => 'Details';

  @override
  String get courseColor => 'Course Color';

  @override
  String get creditsLabel => 'Credits';

  @override
  String get sortAlphabetical => 'Alphabetical';

  @override
  String get sortStudyTime => 'Study Time';

  @override
  String get semester => 'Semester';

  @override
  String get selectSemester => 'Select Semester';

  @override
  String get setAsActive => 'Set as active semester';

  @override
  String get noCoursesYet => 'No courses added yet';

  @override
  String get addFirstCourse => 'Add your first course to start tracking.';

  @override
  String get addFirstCourseBtn => 'Add My First Course';

  @override
  String get deleteCourse => 'Delete Course?';

  @override
  String get deleteCourseWarning =>
      'This will also disconnect this course from all linked tasks and sessions.';

  @override
  String get addCourseFirst => 'Add a course first';

  @override
  String get selectCourse => 'Select Course';

  @override
  String get pleaseSelectCourse => 'Please select a course';

  @override
  String get errorLoadingCourses => 'Error loading courses';

  @override
  String get academicInformation => 'Academic Information';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get manageCourses => 'Manage Courses';

  @override
  String get manageCoursesSubtitle => 'Add or edit your current courses';

  @override
  String yearCount(int count) {
    return 'Year $count';
  }

  @override
  String get studyGoal => 'Weekly Study Goal';

  @override
  String studyGoalCompleted(String time) {
    return 'Completed: $time';
  }

  @override
  String studyGoalRemaining(String time) {
    return 'Remaining: $time';
  }

  @override
  String get sessionReflectionTitle => 'How was this session?';

  @override
  String get focused => 'Focused';

  @override
  String get distracted => 'Distracted';

  @override
  String get veryProductive => 'Very Productive';

  @override
  String get sessionNotes => 'Session Notes';

  @override
  String get identityDesc =>
      'Let\'s start with who you are and where you study.';

  @override
  String get programDesc => 'Tell us about your field of study.';

  @override
  String get loadDesc => 'Help us calibrate your expected workload.';

  @override
  String get learningPatternDesc => 'When and how do you learn best?';

  @override
  String hoursCount(int count) {
    return '$count Hours';
  }

  @override
  String get recommendedFocus => 'Recommended Focus';

  @override
  String get practice => 'Practice';

  @override
  String get studyPreferences => 'Study Preferences';

  @override
  String get appSettings => 'App Settings';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get dataExport => 'Data Export';

  @override
  String get reminderSettings => 'Reminder Settings';

  @override
  String get notificationsEnabled => 'Notifications Enabled';

  @override
  String get notificationsDisabled => 'Notifications Disabled';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get passwordUpdatedSuccess => 'Password updated successfully';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get studyTimerDefaults => 'Study Timer Defaults';

  @override
  String focusOnTitle(String title) {
    return 'Focus on $title - due soon!';
  }

  @override
  String get allCaughtUp =>
      'You\'re all caught up! Maybe start a deep work session?';

  @override
  String bestStudyTime(String time) {
    return 'You study best in the $time. Keep your first session then!';
  }

  @override
  String get discoverPattern =>
      'Start a session to discover your productivity pattern.';

  @override
  String get startNewSession => 'Start New Session';

  @override
  String get sessionType => 'Session Type';

  @override
  String get galleryPermissionRequired => 'Gallery Permission Required';

  @override
  String get galleryPermissionMessage =>
      'Please allow gallery access in settings to change your profile picture.';

  @override
  String get chooseACourse => 'Choose a course';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get notEnoughData => 'Not enough data yet';

  @override
  String get addCoursesPrompt => 'Add your courses to start tracking progress.';

  @override
  String get noUpcomingDeadlines => 'No upcoming deadlines';

  @override
  String get caughtUp => 'You are all caught up!';

  @override
  String youStudiedFor(String time) {
    return 'You studied for $time.';
  }

  @override
  String get efficiencyTip => 'Efficiency Tip';

  @override
  String get discoveryStudyPatterns =>
      'Discover your best study patterns by logging more sessions.';

  @override
  String goalCompletionLabel(int percentage) {
    return 'Goal Completion: $percentage%';
  }

  @override
  String keepGoingLeft(String time) {
    return 'Keep going! You have $time left.';
  }

  @override
  String get greatFocusSession => 'Great focus session!';

  @override
  String get focusLevel => 'Focus Level';

  @override
  String get deepFlow => 'Deep Flow';

  @override
  String get building => 'Building';

  @override
  String get studyHoursByCourse => 'Study Hours by Course';

  @override
  String get weeklyTaskCompletion => 'Weekly Task Completion';

  @override
  String get dailyInsight => 'Daily Insight';

  @override
  String get focusOnStudies => 'Focus on your studies today.';

  @override
  String get thisWeekLabel => 'This Week';

  @override
  String get noCourseSelected => 'No Course Selected';

  @override
  String lastUpdatedAt(String time) {
    return 'Last updated: $time';
  }

  @override
  String get noPendingAlerts => 'No pending alerts.';

  @override
  String overdueTasksSummary(int count) {
    return 'There are $count overdue tasks.';
  }

  @override
  String deadlinesSoonSummary(int count) {
    return 'There are $count deadlines within the next 3 days.';
  }

  @override
  String get allTasksUpToDate => 'All current tasks are up-to-date.';

  @override
  String get ectsLabel => 'ECTS';

  @override
  String get sessionFocus => 'Session Focus';

  @override
  String get academicLoad => 'Academic Load';

  @override
  String get studyDemand => 'Study Demand';

  @override
  String get workloadIntensity => 'Workload Intensity';

  @override
  String get totalEctsLabel => 'Total ECTS';

  @override
  String get overloaded => 'Overloaded';

  @override
  String get highLoad => 'High Load';

  @override
  String get balanced => 'Balanced';

  @override
  String get lowLoad => 'Low Load';

  @override
  String get riskLow => 'Low Risk';

  @override
  String get riskMedium => 'Medium Risk';

  @override
  String get riskHigh => 'High Risk';

  @override
  String get riskBreakdownTitle => 'Risk Breakdown';

  @override
  String get riskOverdueTasks => 'Overdue tasks';

  @override
  String get riskUpcomingTasks => 'Tasks due soon';

  @override
  String get riskStudyDeficit => 'Study deficit';

  @override
  String riskStatusMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tasks',
      one: 'task',
    );
    return '$count overdue $_temp0';
  }

  @override
  String get riskInterpretationOnTrack =>
      'You are on track. Keep your current study pace.';

  @override
  String get riskInterpretationHigh =>
      'You are at high risk due to missed deadlines and insufficient study hours.';

  @override
  String get riskInterpretationMedium =>
      'Your risk is moderate; keep an eye on upcoming tasks and study goals.';

  @override
  String get riskInterpretationLow =>
      'You are in a safe range. Maintain your current progress.';

  @override
  String riskHoursRemaining(Object hours) {
    return '${hours}h remaining';
  }

  @override
  String get riskGoalReached => 'Goal reached!';

  @override
  String riskReasonOverdue(int count) {
    return 'You have $count overdue tasks';
  }

  @override
  String get riskReasonStudyLow => 'You studied less than your weekly goal';

  @override
  String riskReasonUpcoming(int count) {
    return '$count tasks due soon';
  }

  @override
  String riskTrendUp(int delta) {
    return '+$delta risk increase';
  }

  @override
  String riskTrendDown(int delta) {
    return '-$delta (improved)';
  }

  @override
  String get riskTrendStable => '+0 (no change)';

  @override
  String get riskNoData => 'No active risk factors';

  @override
  String get overviewTitle => 'Overview';

  @override
  String lastUpdated(String time) {
    return 'Last updated: $time';
  }

  @override
  String overviewOverdueTasksAction(int count) {
    return '$count tasks need attention';
  }

  @override
  String overviewUpcomingTasks(int count) {
    return '$count upcoming deadlines';
  }

  @override
  String get overviewNoUpcomingTasks => 'No upcoming deadlines';

  @override
  String overviewCompletedToday(int count) {
    return '$count tasks completed today';
  }

  @override
  String get overviewNoCompletedToday => 'No tasks completed today';

  @override
  String get taskCompletion => 'Task Completion';

  @override
  String tasksCompleted(int completed, int total) {
    return '$completed of $total tasks completed';
  }

  @override
  String tasksCompletedThisWeek(int completed, int total) {
    return 'Tasks due this week: $completed of $total completed';
  }

  @override
  String get noStudyDataThisWeek => 'No study sessions this week';

  @override
  String get noTasksThisWeek => 'No tasks scheduled this week';
}
