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
  String get aiInsightTitle => 'Insight';

  @override
  String get aiInsightSectionTitle => 'AI Insight';

  @override
  String get aiInsightPrimaryReasonLabel => 'Why';

  @override
  String get aiInsightWhatToDoLabel => 'Action';

  @override
  String get aiInsightConfidenceHeading => 'Confidence';

  @override
  String get confidenceWordHigh => 'High';

  @override
  String get confidenceWordMedium => 'Medium';

  @override
  String get confidenceWordLow => 'Low';

  @override
  String aiInsightConfidenceLine(String level) {
    return 'Confidence: $level';
  }

  @override
  String get aiRecommendationTitle => 'Recommendation';

  @override
  String get aiActionStartStudy => 'Start study session';

  @override
  String get aiActionAddTask => 'Add task';

  @override
  String get aiActionViewTasks => 'View tasks';

  @override
  String get aiActionOpenAnalytics => 'Open analytics';

  @override
  String get aiPassiveRiskSpike =>
      'Academic risk changed noticeably. Consider a quick check-in.';

  @override
  String get aiPassiveOpenAssistant => 'Open assistant';

  @override
  String get aiPassiveReviewTasksNow => 'Review tasks now';

  @override
  String get aiPassiveViewAnalytics => 'View analytics';

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
  String get noTasksForThisCourse => 'No tasks for this course';

  @override
  String get noDeadlinesForThisCourse => 'No deadlines for this course';

  @override
  String get noSessionsForThisCourse => 'No sessions for this course';

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
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountWarning =>
      'This action is permanent and cannot be undone. Your account data, semester history, tasks, and analytics will be removed and you will lose access immediately. Are you sure you want to continue?';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get notificationsCaughtUp => 'You\'re all caught up';

  @override
  String get noMoodNotificationsYet => 'No mood notifications yet';

  @override
  String get noAcademicNotificationsYet => 'No academic notifications yet';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get earlier => 'Earlier';

  @override
  String get thisMonthLabel => 'This Month';

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
  String get quickMenu => 'Quick Menu';

  @override
  String get deadlineKindBadge => 'Deadline';

  @override
  String get linkToAcademicDeadline => 'Link to deadline (optional)';

  @override
  String get noneLinkedDeadline => 'None';

  @override
  String get relatedTasksSection => 'Related tasks';

  @override
  String get addTaskToThisDeadline => 'Add task to this deadline';

  @override
  String deadlineLinkedTasksProgress(int completed, int total) {
    return '$completed / $total tasks completed';
  }

  @override
  String get deadlineNoLinkedTasks => 'No tasks linked to this deadline yet.';

  @override
  String get taskLinkedToDeadline => 'Linked to a deadline';

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
  String get liveStudySessions => 'Live Study Sessions';

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
  String get focusLabel => 'Focus';

  @override
  String get breakLabel => 'Break';

  @override
  String get reviewLabel => 'Review';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String get stopSessionTitle => 'Stop Session';

  @override
  String get stopSessionConfirm =>
      'Are you sure you want to end this study session?';

  @override
  String get sessionPaused => 'Session paused. Take a breath.';

  @override
  String get refreshYourself => 'Refresh yourself. You\'re doing great.';

  @override
  String get stayFocused => 'Stay focused. You\'re doing well.';

  @override
  String get deepWorkInProgress => 'Deep work in progress...';

  @override
  String get dontStopNow => 'Don\'t stop now, you\'re on a roll!';

  @override
  String get focusOnProcess => 'Focus on the process, not the results.';

  @override
  String get almostThere => 'Almost there! Keep pushing.';

  @override
  String get futureSelf => 'Your future self will thank you.';

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
  String get deepFocus => 'Deep focus';

  @override
  String get analytics => 'Analytics';

  @override
  String get studyHours => 'Study hours';

  @override
  String get taskCompletionRate => 'Task completion rate';

  @override
  String get taskStatThisWeekByDeadline => 'This week (by deadline)';

  @override
  String get taskStatThisSemester => 'This semester';

  @override
  String get taskStatTrendChartPeriod => 'Tasks (chart period)';

  @override
  String get stressTrends => 'Stress trends';

  @override
  String get academicReport => 'Academic Report';

  @override
  String get academicHistory => 'Academic History';

  @override
  String get requiresFocus => 'Requires focus';

  @override
  String get gradeAverage => 'Grade average';

  @override
  String get semesterTrend => 'Semester Trend';

  @override
  String get noAcademicHistory => 'No academic history yet';

  @override
  String get startLoggingContext =>
      'Log study sessions and complete tasks to build your historical profile.';

  @override
  String get activeLabel => 'Active';

  @override
  String get switchToSemester => 'Switch to this Semester';

  @override
  String get setUpSemester => 'Set up Semester';

  @override
  String get startAcademicTracking => 'Start academic tracking';

  @override
  String get gpaPoints => 'GPA Points';

  @override
  String get cgpaLabel => 'CGPA';

  @override
  String gpaValueLabel(String value) {
    return 'GPA: $value';
  }

  @override
  String studyTimeDeltaMsg(String action, int percent) {
    return 'Your weekly study time has $action by $percent%';
  }

  @override
  String riskIncreased(int value) {
    return 'Risk increased by $value%';
  }

  @override
  String riskDecreased(int value) {
    return 'Risk decreased by $value%';
  }

  @override
  String get increased => 'increased';

  @override
  String get decreased => 'decreased';

  @override
  String get taskCompletionImproved =>
      'You are completing more tasks than last semester';

  @override
  String get taskCompletionDecreased => 'Your task completion rate has dropped';

  @override
  String get academicRiskIncreased => 'Your academic risk has increased';

  @override
  String get academicPerformanceSummary => 'Performance Summary';

  @override
  String get performanceSummarySubtitle =>
      'Long-term academic trends across all semesters';

  @override
  String get bestSemester => 'Best Semester';

  @override
  String get worstSemester => 'Worst Semester';

  @override
  String get mostImproved => 'Most Improved';

  @override
  String get highestGPA => 'Highest GPA';

  @override
  String get startStudySessionCTA => 'Start a study session';

  @override
  String get addFirstTaskCTA => 'Add your first task';

  @override
  String get startStudyingHint => 'Start studying to see activity here';

  @override
  String get viewHistoryMode => 'Viewing History';

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
  String get appName => 'Acadia';

  @override
  String get welcomeSubtitle => 'Welcome back to your studies';

  @override
  String get signupSubtitle =>
      'Create your account to start managing your studies';

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
  String get orContinueWith => 'Or continue with';

  @override
  String get googleLabel => 'Google';

  @override
  String get appleLabel => 'Apple';

  @override
  String get signup => 'Create Account';

  @override
  String get invalidCredentials => 'Incorrect email or password.';

  @override
  String get tooManyRequests =>
      'Too many attempts. Email service is temporarily limited. Please wait a few minutes before trying again.';

  @override
  String get emailRateLimit =>
      'Too many attempts. Email service is temporarily limited. Please wait a few minutes.';

  @override
  String emailRateLimitWithTimer(String time) {
    return 'Too many attempts. Email service is temporarily limited. Try again in $time.';
  }

  @override
  String get pleaseWait => 'Please wait a moment before trying again.';

  @override
  String get networkError => 'Connection error. Try again.';

  @override
  String get checkInternetConnection => 'Check your internet connection.';

  @override
  String get requestTimedOut => 'Request timed out. Try again.';

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
  String get tooManyAttempts => 'Please wait a moment before trying again.';

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
  String tryAgainIn(Object count) {
    return 'Try again in ${count}s';
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
  String get riskLevelCritical => 'Critical';

  @override
  String get riskLevelWarning => 'Warning';

  @override
  String get riskLevelSafe => 'Safe';

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
  String get academicAnalyticsContext =>
      'This information helps personalize your academic analytics and recommendations.';

  @override
  String get basicIdentity => 'Basic Identity';

  @override
  String get universitySetup => 'University';

  @override
  String get universitySetupDesc => 'Tell us where you study.';

  @override
  String get academicProgram => 'Academic Program';

  @override
  String get currentSemesterLoad => 'Current Semester';

  @override
  String get learningPatternCalibration => 'Learning Patterns';

  @override
  String get universityName => 'University Name';

  @override
  String get degreeType => 'Degree Type';

  @override
  String get major => 'Major';

  @override
  String get majorPlaceholder => 'e.g. Computer Science';

  @override
  String get minor => 'Minor';

  @override
  String get academicYear => 'Academic Year';

  @override
  String get expectedGraduationYear => 'Expected Graduation Year';

  @override
  String get currentSemesterNumber => 'Current Semester';

  @override
  String get currentSemesterHint => 'Enter your current semester number.';

  @override
  String get semesterTrackingSetup => 'Semester Tracking Setup';

  @override
  String get optionalPreferencesTitle => 'Optional Preferences';

  @override
  String get optionalPreferencesDesc =>
      'You can adjust these anytime in Study Preferences.';

  @override
  String get graduationYearHint =>
      'Choose your expected graduation year (this year or later).';

  @override
  String get graduationYearInvalid =>
      'Graduation year must be this year or later.';

  @override
  String get graduationYearSemesterMismatch => '';

  @override
  String get semesterNumberInvalid => 'Semester number must be at least 1.';

  @override
  String get weeklyStudyGoalInvalid =>
      'Weekly study goal must be between 5 and 40 hours.';

  @override
  String get onboardingRiskImpactHint =>
      'Your semester and study goal are used to calculate academic risk and progress insights.';

  @override
  String get studyGoalRecommendation => 'Recommended: 10-25 hours per week';

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
  String get allSemesters => 'All Semesters';

  @override
  String get addCourse => 'Add Course';

  @override
  String get editCourse => 'Edit Course';

  @override
  String get courseTitle => 'Course Title';

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
  String get academicSemester => 'Academic Semester';

  @override
  String get creditsLabel => 'Credits';

  @override
  String get sortAlphabetical => 'Alphabetical';

  @override
  String get sortStudyTime => 'Study Time';

  @override
  String get semester => 'Semester';

  @override
  String get semesterSeason => 'Season';

  @override
  String get fallSemester => 'Fall';

  @override
  String get springSemester => 'Spring';

  @override
  String get academicYearLabel => 'Academic Year';

  @override
  String get selectSemester => 'Select Semester';

  @override
  String get setAsActive => 'Set as active semester';

  @override
  String get currentSemesterLabel => 'Current';

  @override
  String get selectDate => 'Select Date';

  @override
  String get noSemestersYet => 'No semesters created yet';

  @override
  String get createFirstSemester =>
      'Create your first semester to organize your courses.';

  @override
  String get deleteSemesterWarning =>
      'This semester will be removed from your semester list.';

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
  String get ectsRequired => 'ECTS is required';

  @override
  String get errorLoadingCourses => 'Error loading courses';

  @override
  String get academicInformation => 'Academic Information';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get manageExams => 'Manage Exams';

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
  String get notEnoughData => 'Start tracking to see trends';

  @override
  String get addCoursesPrompt => 'Add your courses to start tracking progress.';

  @override
  String get noUpcomingDeadlines => 'No deadlines due soon';

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
  String get weeklyTaskCompletion => 'This week (by deadline)';

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
  String get riskSessionStress => 'Session stress';

  @override
  String get riskConsistencyImpact => 'Consistency impact';

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
      'Your risk is moderate. Focus on completing tasks and increasing study time.';

  @override
  String get riskInterpretationLow =>
      'You are in a safe range. Keep your current progress.';

  @override
  String get riskInterpretationStudyDeficit =>
      'Increase study time immediately';

  @override
  String get studyDeficitTitle => 'High Study Deficit';

  @override
  String get studyDeficitBody =>
      'Increase study time immediately to stay on track.';

  @override
  String get decisionHighSessionStressTitle => 'High Study Stress';

  @override
  String get decisionHighSessionStressBody =>
      'Reduce session length to 30-40 min to prevent burnout.';

  @override
  String get decisionLowConsistencyTitle => 'Build Study Consistency';

  @override
  String get decisionLowConsistencyBody =>
      'Fix your schedule before increasing workload.';

  @override
  String get burnoutExplanationNew =>
      'Burnout risk is driven by sustained high stress and severe study deficit.';

  @override
  String get startTrackingToSeeTrends => 'Start tracking to see trends';

  @override
  String get noGpaDataAvailable => 'No GPA data available';

  @override
  String get riskInterpretationFocusTasks => 'Focus on completing tasks';

  @override
  String riskHoursRemaining(Object hours) {
    return '${hours}h remaining';
  }

  @override
  String get riskGoalReached => 'Goal reached!';

  @override
  String get historicalConsistency => 'Historical consistency';

  @override
  String historicalConsistencyScoreLine(Object score, Object trend) {
    return 'Historical consistency: $score% ($trend)';
  }

  @override
  String get weeklyConsistency => 'This week consistency';

  @override
  String get decisionHighStressOverrideTitle => 'Reduce workload';

  @override
  String get decisionHighStressOverrideBody =>
      'Focus on shorter sessions to prevent burnout.';

  @override
  String get riskExplanationLowStudyHighStress =>
      'High Risk due to low study activity and high stress';

  @override
  String get riskExplanationDeficitOnly =>
      'High Risk due to severe study deficit';

  @override
  String get riskExplanationStressOnly =>
      'High Risk due to critical stress levels';

  @override
  String get riskExplanationGeneric =>
      'High Risk due to combined academic signals';

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
    return 'Increased by $delta points from last week';
  }

  @override
  String riskTrendDown(int delta) {
    return 'Improved by $delta points from last week';
  }

  @override
  String get riskTrendStable => 'Stable';

  @override
  String riskTrendWorseningDelta(int delta) {
    return 'Worsening · +$delta';
  }

  @override
  String riskTrendImprovingDelta(int delta) {
    return 'Improving · −$delta';
  }

  @override
  String get riskTrendNew => 'New';

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
  String get overviewNoUpcomingTasks => 'No deadlines due soon';

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
    return 'This week (by deadline): $completed of $total completed';
  }

  @override
  String get noStudyDataThisWeek => 'No study sessions this week';

  @override
  String get noTasksThisWeek => 'No tasks scheduled this week';

  @override
  String get examResults => 'Course Results';

  @override
  String get addResult => 'Add Result';

  @override
  String get editResult => 'Edit Result';

  @override
  String get noResultsYet => 'No results added yet';

  @override
  String get addFirstResultPrompt =>
      'Add your first course result for this semester.';

  @override
  String get gradingComponents => 'Grading Components';

  @override
  String get addComponent => '+ Add Component';

  @override
  String get finalSection => 'Final';

  @override
  String get finalAverage => 'Final Average';

  @override
  String get letterGrade => 'Letter Grade';

  @override
  String get resultStatus => 'Course Status';

  @override
  String get resultSuccessful => 'Successful';

  @override
  String get resultFailed => 'Failed';

  @override
  String get component => 'Component';

  @override
  String get componentTitle => 'Title';

  @override
  String get componentTitleHint => 'e.g. Midterm, Project, Final, Quiz';

  @override
  String get scoreHint => 'e.g. 85';

  @override
  String get percentage => 'Percentage';

  @override
  String get percentageHint => 'e.g. 40';

  @override
  String get finalAverageHint => 'e.g. 78.5';

  @override
  String get numberRequired => 'Enter a valid number';

  @override
  String get completeComponentsError => 'Complete all components before saving';

  @override
  String get percentageNot100Warning => 'Warning: total percentage is not 100';

  @override
  String get gradeDistribution => 'Grade Distribution';

  @override
  String get noGradeDistributionYet => 'No grade distribution data yet';

  @override
  String get pleaseSelectLetterGrade => 'Please select a letter grade';

  @override
  String get noCoursesForSemester => 'No courses found for this semester';

  @override
  String get semesterAlreadyExists => 'This semester already exists';

  @override
  String get semesterStartBeforeEndError =>
      'Start date must be before end date';

  @override
  String get gradeRangeError => 'Value must be between 0 and 100';

  @override
  String get trendAnalysis => 'Trend Analysis';

  @override
  String get studyTrend => 'Study Trend';

  @override
  String get taskCompletionTrend => 'Task Completion Trend';

  @override
  String get workloadTrend => 'Workload Trend';

  @override
  String get performanceTrend => 'Performance Trend';

  @override
  String daysFilter(int count) {
    return '$count days';
  }

  @override
  String trendTodayDuration(String duration) {
    return '$duration today';
  }

  @override
  String trendCompletedToday(int count) {
    return '$count completed today';
  }

  @override
  String trendNewToday(int count) {
    return '$count new today';
  }

  @override
  String get trendStudySubtitle =>
      'Hours studied per day over the selected period';

  @override
  String get trendTaskSubtitle =>
      'Completed tasks per day over the selected period';

  @override
  String get trendWorkloadSubtitle => 'Tasks and deadlines added per day';

  @override
  String get trendPerformanceSubtitle => 'GPA change based on course results';

  @override
  String get trendTasksOneDayHint => 'Most tasks were completed on one day.';

  @override
  String get trendWorkloadEmptyMessage =>
      'No data yet.\nAdd tasks or deadlines to see workload trends.';

  @override
  String get trendStudyEmptyMessage =>
      'No data yet.\nStart logging study sessions to see trends.';

  @override
  String get trendTaskEmptyMessage =>
      'No completed tasks in this period.\nComplete tasks to track progress.';

  @override
  String get trendPerformanceEmptyMessage =>
      'Add course results to track performance.';

  @override
  String get trendPerformanceNeedThreeResults =>
      'Add at least 3 course results to see performance trends.';

  @override
  String get trendSummaryTitle => 'Trend Summary';

  @override
  String get trendOverallStatusTitle => 'Overall Status';

  @override
  String get trendNotEnoughData => 'Insufficient data';

  @override
  String get trendStable => 'Stable';

  @override
  String get trendImproving => 'Improving';

  @override
  String get trendDeclining => 'Declining';

  @override
  String get trendLessThan30Minutes => 'Less than 30 minutes in this period';

  @override
  String trendHoursInPeriod(String hours) {
    return '${hours}h in this period';
  }

  @override
  String trendTasksCompletedFraction(int completed, int total) {
    return '$completed / $total completed';
  }

  @override
  String trendTasksDeadlinesAdded(int count) {
    return '$count tasks/deadlines added';
  }

  @override
  String get trendVeryLowActivity => 'Very low activity';

  @override
  String get trendLowActivity => 'Low activity';

  @override
  String get trendNoTasks => 'No tasks';

  @override
  String get trendNoTasksCompletedPeriod => 'No tasks completed in this period';

  @override
  String get trendZeroCompleted => '0% completed';

  @override
  String trendPercentCompleted(int percent) {
    return '$percent% completed';
  }

  @override
  String get trendNoWorkload => 'No workload';

  @override
  String get trendIncreased => 'Increased';

  @override
  String get trendReducedComparedLastPeriod =>
      'Reduced compared to last period';

  @override
  String get trendStatusOnTrack => 'On track';

  @override
  String get trendStatusLowAndBehind => 'Low activity and falling behind';

  @override
  String get trendStatusStudyNeedsImprovement =>
      'Study consistency needs improvement';

  @override
  String get trendStatusTaskIncomplete => 'Task progress is incomplete';

  @override
  String get trendStatusStableProgress => 'Stable progress';

  @override
  String get trendStatusOnTrackDetail =>
      'Your recent activity looks balanced. Keep this pace.';

  @override
  String get trendStatusNeedsFocusDetail =>
      'Your activity is low and task progress is incomplete. Focus on completing tasks and increasing study time.';

  @override
  String get trendStatusLowActivityHighCompletion =>
      'Your activity is low, but task completion is strong.';

  @override
  String get trendStatusNeedsAttention => 'Needs attention';

  @override
  String get trendStatusNeedsImprovement => 'Needs improvement';

  @override
  String get trendStatusCriticalRiskDetail =>
      'Risk factors identified. Review your study habits.';

  @override
  String get trendInsightBuildConsistencyTitle => 'Build study consistency';

  @override
  String get trendInsightStudyIncreasedSignificantlyTitle =>
      'Study increased significantly';

  @override
  String get trendInsightStudyImprovedTitle => 'Study improved';

  @override
  String get trendInsightStudyDeclinedTitle => 'Study declined';

  @override
  String get trendInsightNoTasksTitle => 'No tasks in this period';

  @override
  String get trendInsightTaskLowTitle => 'Task completion is low';

  @override
  String get trendInsightNoWorkloadTitle => 'No new workload';

  @override
  String get trendInsightWorkloadSharpTitle => 'Workload increased sharply';

  @override
  String get trendInsightWorkloadRisingTitle => 'Workload is rising';

  @override
  String get trendInsightPerformanceDecliningTitle => 'Performance declining';

  @override
  String get trendInsightPerformanceImprovingTitle => 'Performance improving';

  @override
  String get trendInsightPerformanceStableTitle => 'Performance stable';

  @override
  String get trendInsightStableTitle => 'Stable trends';

  @override
  String get trendInsightBuildConsistencyMessage =>
      'Start building a daily study habit.';

  @override
  String trendInsightStudyIncreasedMessage(int percent) {
    return 'Study increased by $percent%. Keep this pace to stay ahead.';
  }

  @override
  String trendInsightStudyDroppedMessage(int percent) {
    return 'Study dropped by $percent%. Consider scheduling extra sessions.';
  }

  @override
  String get trendInsightNoTasksMessage => 'No tasks were due in this period.';

  @override
  String get trendInsightNoTasksCompletedMessage =>
      'No tasks completed yet. Start completing tasks to track performance.';

  @override
  String trendInsightTaskCompletedFractionMessage(int completed, int total) {
    return 'You completed $completed of $total tasks. Try to complete more next period.';
  }

  @override
  String get trendInsightNoWorkloadMessage =>
      'No new tasks or deadlines were added in this period.';

  @override
  String trendInsightWorkloadAddedMessage(int count) {
    return 'You added $count tasks/deadlines in this period. Plan ahead to avoid overload.';
  }

  @override
  String get trendInsightPerformanceDecliningMessage =>
      'Performance trend is decreasing. Review weak courses this week.';

  @override
  String get trendInsightPerformanceImprovingMessage =>
      'Performance trend is improving. Keep the same study consistency.';

  @override
  String get trendInsightPerformanceStableMessage =>
      'Performance trend is stable. Keep up the consistent effort.';

  @override
  String get trendInsightStableMessage =>
      'No significant change yet. Keep logging consistently.';

  @override
  String get trendInsightLimitedDataTitle => 'Limited data for period';

  @override
  String get trendInsightLimitedDataMessage =>
      'Not enough sessions tracked in this specific time range to calculate reliable trends.';

  @override
  String get trendWorsening => 'Worsening';

  @override
  String get trendUnstable => 'Unstable';

  @override
  String get trendModerate => 'Moderate';

  @override
  String get recoveryMessage => 'You are recovering. Keep this pattern.';

  @override
  String get burnoutTrendNoHistory => 'Not enough data to detect trend yet.';

  @override
  String get burnoutTrendNoRecovery => 'No recovery trend detected yet.';

  @override
  String get dashboardRiskLevelTitle => 'Risk Level';

  @override
  String dashboardRiskLevelValue(String level) {
    return 'Risk Level: $level';
  }

  @override
  String get dashboardTodaySnapshotTitle => 'Today Snapshot';

  @override
  String dashboardStudyToday(String time) {
    return 'Study: $time today';
  }

  @override
  String dashboardTasksCompletedToday(int count) {
    return 'Tasks: $count completed';
  }

  @override
  String dashboardWorkloadAddedToday(int count) {
    return 'Workload: $count added';
  }

  @override
  String get dashboardKeyInsightTitle => 'Key Insight';

  @override
  String get dashboardNoInsightAvailable => 'No key insight available yet.';

  @override
  String get dashboardQuickActionsTitle => 'Quick Actions';

  @override
  String get dashboardProgressOverviewTitle => 'Progress Overview';

  @override
  String get dashboardViewDetailedAnalysis => 'View detailed analysis ->';

  @override
  String get analyticsSparseDataTitle => 'Building your analytics';

  @override
  String get analyticsSparseDataBody =>
      'Log study sessions, add tasks, and record grades. Charts fill in as you use the app.';

  @override
  String get analyticsInsightNoStudyDataHint =>
      'No study data yet. Start tracking to unlock insights.';

  @override
  String get startTrackingYourSemester => 'Start tracking your semester';

  @override
  String get whatYouCanTrack => 'What you can track';

  @override
  String get trackTasks => 'Tasks';

  @override
  String get trackStudySessions => 'Study sessions';

  @override
  String get trackGrades => 'Grades';

  @override
  String get whyItMatters => 'Why it matters';

  @override
  String get monitorProgress => 'Monitor your progress';

  @override
  String get reduceAcademicRisk => 'Reduce academic risk';

  @override
  String get custom => 'Custom';

  @override
  String customDurationLabel(int minutes) {
    return 'Custom: ${minutes}m';
  }

  @override
  String get enterMinutes => 'Enter minutes';

  @override
  String get quickPresets => 'Quick Presets';

  @override
  String get setDuration => 'Set Duration';

  @override
  String get focusedTime => 'Focused time';

  @override
  String get startAnotherSession => 'Start another session';

  @override
  String get sessionInsightShort =>
      'Short session. Try longer focus next time.';

  @override
  String get sessionInsightMedium => 'Good session. Stay consistent.';

  @override
  String get sessionInsightLong => 'Strong focus session.';

  @override
  String addedToWeeklyGoal(int minutes) {
    return '+${minutes}m added to weekly goal';
  }

  @override
  String get minimumSessionMessage => 'Minimum session is 10 minutes';

  @override
  String get durationRangeHint => 'Enter duration (10–240 minutes)';

  @override
  String get selectCourseToStart => 'Select a course to start';

  @override
  String todayProgress(String completed, String goal) {
    return 'Today: $completed / $goal';
  }

  @override
  String weeklyProgress(String completed, String goal) {
    return 'This week: $completed / $goal';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count day$_temp0';
  }

  @override
  String get noStreak => 'Start a streak today';

  @override
  String get insightTooShort => 'Too short. Aim for at least 20 minutes.';

  @override
  String get insightDecent => 'Decent start. Try extending your next session.';

  @override
  String get insightStrong => 'Strong focus. Keep this consistency.';

  @override
  String get lowFocus => 'Low Focus';

  @override
  String get mediumFocus => 'Medium Focus';

  @override
  String get highFocus => 'High Focus';

  @override
  String get goodFocus => 'Good focus';

  @override
  String todayFocusedContext(int minutes, int sessions) {
    return '${minutes}m focused tonight • $sessions sessions';
  }

  @override
  String get studyIntent => 'Study Intent';

  @override
  String get studyIntentHint => 'What is your main focus for this session?';

  @override
  String get studyIntentPlaceholder =>
      'e.g. Read Chapter 4, Solve Calculus set...';

  @override
  String endsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String endsAround(String time) {
    return 'Ends around $time';
  }

  @override
  String get structuredSession => 'Structured session';

  @override
  String get remainingTime => 'Remaining time';

  @override
  String sessionProgress(int current, int total) {
    return 'Session $current of $total';
  }

  @override
  String get stayFocusedMsg => 'Stay focused. You\'re doing well.';

  @override
  String get halfwayMsg => 'Halfway there!';

  @override
  String get almostDoneMsg => 'Almost there, keeps it up!';

  @override
  String youStayedFocused(int minutes) {
    return 'You stayed focused for $minutes minutes';
  }

  @override
  String get recommended => 'Recommended';

  @override
  String get weeklyGoalProgress => 'Weekly Goal Progress';

  @override
  String weeklyGoalTag(int goal) {
    return 'Goal: ${goal}m';
  }

  @override
  String minutesDone(int minutes) {
    return '${minutes}m done';
  }

  @override
  String get sessionTooShort => 'Session Too Short';

  @override
  String get sessionTooShortDescription =>
      'Minimum session duration is 10 minutes to ensure effective focus. This session was not recorded.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get weeklyStudyGoal => 'Weekly Study Goal';

  @override
  String get behindThisWeek => 'You\'re behind this week — take action today';

  @override
  String get justGettingStarted => 'Just getting started';

  @override
  String remainingHours(int hours) {
    return '${hours}h remaining';
  }

  @override
  String catchUpMessage(int hours) {
    return '${hours}h remaining • You need to catch up';
  }

  @override
  String get focusScore => 'Focus Score';

  @override
  String get moderateFocus => 'Moderate Focus';

  @override
  String get patternConsistent => 'Pattern: Consistent';

  @override
  String get patternIrregular => 'Pattern: Irregular';

  @override
  String get confidenceHigh => 'Confidence: High';

  @override
  String get confidenceMedium => 'Confidence: Medium';

  @override
  String get confidenceLow => 'Confidence: Low';

  @override
  String basedOnSessions(int count) {
    return '(based on $count sessions)';
  }

  @override
  String get gettingStarted => 'Getting started';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get noDataForSemesterYet => 'No data for this semester yet';

  @override
  String get statusStable => 'Stable';

  @override
  String get statusImproving => 'Improving';

  @override
  String get statusDeclining => 'Declining';

  @override
  String get statusModerate => 'Moderate';

  @override
  String trySessionNow(int duration) {
    return 'Try a $duration-minute session now';
  }

  @override
  String get startNow => 'Start now';

  @override
  String get sessionTooShortTitle => 'Session Too Short';

  @override
  String get sessionTooShortMessage =>
      'Minimum session duration is 10 minutes. This session was not recorded.';

  @override
  String get focusRemaining => 'Remaining time';

  @override
  String get shortSessionInsight =>
      'Short session. Try longer focus next time.';

  @override
  String get goodSessionInsight => 'Good session. Stay consistent.';

  @override
  String get strongSessionInsight => 'Strong focus session.';

  @override
  String get sessionEndedEarly =>
      'Session ended early — try staying at least 15 min';

  @override
  String get niceProgressToday => 'Nice progress today';

  @override
  String get studyConsistent => 'Stay consistent this week';

  @override
  String get next15m => 'Start a 15-minute session to rebuild focus';

  @override
  String get next25m => 'Continue with a 25-minute focus session';

  @override
  String get next45m => 'You’re in deep focus mode. Try a 45-minute session';

  @override
  String sessionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
      zero: 'No sessions',
    );
    return '$_temp0';
  }

  @override
  String minutesFocused(Object minutes) {
    return '${minutes}m focused';
  }

  @override
  String get patternLabel => 'Pattern';

  @override
  String get statusVariable => 'Variable';

  @override
  String get burnoutTrendForming =>
      'Burnout risk is driven by sustained high study stress and severe study deficit.';

  @override
  String get burnoutRiskIncreasing =>
      'Risk is increasing due to low consistency and goal deficit.';

  @override
  String burnoutReasonBehindGoal(String hours) {
    return 'You are behind your weekly goal by ${hours}h.';
  }

  @override
  String get burnoutReasonInconsistent =>
      'Your study pattern is inconsistent this week.';

  @override
  String get burnoutReasonFrequentSwitching =>
      'You are switching study times frequently.';

  @override
  String get burnoutReasonLoadAboveGoal =>
      'Your total study load is above your weekly goal.';

  @override
  String get burnoutReasonNoSignals => 'No major burnout signals detected yet.';

  @override
  String get burnoutReasonDeficit =>
      'You are falling behind your weekly study goal.';

  @override
  String get burnoutReasonStress =>
      'High stress detected during study sessions.';

  @override
  String get burnoutReasonConsistency =>
      'Low study consistency over the last 7 days.';

  @override
  String get burnoutReasonMood => 'A declining mood trend has been detected.';

  @override
  String get burnoutRecStable1 => 'Keep your current routine steady.';

  @override
  String get burnoutRecStable2 => 'Continue tracking your weekly goal.';

  @override
  String get burnoutRecWarning1 => 'Reduce session length a little.';

  @override
  String get burnoutRecWarning2 =>
      'Keep your study time in one consistent slot.';

  @override
  String get burnoutRecHighRisk1 =>
      'Shorten sessions and take breaks more often.';

  @override
  String get burnoutRecHighRisk2 => 'Focus on one study time window this week.';

  @override
  String get burnoutRecHighRisk3 => 'Take a recovery day if you feel drained.';

  @override
  String get burnoutRecRisk1 => 'Reduce session length right away.';

  @override
  String get burnoutRecRisk2 => 'Increase break frequency and simplify goals.';

  @override
  String get burnoutRecRisk3 => 'Take a recovery day before pushing harder.';

  @override
  String get overloadWarning =>
      'You\'re pushing too hard. Take a proper break.';

  @override
  String focusTrendMessage(String trend) {
    return '$trend focus pattern this week';
  }

  @override
  String get focusAnalysisBasis =>
      'Based on recent sessions, consistency, and stability.';

  @override
  String get longBreakLabel => 'Long Break';

  @override
  String focusSessionCount(int current, int total) {
    return 'Focus $current/$total';
  }

  @override
  String get improving => 'Improving';

  @override
  String get declining => 'Declining';

  @override
  String get stable => 'Stable';

  @override
  String get focusShort => 'Short Focus';

  @override
  String get focusGood => 'Good Focus';

  @override
  String get focusDeep => 'Deep Focus';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusStoppedEarly => 'Stopped early';

  @override
  String get tryLongerFocus => 'Try longer focus next time';

  @override
  String get solidSession => 'Solid session, keep it up';

  @override
  String get excellentDeepWork => 'Excellent deep work';

  @override
  String get focusScoreImpact => 'Focus Score Impact';

  @override
  String get completedYes => 'Yes';

  @override
  String get completedNo => 'No';

  @override
  String get cycles => 'Cycles';

  @override
  String get breaksSkipped => 'Breaks skipped';

  @override
  String get weeklyActivity => 'Weekly Activity';

  @override
  String get streakWarningMessage =>
      '🔥 Don\'t break your streak. Study today to keep it alive!';

  @override
  String get preivousWeekLabel => 'Last week';

  @override
  String get newWeekStart => 'New week start';

  @override
  String get noStudyActivityYet => 'No study activity yet';

  @override
  String get studiedOnlyOneDay => 'You studied only one day this week';

  @override
  String get gettingStartedExtend => 'Getting started. Try to extend sessions';

  @override
  String get buildingConsistency => 'Building consistency';

  @override
  String get strongConsistentPattern => 'Strong and consistent study pattern';

  @override
  String get noActivity => 'No activity';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get weeklyProgressLabel => 'Weekly Progress';

  @override
  String get newBadge => 'New ⭐';

  @override
  String weeklyGoalProgressHours(String current, String goal) {
    return '$current / $goal';
  }

  @override
  String activeDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count active day$_temp0';
  }

  @override
  String peakDayLabel(String day) {
    return 'Peak: $day';
  }

  @override
  String get streakAtRisk => 'Streak at Risk!';

  @override
  String get studyHabit => 'Study Habit';

  @override
  String get startStreakToday => 'Start your streak today';

  @override
  String get streakDay1 => 'Day 1 completed. Build consistency tomorrow';

  @override
  String get strongHabitForming => 'Strong habit forming';

  @override
  String get excellentDiscipline => 'Excellent discipline';

  @override
  String get lightFocus => 'Light focus';

  @override
  String get insightCycle => 'High-quality focus pattern. Keep this cycle.';

  @override
  String get insightStart =>
      'Strong start. Extend beyond 30m for deeper focus.';

  @override
  String get insightMomentum => 'Building momentum toward deep work.';

  @override
  String focusPoints(String points) {
    return '$points points';
  }

  @override
  String get pomodoroFocusStep => 'Focus • 25 min';

  @override
  String get pomodoroBreakStep => 'Break • 5 min';

  @override
  String get pomodoroRepeatStep => '4 cycles total';

  @override
  String pomodoroTotalFocusSummary(int minutes) {
    return 'Total focus: $minutes min';
  }

  @override
  String get pomodoroCompleted => 'Pomodoro completed';

  @override
  String cyclesCompleted(int count) {
    return '$count cycles completed';
  }

  @override
  String focusTimeBreakdown(int minutes) {
    return 'Focus time: $minutes min';
  }

  @override
  String breakTimeBreakdown(int minutes) {
    return 'Break time: $minutes min';
  }

  @override
  String get excellentConsistency => 'Excellent consistency';

  @override
  String get totalFocusTime => 'Total focus time';

  @override
  String streakDaysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count day$_temp0 in a row';
  }

  @override
  String get pomodoroMetrics => 'Metrics';

  @override
  String get pomodoroPerformance => 'Performance';

  @override
  String get pomodoroTimeline => 'Cycle Timeline';

  @override
  String pomodoroSubtitle(int done, int total) {
    return 'Pomodoro • $done/$total cycles';
  }

  @override
  String focusCycleDone(int index, int minutes) {
    return 'Focus $index  •  $minutes min';
  }

  @override
  String focusCycleInProgress(int index) {
    return 'Focus $index  •  in progress';
  }

  @override
  String focusCycleNotReached(int index) {
    return 'Focus $index  •  not reached';
  }

  @override
  String breakDone(int minutes) {
    return 'Break  •  $minutes min';
  }

  @override
  String get breakPending => 'Break';

  @override
  String get focusTimeLabel => 'Focus Time';

  @override
  String get breakTimeLabel => 'Break Time';

  @override
  String completionOfCycles(int percent) {
    return '$percent% of planned cycles';
  }

  @override
  String minutesFocusedLabel(int minutes) {
    return '$minutes min focused';
  }

  @override
  String pomodoroHistorySubtitle(int done, int total, String time) {
    return '$done of $total cycles • $time';
  }

  @override
  String sessionHistorySubtitle(String type, int minutes, String time) {
    return '$type • ${minutes}m • $time';
  }

  @override
  String get statusBadgeCompleted => '✔ Completed';

  @override
  String get statusBadgeStopped => '⏸ Stopped early';

  @override
  String errorLoading(String error) {
    return 'Error: $error';
  }

  @override
  String get pomodoroInsightConsistent =>
      'You consistently complete full Pomodoro cycles';

  @override
  String get pomodoroInsightPartial =>
      'You often stop mid-cycle. Try shorter sessions';

  @override
  String get pomodoroInsightNeedsWork =>
      'You rarely complete Pomodoro cycles. Consider reducing duration';

  @override
  String get studyActivity => 'Study Activity';

  @override
  String heatmapTooltip(String date, int minutes, int sessions, int score) {
    return '$date: ${minutes}m • $sessions sessions • Score: $score';
  }

  @override
  String get heatmapLegendLess => 'Less';

  @override
  String get heatmapLegendMore => 'More';

  @override
  String get heatmapDayDetails => 'Day Details';

  @override
  String streakCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get studyIntensitySubtitle => 'Your daily study intensity over time';

  @override
  String get buildStreak => 'BUILD YOUR STREAK';

  @override
  String get buildStreakSubtitle =>
      'Your study activity history will appear here';

  @override
  String get goodConsistency => 'Good consistency';

  @override
  String get activity => 'Activity';

  @override
  String get sessions => 'Sessions';

  @override
  String get min => 'min';

  @override
  String heatmapActivityLegendTooltip(Object label) {
    return 'Activity: $label';
  }

  @override
  String minutesShort(Object count) {
    return '$count min';
  }

  @override
  String get startSession => 'Start Session';

  @override
  String targetPrefix(String target) {
    return 'Target: $target';
  }

  @override
  String get recommendedForYouTitle => 'Recommended for you';

  @override
  String get keepMyPreference => 'Keep my preference';

  @override
  String get followActualBehavior => 'Follow actual behavior';

  @override
  String bestStudyTimeBullet(String time) {
    return '• Best study time: $time';
  }

  @override
  String suggestedSessionBullet(int minutes, String pattern) {
    return '• Suggested session: $minutes min ($pattern)';
  }

  @override
  String dailyTargetNeededBullet(String hours) {
    return '• You need ~$hours hours/day to stay on track';
  }

  @override
  String burnoutInputsHumanized(String deficit, int inconsistency) {
    return '• Study deficit: ${deficit}h\n• Consistency: $inconsistency%';
  }

  @override
  String get patternIrregularThisWeek =>
      '• Pattern note: your study times are currently irregular this week.';

  @override
  String adaptiveHintRecentStudyTime(String time) {
    return 'You seem to study more in $time recently.';
  }

  @override
  String weekSessionsBreakdown(int morning, int afternoon, int night) {
    return 'This week sessions: morning $morning, afternoon $afternoon, night $night.';
  }

  @override
  String confidenceBreakdown(int behavior, int preference, String trendText) {
    return 'Confidence: behavior $behavior% • preference match $preference% $trendText';
  }

  @override
  String trendDeltaVsLastWeek(String delta) {
    return '• trend $delta vs last week';
  }

  @override
  String weeklyGoalBehindDetailed(String logged, String expected) {
    return 'You are behind your weekly goal (${logged}h logged vs ${expected}h expected by now).';
  }

  @override
  String get warningActionStartSession =>
      'Start a 25-40 min session now to get back on track.';

  @override
  String get weeklyGoalSlightlyBehind =>
      'You are slightly behind your weekly goal. Keep your current pace.';

  @override
  String get burnoutStatusTitle => 'Burnout Status';

  @override
  String burnoutOverallTrend(String status) {
    return 'Overall: $status';
  }

  @override
  String burnoutTrendLine(String status, String direction) {
    return 'Trend: $status $direction';
  }

  @override
  String burnoutDeficitLine(String status, String direction) {
    return 'Deficit: $status $direction';
  }

  @override
  String burnoutConsistencyLine(String status, String direction) {
    return 'Consistency: $status $direction';
  }

  @override
  String get noRecoveryTrendDetectedYet => 'No recovery trend detected yet.';

  @override
  String get notEnoughDataTrendYet => 'Not enough data to detect trend yet.';

  @override
  String get recoveryImprovingThisWeek =>
      'Your study pattern is improving this week.';

  @override
  String studyDeficitBasedOnWeeklyGoal(String hours) {
    return 'Study deficit is based on your weekly goal (${hours}h).';
  }

  @override
  String get softInterventionsTitle => 'Soft interventions';

  @override
  String get burnoutLevelStable => 'Stable';

  @override
  String get burnoutLevelWarning => 'Warning';

  @override
  String get burnoutLevelHighRisk => 'High Risk';

  @override
  String get burnoutLevelBurnoutRisk => 'Burnout Risk';

  @override
  String get burnoutExplanationStable =>
      'Your study pattern looks balanced right now.';

  @override
  String get burnoutExplanationWarning =>
      'Your study pattern is becoming inconsistent and you are falling behind your weekly goal.';

  @override
  String get burnoutExplanationHighRisk =>
      'You are showing signs of inconsistent study and deficit.';

  @override
  String get burnoutExplanationBurnoutRisk =>
      'Your load is high and your routine is becoming unstable.';

  @override
  String get burnoutReasonInconsistentPattern =>
      'Your study pattern is inconsistent this week.';

  @override
  String get burnoutReasonSwitchingTimes =>
      'You are switching study times frequently.';

  @override
  String get burnoutReasonNoMajorSignals =>
      'No major burnout signals detected yet.';

  @override
  String get burnoutRecommendationStable1 =>
      'Keep your current routine steady.';

  @override
  String get burnoutRecommendationStable2 =>
      'Continue tracking your weekly goal.';

  @override
  String get burnoutRecommendationWarning1 => 'Reduce session length a little.';

  @override
  String get burnoutRecommendationWarning2 =>
      'Keep your study time in one consistent slot.';

  @override
  String get burnoutRecommendationHigh1 =>
      'Shorten sessions and take breaks more often.';

  @override
  String get burnoutRecommendationHigh2 =>
      'Focus on one study time window this week.';

  @override
  String get burnoutRecommendationHigh3 =>
      'Take a recovery day if you feel drained.';

  @override
  String get burnoutRecommendationBurnout1 =>
      'Reduce session length right away.';

  @override
  String get burnoutRecommendationBurnout2 =>
      'Increase break frequency and simplify goals.';

  @override
  String get burnoutRecommendationBurnout3 =>
      'Take a recovery day before pushing harder.';

  @override
  String get decisionNextActionTitle => 'Next Action';

  @override
  String get decisionStudyAnyCourse => 'Study your priority course';

  @override
  String decisionStudyCourse(String course) {
    return 'Study $course';
  }

  @override
  String decisionMinutesToday(int minutes) {
    return '$minutes minutes today';
  }

  @override
  String get decisionFocusRecommendationTitle => 'Focus Recommendation';

  @override
  String get decisionWhatChangedTitle => 'What Changed';

  @override
  String get decisionTaskLoadLabel => 'Task Load';

  @override
  String get decisionConfidenceLow =>
      'Confidence: Low (based on recent activity)';

  @override
  String get startedFromAnalyticsRecommendation =>
      'Started from Analytics recommendation';

  @override
  String get followedPlanToday => 'Nice. You followed your plan today.';

  @override
  String sessionImpactAddedToCourse(int minutes, String course) {
    return '+$minutes min added to $course';
  }

  @override
  String get sessionImpactCloserToGoal =>
      'You\'re now closer to your weekly goal';

  @override
  String get decisionReasonOverdueAttention =>
      'Overdue tasks need immediate attention';

  @override
  String get decisionReasonLeastStudied =>
      'You studied this course the least this week';

  @override
  String get decisionReasonNoUrgentDeadlines =>
      'No urgent deadlines. Stay consistent.';

  @override
  String get decisionReasonBehindWeeklyTarget =>
      'You are behind your weekly target';

  @override
  String get decisionReasonHeavyWorkload =>
      'Heavy open workload in this course';

  @override
  String get decisionReasonHighestPriority =>
      'This is your highest-priority course right now';

  @override
  String get decisionReasonBuildRoutine => 'Start building your routine';

  @override
  String get decisionReasonLowestStudyWeek => 'Lowest study time this week';

  @override
  String get decisionReasonNoStudyLogged => 'No study logged this week';

  @override
  String get decisionReasonFallbackConsistency =>
      'Fallback recommendation: keep your consistency this week';

  @override
  String decisionReasonStudyProgress(String studied, String target) {
    return 'You studied ${studied}h of your ${target}h target';
  }

  @override
  String decisionReasonImportantCourse(int ects) {
    return 'Important course ($ects ECTS)';
  }

  @override
  String decisionReasonHigherPriorityThan(String course) {
    return 'More urgent than $course';
  }

  @override
  String get decisionReasonHigherPriorityGeneral =>
      'More urgent than other courses this week';

  @override
  String get todayPlanTitle => 'Today Plan';

  @override
  String todayMinutesCompleted(int minutes) {
    return 'Today: $minutes min completed';
  }

  @override
  String get recoveryPlanTitle => 'Recovery Plan';

  @override
  String get recoveryPlanSplitFromWeeklyDeficit =>
      'Split based on your weekly deficit';

  @override
  String get planDay3Label => 'Day 3';

  @override
  String suggestedSplitSessionsToday(int count, int minutes) {
    return 'Suggested: $count × $minutes min sessions today';
  }

  @override
  String get suggestedFlexibleSessionsToday =>
      'Suggested: 2-3 focused sessions today';

  @override
  String get suggestedShorterSessionsToday =>
      'Suggested: 3-4 shorter sessions today';

  @override
  String get recoveryMessageStressHigh =>
      'Focus on shorter sessions today to avoid burnout';

  @override
  String needHoursTodayToStayOnTrack(String hours) {
    return 'You need ${hours}h today to stay on track';
  }

  @override
  String minutesRemainingShort(int minutes) {
    return '${minutes}m left';
  }

  @override
  String decisionReasonDeadlineLowStudy(int days) {
    return 'Deadline in $days days and you studied less than usual this week';
  }

  @override
  String decisionReasonDeadlineInDays(int days) {
    return 'Deadline in $days days';
  }

  @override
  String decisionReasonLowestStudyWithDeadline(int days) {
    return 'Lowest study time this week and deadline in $days days';
  }

  @override
  String decisionReasonLowestStudyWithOpenTasks(int count) {
    return 'Lowest study time this week and $count open tasks';
  }

  @override
  String decisionReasonHighCourseWeight(int ects) {
    return 'High course weight ($ects ECTS)';
  }

  @override
  String get reset => 'Reset';

  @override
  String get status => 'Status';

  @override
  String get logMoodTitle => 'Log Mood';

  @override
  String get moodAfterSessionPrompt =>
      'How do you feel after this study session?';

  @override
  String get moodManualPrompt =>
      'Track your current mood and stress to improve your study insights.';

  @override
  String get moodLevel => 'Mood Level';

  @override
  String get stressLevel => 'Stress Level';

  @override
  String get energyLevel => 'Energy Level';

  @override
  String get moodFactors => 'Factors';

  @override
  String get moodFactorSleep => 'Sleep';

  @override
  String get moodFactorWorkload => 'Workload';

  @override
  String get moodFactorHealth => 'Health';

  @override
  String get moodFactorMotivation => 'Motivation';

  @override
  String get moodFactorSocial => 'Social';

  @override
  String get moodFactorExams => 'Exams';

  @override
  String get saveMood => 'Save Mood';

  @override
  String get moodSaved => 'Mood log saved.';

  @override
  String get moodSaveFailed => 'Could not save mood log.';

  @override
  String get moodAndStressTitle => 'Mood & Stress';

  @override
  String get moodAverageLabel => 'Average Mood';

  @override
  String get stressAverageLabel => 'Average Stress';

  @override
  String get moodNoData => 'No data';

  @override
  String get moodSettingsTitle => 'Mood & Stress Settings';

  @override
  String get enableMoodTracking => 'Enable Mood Tracking';

  @override
  String get enableMoodReminders => 'Enable Reminders';

  @override
  String get reminderTimeLabel => 'Reminder Time';

  @override
  String get reminderTypeLabel => 'Reminder Type';

  @override
  String get reminderTypeDaily => 'Daily';

  @override
  String get reminderTypeAfterStudy => 'After Study';

  @override
  String get reminderTypeBoth => 'Both';

  @override
  String get moodHistoryTitle => 'Mood History';

  @override
  String get moodDailyPromptTitle => 'How are you feeling today?';

  @override
  String get moodDailyPromptSubtitle =>
      'Track mood and stress to improve your study decisions.';

  @override
  String get moodReminderTitle => 'Mood check-in';

  @override
  String get moodReminderBody => 'Take a minute to log your mood and stress.';

  @override
  String get moodLast7Days => 'Mood over last 7 days';

  @override
  String moodOverLastDays(int count) {
    return 'Mood over last $count days';
  }

  @override
  String get moodKeepLogging => 'Keep logging your mood';

  @override
  String get moodTrendNeedsData =>
      'Keep logging your mood to see your personal emotional trend chart.';

  @override
  String get dailyMoodHistory => 'Daily Mood History';

  @override
  String get olderLabel => 'Older';

  @override
  String get decisionSmartInsights => 'AI Insight';

  @override
  String get decisionHighStress => 'High stress detected';

  @override
  String get decisionShortSessions => 'Use shorter sessions today';

  @override
  String get decisionDeepWork => 'You are in a strong state for deep work';

  @override
  String get decisionBurnoutWarning => 'Burnout risk is increasing';

  @override
  String get decisionStressRising => 'Your stress is rising this week';

  @override
  String get decisionMoodDeclining => 'Your mood is declining';

  @override
  String get decisionDeadlinePressure =>
      'High pressure detected. Break tasks down';

  @override
  String get decisionLowActivityHighStress => 'Low Activity, High Stress';

  @override
  String get decisionLightTasksOnly =>
      'Mood is low today. Stick to lighter tasks.';

  @override
  String decisionMainFactor(String factor) {
    return 'Main Factor: $factor';
  }

  @override
  String decisionWorstDay(String day) {
    return 'Difficult $day ahead';
  }

  @override
  String get decisionMorningPlanning => 'Morning Strategy';

  @override
  String get decisionAfternoonExecution => 'Afternoon Peak';

  @override
  String get decisionNightLightReview => 'Night Review';

  @override
  String get decisionActionShortSessions =>
      'High stress with low activity detected. Try 15-min sessions.';

  @override
  String get decisionActionBreakDown =>
      'Break down large tasks to reduce session stress.';

  @override
  String get decisionActionMonitorWeekly =>
      'Monitor this pattern through the week';

  @override
  String get decisionActionPlanning =>
      'Start with planning. Clear goals reduce session anxiety.';

  @override
  String get decisionActionExecution =>
      'Execute difficult tasks now while energy is high.';

  @override
  String get decisionActionLightReview =>
      'Stress is trending up. Consider a lighter study session.';

  @override
  String startRecommendedSession(int minutes) {
    return 'Start Recommended Session ($minutes min)';
  }

  @override
  String get smartInsightUpdated => 'Smart Insight Updated';

  @override
  String get moodSavedPositive1 => 'Saved. Great consistency.';

  @override
  String get moodSavedPositive2 => 'Saved. Keep going.';

  @override
  String get moodSavedPositive3 => 'Saved. Nice progress.';

  @override
  String get moodSavedPositive4 => 'Saved. You are doing well.';

  @override
  String get todaysMoodTitle => 'Today\'s Mood';

  @override
  String stressOutOfTen(int value) {
    return 'Stress $value/10';
  }

  @override
  String get takeItSlowerTodayTitle => 'Take it slower today';

  @override
  String get takeItSlowerTodayBody =>
      'You have multiple deadlines soon. Pace yourself.';

  @override
  String get strongStateTitle => 'Peak Focus State';

  @override
  String get strongStateBody =>
      'You are in a great mood with low stress. Tackle a difficult task!';

  @override
  String get view => 'View';

  @override
  String get focusRecommendationPrimary => 'Focus Recommendation (Primary)';

  @override
  String get decisionConfidenceHigh =>
      'Confidence: High (based on recent activity)';

  @override
  String get decisionConfidenceMedium =>
      'Confidence: Medium (based on recent activity)';

  @override
  String get decisionBurnoutDurationCap =>
      'Shorter sessions recommended to prevent burnout.';

  @override
  String get decisionFixedSchedule => 'Build a fixed schedule';

  @override
  String get decisionActionFixedSchedule =>
      'Establishing a routine can lower daily session stress.';

  @override
  String get postSessionMoodImproved => 'Your mood improved after studying';

  @override
  String get postSessionStressIncreased =>
      'Long sessions may be increasing your stress';

  @override
  String get postSessionFeedbackLogged => 'Post-session feedback captured';

  @override
  String consistencyScoreLine(int score, String trend) {
    return 'Consistency: $score% ($trend)';
  }

  @override
  String get predictionStressTitle => 'Predicted Stress (Next 3 Days)';

  @override
  String get predictionPlanTitle => 'Recommended Plan';

  @override
  String get predictionLevelLow => 'LOW';

  @override
  String get predictionLevelMedium => 'MEDIUM';

  @override
  String get predictionLevelHigh => 'Stress trend: Increasing';

  @override
  String predictionReasonHighStressToday(String stress) {
    return 'Stress: $stress/10';
  }

  @override
  String predictionReasonLowConsistency(String percent) {
    return 'Consistency: $percent%';
  }

  @override
  String predictionReasonUpcomingWorkload(int count) {
    return 'Deadlines: $count';
  }

  @override
  String get predictionMainReasonTitle => 'Main reason:';

  @override
  String get predictionWhyTitle => 'Why this plan?';

  @override
  String predictionReasonStressHigh(String stress) {
    return 'Stress: $stress/10';
  }

  @override
  String predictionReasonLowConsistencyDetail(String delta) {
    return 'Consistency: $delta%';
  }

  @override
  String predictionReasonTasksPending(int count) {
    return 'Pending tasks: $count';
  }

  @override
  String predictionReasonDeadlinesSoon(int count) {
    return 'Deadlines: $count';
  }

  @override
  String get predictionAffectedTitle => 'Affected:';

  @override
  String predictionPlanLine(
    String day,
    String time,
    int minutes,
    String focus,
  ) {
    return '$day at $time • $minutes min $focus session';
  }

  @override
  String predictionPlanLineSimple(String day, int minutes, String focus) {
    return '• $day: $minutes min $focus';
  }

  @override
  String get predictionPlanLightFocus => 'Light Focus Session';

  @override
  String get predictionPlanFocusExecution => 'Focus Execution Session';

  @override
  String get predictionPlanDeepExecution => 'Deep Execution Session';

  @override
  String get predictionPlanLightReview => 'Light Review Session';

  @override
  String predictionPerformanceRisk(String level) {
    return 'Performance Risk: $level';
  }

  @override
  String predictionPerformanceRiskLagging(String level, String courses) {
    return 'Performance Risk: $level • Falling behind: $courses';
  }

  @override
  String get moodNameAwful => 'Awful';

  @override
  String get moodNameBad => 'Bad';

  @override
  String get moodNameNeutral => 'Neutral';

  @override
  String get moodNameGood => 'Good';

  @override
  String get moodNameGreat => 'Great';

  @override
  String imFeelingMood(String mood) {
    return 'I\'m feeling $mood';
  }

  @override
  String saveMoodDots(String mood, String stress) {
    return 'Save Mood • $mood • Stress $stress';
  }

  @override
  String get addQuickNoteOptional => 'Add a quick note (optional)';

  @override
  String get analyticsMoodPerformanceTitle => '🧠 Mood vs Performance';

  @override
  String get analyticsMoodPerformanceGoodDesc =>
      'Your high mood positively impacts your focus duration.';

  @override
  String analyticsMoodLabel(String label, String value, String trend) {
    return '🙂 $label: $value $trend';
  }

  @override
  String analyticsStressLabel(String label, String value, String trend) {
    return '⚡ $label: $value $trend';
  }

  @override
  String analyticsImpactPositive(int minutes) {
    return '🚀 +${minutes}m';
  }

  @override
  String analyticsImpactNegative(int minutes) {
    return '📉 -${minutes}m';
  }

  @override
  String get analyticsMoodPerformanceBadDesc =>
      'Low mood is restricting your session efficiency.';

  @override
  String get analyticsMoodPerformanceStableDesc =>
      'Your mood is stable, allowing for consistent focus.';

  @override
  String get analyticsMoodBetterMood => 'Better Mood';

  @override
  String get analyticsMoodHighStress => 'High Stress';

  @override
  String get analyticsMoodFocusBoost => 'Focus Boost';

  @override
  String get analyticsMoodFocusDrain => 'Focus Drain';

  @override
  String analyticsMoodDifference(Object minutes, Object plusMinus) {
    return '$plusMinus${minutes}m';
  }

  @override
  String get burnoutMessageEmotionalRisk =>
      'Emotional volatility detected in recent sessions. Prioritize mental health.';

  @override
  String get decisionStatusModerateStress => 'Moderate stress detected';

  @override
  String get decisionStatusLowStress => 'Low stress';

  @override
  String get decisionStatusHighStress => 'High stress detected';

  @override
  String get predictionStressLikelyIncrease =>
      'Stress likely to increase due to low recovery and rising pressure';

  @override
  String get analyticsNotEnoughData => 'Not enough data yet';

  @override
  String get decisionRisingStressUnstablePattern =>
      'Your stress is rising while your routine is unstable';

  @override
  String get decisionActionFixedScheduleFocus =>
      'Study at the same time for 3 days to stabilize focus';

  @override
  String get burnoutRisingStressInconsistentPattern =>
      'Your stress is increasing while your study pattern is inconsistent';

  @override
  String predictionPressureLikelyToIncrease(String hours) {
    return 'Study deficit: ${hours}h';
  }

  @override
  String get analyticsMoodCorrelationDetected => 'Correlation detected';

  @override
  String analyticsMoodStudyDropped(String percent) {
    return 'Study dropped by $percent%';
  }

  @override
  String analyticsMoodMoodDropped(String percent) {
    return 'Mood dropped by $percent%';
  }

  @override
  String get burnoutShortExplanation =>
      'Your study pattern looks balanced right now.';

  @override
  String get signalStressHigh => 'High stress';

  @override
  String get signalStressMedium => 'Moderate stress';

  @override
  String get signalMoodLow => 'Low mood';

  @override
  String get signalConsistencyLow => 'Unstable routine';

  @override
  String get signalDeficitHigh => 'Study deficit';

  @override
  String get consistency => 'Consistency';

  @override
  String get stress => 'Stress';

  @override
  String get moodTrends => 'Mood Trends';

  @override
  String get studyProfileTitle => 'Your Study Profile';

  @override
  String studyProfileOptimalDuration(int min, int max) {
    return 'Optimal Session: $min-$max min';
  }

  @override
  String studyProfileStressThreshold(String value) {
    return 'Focus drops when stress > $value';
  }

  @override
  String studyProfilePeakWindow(String window) {
    return 'Peak Productivity: $window';
  }

  @override
  String get studyProfileMorning => 'Morning';

  @override
  String get studyProfileAfternoon => 'Afternoon';

  @override
  String get studyProfileEvening => 'Evening';

  @override
  String studyProfileMainFactor(String factor) {
    return 'Main factor: $factor';
  }

  @override
  String studyProfileSecondaryFactor(String factor) {
    return 'Secondary: $factor';
  }

  @override
  String get completion => 'Completion';

  @override
  String get moodEnergyLevel => 'Energy Level';

  @override
  String get moodLoggedSession => 'Logged after study session';

  @override
  String get moodLoggedManual => 'Logged manually';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get mood => 'Mood';

  @override
  String get academic => 'Academic';

  @override
  String get moodCheckNotificationTitle => 'Mood check-in';

  @override
  String get moodCheckNotificationMessage =>
      'How are you feeling today? Log your mood to keep insights accurate.';

  @override
  String get dailyBaseline => 'Daily Baseline';

  @override
  String get studySessions => 'Study Sessions';

  @override
  String get notificationOverdue => 'is overdue';

  @override
  String get notificationDueToday => 'is due today';

  @override
  String get notificationDueTomorrow => 'is due tomorrow';

  @override
  String get notificationDueSoon => 'is due soon';

  @override
  String get weeklyStudyGoalMissed => 'Weekly study goal missed';

  @override
  String weeklyStudyGoalMissedMessage(Object actual, Object goal) {
    return 'You studied ${actual}h of ${goal}h this week.';
  }

  @override
  String get decisionRisingStressTitle => 'Rising Stress Levels';

  @override
  String get decisionStatusDeficit => 'Large study deficit';

  @override
  String get decisionStatusInconsistent => 'Inconsistency detected';

  @override
  String get baseline => 'Baseline';

  @override
  String get predictionCollectingData => 'Collecting Data';

  @override
  String get predictionCollectingDataDetail =>
      'Studying 5 or more sessions will activate full AI insights.';

  @override
  String decisionRecommendedSession(int minutes) {
    return 'Recommended: $minutes min';
  }

  @override
  String get moodTerrible => 'Terrible';

  @override
  String get moodBad => 'Bad';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodGood => 'Good';

  @override
  String get moodAmazing => 'Amazing';

  @override
  String get moodUnknown => 'Unknown';

  @override
  String get hideDetails => 'Hide details';

  @override
  String get viewFullAnalysis => 'View full analysis';

  @override
  String get unknown => 'Unknown';

  @override
  String get selectedSemester => 'Selected Semester';

  @override
  String minutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String minutesCourseValue(int minutes, String course) {
    return '$minutes min $course';
  }

  @override
  String get smartAiInsights => 'AI Insight';

  @override
  String get burnoutExplanationFallingBehind =>
      'You are showing signs of mental fatigue and irregular study habits.';

  @override
  String get burnoutBehaviorHighFatigue =>
      'Elevated mental fatigue levels detected.';

  @override
  String get burnoutBehaviorMoodInstability =>
      'Increasing mood variability impacting focus.';

  @override
  String get burnoutBehaviorIrregularRest =>
      'Inconsistent rest periods between sessions.';

  @override
  String get burnoutBehaviorUnpredictableRhythm =>
      'Unpredictable study rhythm and timing.';

  @override
  String get burnoutBehaviorSwitchingContext =>
      'Frequent context switching affecting deep focus.';

  @override
  String get burnoutBehaviorMentalOverload =>
      'Cognitive load exceeding typical recovery rates.';

  @override
  String consistencyPercentage(Object score) {
    return 'Consistency: $score%';
  }

  @override
  String labelWithColon(Object label) {
    return '$label:';
  }

  @override
  String labelWithColonAndSpace(Object label) {
    return '$label: ';
  }

  @override
  String get examsTitle => 'Exams';

  @override
  String get examsLoadError => 'Could not load exams';

  @override
  String get examsAddCta => 'Add Exam';

  @override
  String get examsUpcomingSectionTitle => 'Upcoming exams';

  @override
  String get examsPastSectionTitle => 'Past exams';

  @override
  String get examsNoUpcoming => 'No upcoming exams for this semester';

  @override
  String get examsNoUpcomingSubtitle =>
      'Tap \"Add Exam\" to create your schedule';

  @override
  String get examsNoPast => 'No past exams for this semester';

  @override
  String get examsTypeMidterm => 'Midterm';

  @override
  String get examsTypeFinal => 'Final';

  @override
  String get examsTypeQuiz => 'Quiz';

  @override
  String get examTypeQuiz => 'Quiz';

  @override
  String get examsLocationOnline => 'Online Exam';

  @override
  String get examsLocationFaceToFace => 'Face-to-face Exam';

  @override
  String get examsLocationClassroomPrefix => 'Room';

  @override
  String get examsInstructorPrefix => 'Instructor:';

  @override
  String get examsCoursePrefix => 'Course:';

  @override
  String get examsTitleField => 'Exam title';

  @override
  String get examsPickDateTimeError => 'Please select date and time';

  @override
  String get examsCreateError => 'Could not create exam';

  @override
  String get examsOptionalCourse => 'Optional course';

  @override
  String get examsCourseOptionalField => 'Course (optional)';

  @override
  String get examsDateField => 'Exam date';

  @override
  String get examsTimeField => 'Exam time';

  @override
  String get examsOnlineToggle => 'Online exam';

  @override
  String get examsClassroomField => 'Classroom';

  @override
  String get examsInstructorField => 'Instructor';

  @override
  String get examsNotesOptionalField => 'Notes (optional)';

  @override
  String get examsCreateButton => 'Create Exam';

  @override
  String get editExam => 'Edit Exam';

  @override
  String get examsUpdateError => 'Could not update exam';

  @override
  String get examsNotFound => 'Exam not found';

  @override
  String get examsNoItems => 'No exams';

  @override
  String get examsCalendarTitle => 'Exam Calendar';

  @override
  String get examsNoItemsForDay => 'No exams this day';

  @override
  String get examsCalendarOpenTooltip => 'Open exam calendar';

  @override
  String get examUrgencyNoExamsSoon => 'No exams soon';

  @override
  String examUrgencyUpcoming(Object count, Object days) {
    return '$count exams in next $days days';
  }

  @override
  String get examUrgencyHeavyWeek => 'Heavy exam period';

  @override
  String get examDetailTitle => 'Exam Details';

  @override
  String get examDetailDeletePrompt => 'Delete this exam?';

  @override
  String get examDetailDeleteWarning => 'This action cannot be undone.';

  @override
  String get examDetailDeleteWarningStrong =>
      'This will permanently remove the exam and its reminders.';

  @override
  String get examsNextCardTitle => 'Next Exam';

  @override
  String examsInDays(int days) {
    return 'In $days days';
  }

  @override
  String aiDetRiskIncreased(Object delta, Object core) {
    return 'Your risk increased by $delta% this week.\n$core';
  }

  @override
  String aiDetHighStressInsight(Object stress) {
    return 'Session stress is high ($stress/10). That usually means overload or fatigue.';
  }

  @override
  String get aiDetHighStressRecoPrimary =>
      'Today: one 20-30 minute session, single topic.';

  @override
  String get aiDetHighStressRecoSecondary =>
      'Take a 5-minute break before you start the next block.';

  @override
  String aiDetOverdueInsight(Object count) {
    return 'You have $count overdue tasks this semester - that pulls your risk up until they move.';
  }

  @override
  String get aiDetOverdueRecoPrimary =>
      'Today: finish or reschedule the smallest overdue item first.';

  @override
  String get aiDetOverdueRecoSecondary =>
      'Then pick the next smallest - estimate a time box before you start.';

  @override
  String aiDetRiskHighInsight(Object score) {
    return 'Academic risk is high ($score/100). Tasks, study time, or consistency are stacking.';
  }

  @override
  String aiDetRiskHighRecoPrimary(Object dueSoon) {
    return 'Before 18:00: tackle the top due-soon or overdue item ($dueSoon due-soon).';
  }

  @override
  String get aiDetRiskHighRecoSecondary =>
      'Calendar two 25-40 minute blocks; start the first within 2 hours.';

  @override
  String aiDetRiskModerateInsight(Object score) {
    return 'Academic risk is moderate ($score/100). Weekly progress is below target and needs recovery actions.';
  }

  @override
  String aiDetRiskModerateRecoPrimary(Object minutes) {
    return 'Start one focused session now ($minutes min).';
  }

  @override
  String aiDetModerateSecondaryDueSoon(Object count) {
    return 'Reorder your $count due-soon tasks by deadline tonight.';
  }

  @override
  String aiDetModerateSecondaryDeficitMulti(
    Object sessions,
    Object m1,
    Object m2,
  ) {
    return 'Today: do $sessions sessions ($m1 + $m2 min) to reduce deficit faster.';
  }

  @override
  String aiDetModerateSecondaryDeficitSingle(Object minutes) {
    return 'Today: start one $minutes-minute recovery session.';
  }

  @override
  String get aiDetModerateSecondaryTomorrow =>
      'Tomorrow: second 30-minute block so risk does not climb.';

  @override
  String get aiDetDefaultInsight =>
      'Snapshot looks manageable: no overdue flag here and risk is not in the high band.';

  @override
  String get aiDetDefaultRecoPrimary => 'Today: one 25-minute review session.';

  @override
  String get aiDetDefaultRecoSecondary =>
      'Mid-week: reload deadlines and date any undated tasks.';

  @override
  String get aiTaskUrgentInsight =>
      'You have high-priority open work - tackle it before optional tasks.';

  @override
  String get aiTaskUrgentRecoPrimary => 'Finish one urgent item to completion.';

  @override
  String get aiTaskUrgentRecoSecondary =>
      'Then pick the next urgent line only.';

  @override
  String get aiTaskBacklogInsight => 'Large backlogs increase avoidance.';

  @override
  String get aiTaskBacklogRecoPrimary =>
      'Today: finish the two smallest tasks.';

  @override
  String get aiTaskBacklogRecoSecondary =>
      'That shrinks the list you see every morning.';

  @override
  String get aiTaskQueuedInsight => 'Queued work without dates tends to slip.';

  @override
  String get aiTaskQueuedRecoPrimary =>
      'Schedule the next two tasks on your calendar.';

  @override
  String get aiTaskQueuedRecoSecondary =>
      'Give each a start time, not only a due date.';

  @override
  String get aiTaskNoneInsight => 'No urgent items in this view.';

  @override
  String get aiTaskNoneRecoPrimary =>
      'Use spare time for readings or long assignments.';

  @override
  String get aiTaskNoneRecoSecondary =>
      'Add the next exam date if it is not in yet.';

  @override
  String aiDetDeficitHighInsight(Object hours) {
    return 'You are about ${hours}h behind your weekly study goal - missing multiple days adds up fast.';
  }

  @override
  String get aiDetDeficitHighRecoPrimary =>
      'Today: schedule 2-3 blocks (25-40 min each) on your calendar.';

  @override
  String get aiDetDeficitHighRecoSecondary =>
      'Use fixed times - not \"when I feel like it.\"';

  @override
  String aiDetDeficitMediumInsight(Object hours) {
    return 'You are roughly ${hours}h under your weekly goal.';
  }

  @override
  String get aiDetDeficitMediumRecoPrimary =>
      'Before Sunday: add 1-2 focused sessions toward the course with the nearest deadline.';

  @override
  String get aiDetDeficitMediumRecoSecondary =>
      'Pick the course that moves your grades most this week.';

  @override
  String aiDetConsistencyLowInsight(Object percent) {
    return 'Consistency is low ($percent%). Irregular days make every deadline feel tighter.';
  }

  @override
  String get aiDetConsistencyLowRecoPrimary =>
      'Next 5 weekdays: same 30-minute start window (e.g. after lunch).';

  @override
  String get aiDetConsistencyLowRecoSecondary =>
      'Tonight: one 25-minute session to move off your current level.';

  @override
  String aiDetConsistencyMidInsight(Object percent) {
    return 'Consistency is middling ($percent%). You study, but not on a steady rhythm.';
  }

  @override
  String get aiDetConsistencyMidRecoPrimary =>
      'Today: 25-35 minutes right after a habit you already have.';

  @override
  String get aiDetConsistencyMidRecoSecondary =>
      'Tomorrow: repeat at the same clock time.';

  @override
  String aiDetDueSoonManyInsight(Object count) {
    return '$count tasks are due soon - switching between them raises stress.';
  }

  @override
  String get aiDetDueSoonManyRecoPrimary =>
      'Order by deadline: quick wins first, then the hardest task.';

  @override
  String get aiDetDueSoonManyRecoSecondary =>
      'Pause new optional work until these clear.';

  @override
  String get aiDetDueSoonSomeInsight =>
      'You have coursework due soon - finishing ahead beats cramming.';

  @override
  String get aiDetDueSoonSomeRecoPrimary =>
      'Today: block time for the nearest deadline first.';

  @override
  String get aiDetDueSoonSomeRecoSecondary =>
      'If nothing is overdue, pre-read for the next lecture or quiz.';

  @override
  String get aiDetCalendarNoDeadlinesButSemesterInsight =>
      'No deadlines this calendar week, but semester work is still tracked.';

  @override
  String get aiDetCalendarNoDeadlinesButSemesterRecoPrimary =>
      'Use the gap for readings or exam prep.';

  @override
  String get aiDetCalendarNoDeadlinesButSemesterRecoSecondary =>
      'Add dates to undated tasks so planning stays honest.';

  @override
  String get aiDetCalendarNoTasksInsight =>
      'No tasks fall in this calendar-week window - deadlines may be further out.';

  @override
  String get aiDetCalendarNoTasksRecoPrimary =>
      'Advance coursework or shore up weak topics.';

  @override
  String get aiDetCalendarNoTasksRecoSecondary =>
      'Bank extra time before the next busy week.';

  @override
  String get dataPermissionsTitle => 'Data & Permissions';

  @override
  String get contactSupportTitle => 'Contact / Support';

  @override
  String get privacyPolicyIntro =>
      'This policy explains what data Acadia uses and why.';

  @override
  String get privacyPolicyEffectiveDate => 'Effective date: May 2026';

  @override
  String get privacyPolicyCollectedTitle => 'We collect';

  @override
  String get privacyPolicyCollectedAccount =>
      'Account information (name, email)';

  @override
  String get privacyPolicyCollectedAcademic =>
      'Academic data (tasks, exams, study sessions)';

  @override
  String get privacyPolicyCollectedMood =>
      'Mood data only when mood tracking is enabled';

  @override
  String get privacyPolicyUseTitle => 'We use your data to';

  @override
  String get privacyPolicyUseAnalytics =>
      'Provide analytics and progress insights';

  @override
  String get privacyPolicyUseAi => 'Generate AI study suggestions';

  @override
  String get privacyPolicyUseFeatures =>
      'Enable app functionality across your courses and tasks';

  @override
  String get privacyPolicyStorageTitle => 'Storage';

  @override
  String get privacyPolicyStorageSupabase =>
      'Your data is stored securely using Supabase';

  @override
  String get privacyPolicyStorageRetention =>
      'Data is retained while your account is active and used to power your semester history';

  @override
  String get privacyPolicyNotificationsTitle => 'Notifications';

  @override
  String get privacyPolicyNotificationsLocalOnly =>
      'Reminders are local notifications used for study/mood reminders only';

  @override
  String get privacyPolicyControlTitle => 'Your control';

  @override
  String get privacyPolicyControlMood =>
      'You can disable mood tracking at any time';

  @override
  String get privacyPolicyControlDelete =>
      'You can request deletion of your account data through support';

  @override
  String get privacyPolicyNoSell =>
      'We do not sell your data and we do not share it with third parties for advertising.';

  @override
  String get privacyPolicyThirdParty =>
      'Acadia uses trusted infrastructure providers (Supabase, Firebase, and Resend for optional email delivery) only to operate core app features.';

  @override
  String get privacyPolicyAiDisclaimer =>
      'AI-generated insights are suggestions and are not professional advice.';

  @override
  String get termsIntro =>
      'These terms describe your responsibilities and Acadia\'s service boundaries.';

  @override
  String get termsLine1 =>
      'This app is provided for educational and productivity purposes.';

  @override
  String get termsLine2 =>
      'We do not guarantee the accuracy of analytics, reminders, or AI insights.';

  @override
  String get termsLine3 =>
      'You are responsible for the data you enter and the decisions you make using the app.';

  @override
  String get termsLine4 =>
      'Mood tracking is optional and only used within app features.';

  @override
  String get termsLine5 => 'We may update or modify features at any time.';

  @override
  String get termsLine6 => 'By using Acadia, you agree to these terms.';

  @override
  String get dataPermissionsNotificationsTitle => 'Notifications';

  @override
  String get dataPermissionsNotificationsUsage =>
      'Used for study and mood reminder alerts.';

  @override
  String get dataPermissionsNotCollectedTitle => 'We do not collect';

  @override
  String get dataPermissionsNoTracking => 'No device tracking data';

  @override
  String get dataPermissionsNoLocation => 'No location data';

  @override
  String get dataPermissionsNoContacts => 'No contacts data';

  @override
  String get dataPermissionsNoCameraTracking =>
      'No camera recording or background camera access';

  @override
  String get dataPermissionsAvatarNote =>
      'Photo library/camera permission is only requested when you manually change your profile avatar.';

  @override
  String get contactSupportIntro =>
      'For support, feedback, or data requests, contact us at:';

  @override
  String get contactSupportTopics =>
      'Support can help with account access, data requests, notification issues, and incorrect app behavior.';

  @override
  String get legalContactLine => 'Email: support@acadia.app';

  @override
  String get moodTrackingOffBanner => 'Mood tracking is off';

  @override
  String get moodTrackingOffBannerSubtitle =>
      'New mood data will not be collected';

  @override
  String get moodTrackingOffGoToSettings => 'Settings';

  @override
  String get moodTrackingStatusOff => 'Status: Off';

  @override
  String get moodTrackingStatusActive => 'Status: Active';

  @override
  String get moodTrackingNowEnabled => 'Mood tracking enabled';

  @override
  String get moodTrackingNowDisabled => 'Mood tracking disabled';

  @override
  String get moodTrackingHistoricalOnly =>
      'Mood tracking is off. Historical mood insights are still available. Enable tracking to record new mood and stress data.';

  @override
  String get moodTrackingOffSessionSnackbar =>
      'Mood tracking is off. Enable it in Settings to capture session mood.';

  @override
  String get moodTrackingOffBadge => 'Tracking Off';
}
