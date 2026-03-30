import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String helloUser(String name);

  /// No description provided for @academicOverview.
  ///
  /// In en, this message translates to:
  /// **'Your academic overview'**
  String get academicOverview;

  /// No description provided for @academicRisk.
  ///
  /// In en, this message translates to:
  /// **'Academic Risk'**
  String get academicRisk;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRisk;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @tasksToday.
  ///
  /// In en, this message translates to:
  /// **'Tasks Today'**
  String get tasksToday;

  /// No description provided for @tasksPending.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks pending'**
  String tasksPending(int count);

  /// No description provided for @upcomingDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Deadlines'**
  String get upcomingDeadlines;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} this week'**
  String thisWeek(int count);

  /// No description provided for @noDeadlinesWeek.
  ///
  /// In en, this message translates to:
  /// **'No deadlines this week'**
  String get noDeadlinesWeek;

  /// No description provided for @studyTimeToday.
  ///
  /// In en, this message translates to:
  /// **'Study Time Today'**
  String get studyTimeToday;

  /// No description provided for @noStudyLogged.
  ///
  /// In en, this message translates to:
  /// **'No study logged today'**
  String get noStudyLogged;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get theme;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @notificationsCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsCaughtUp;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks, exams or insights'**
  String get searchHint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @deadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadlines'**
  String get deadlines;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitle;

  /// No description provided for @course.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get course;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @estimatedStudyTime.
  ///
  /// In en, this message translates to:
  /// **'Est. Study Time'**
  String get estimatedStudyTime;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @study.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get study;

  /// No description provided for @startStudySession.
  ///
  /// In en, this message translates to:
  /// **'Study Session'**
  String get startStudySession;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @sessionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Session completed'**
  String get sessionCompleted;

  /// No description provided for @recentStudySessions.
  ///
  /// In en, this message translates to:
  /// **'Recent Study Sessions'**
  String get recentStudySessions;

  /// No description provided for @stayOrganized.
  ///
  /// In en, this message translates to:
  /// **'Stay organized'**
  String get stayOrganized;

  /// No description provided for @createFirstTask.
  ///
  /// In en, this message translates to:
  /// **'Create your first task to start tracking your assignments.'**
  String get createFirstTask;

  /// No description provided for @couldNotLoadTasks.
  ///
  /// In en, this message translates to:
  /// **'Could not load tasks.'**
  String get couldNotLoadTasks;

  /// No description provided for @couldNotLoadDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Could not load deadlines.'**
  String get couldNotLoadDeadlines;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String due(String date);

  /// No description provided for @estStudy.
  ///
  /// In en, this message translates to:
  /// **'Est. Study: {time}h'**
  String estStudy(num time);

  /// No description provided for @noDeadlinesYet.
  ///
  /// In en, this message translates to:
  /// **'No deadlines yet'**
  String get noDeadlinesYet;

  /// No description provided for @createFirstDeadline.
  ///
  /// In en, this message translates to:
  /// **'Create your first academic deadline to stay ahead.'**
  String get createFirstDeadline;

  /// No description provided for @createDeadline.
  ///
  /// In en, this message translates to:
  /// **'Create Deadline'**
  String get createDeadline;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String daysRemaining(int count);

  /// No description provided for @exam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get exam;

  /// No description provided for @quiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @assignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignment;

  /// No description provided for @noDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get noDeadline;

  /// No description provided for @newAcademicTask.
  ///
  /// In en, this message translates to:
  /// **'New Academic Task'**
  String get newAcademicTask;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @newAcademicDeadline.
  ///
  /// In en, this message translates to:
  /// **'New Academic Deadline'**
  String get newAcademicDeadline;

  /// No description provided for @pleaseSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get pleaseSelectDate;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @deadlineDate.
  ///
  /// In en, this message translates to:
  /// **'Deadline Date'**
  String get deadlineDate;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @studySession.
  ///
  /// In en, this message translates to:
  /// **'Study Session'**
  String get studySession;

  /// No description provided for @saveSession.
  ///
  /// In en, this message translates to:
  /// **'Save Session'**
  String get saveSession;

  /// No description provided for @noStudySessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No study sessions yet.'**
  String get noStudySessionsYet;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String minutes(int count);

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @pomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get pomodoro;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @deepFocus.
  ///
  /// In en, this message translates to:
  /// **'Deep Focus'**
  String get deepFocus;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @studyHours.
  ///
  /// In en, this message translates to:
  /// **'Study hours'**
  String get studyHours;

  /// No description provided for @taskCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Task completion rate'**
  String get taskCompletionRate;

  /// No description provided for @stressTrends.
  ///
  /// In en, this message translates to:
  /// **'Stress trends'**
  String get stressTrends;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @taskDetail.
  ///
  /// In en, this message translates to:
  /// **'Task Detail'**
  String get taskDetail;

  /// No description provided for @deadlineDetail.
  ///
  /// In en, this message translates to:
  /// **'Deadline Detail'**
  String get deadlineDetail;

  /// No description provided for @taskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found.'**
  String get taskNotFound;

  /// No description provided for @deadlineNotFound.
  ///
  /// In en, this message translates to:
  /// **'Deadline not found.'**
  String get deadlineNotFound;

  /// No description provided for @noDeadlineSet.
  ///
  /// In en, this message translates to:
  /// **'No deadline set'**
  String get noDeadlineSet;

  /// No description provided for @overdueByDays.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {count} days'**
  String overdueByDays(int count);

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {count} days'**
  String dueInDays(int count);

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @editDeadline.
  ///
  /// In en, this message translates to:
  /// **'Edit Deadline'**
  String get editDeadline;

  /// No description provided for @markAsPending.
  ///
  /// In en, this message translates to:
  /// **'Mark as Pending'**
  String get markAsPending;

  /// No description provided for @markAsComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as Complete'**
  String get markAsComplete;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @deleteDeadline.
  ///
  /// In en, this message translates to:
  /// **'Delete Deadline'**
  String get deleteDeadline;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// No description provided for @updateTask.
  ///
  /// In en, this message translates to:
  /// **'Update Task'**
  String get updateTask;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcome;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signup;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get invalidCredentials;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get tooManyRequests;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Try again.'**
  String get networkError;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrong;

  /// No description provided for @passwordFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordFair;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordWeak;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try logging in instead.'**
  String get emailAlreadyInUse;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Request a new one.'**
  String get otpExpired;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyAttempts;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalidOtp;

  /// No description provided for @codeResent.
  ///
  /// In en, this message translates to:
  /// **'Code sent!'**
  String get codeResent;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email'**
  String get enterOtp;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to receive a 6-digit verification code.'**
  String get forgotPasswordPrompt;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @passwordSameAsOld.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from your current password.'**
  String get passwordSameAsOld;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {count} seconds'**
  String resendIn(Object count);

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Master your academic life'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Track your tasks, exams, and study sessions in one intelligent workspace.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of your tasks'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Organize assignments and deadlines so nothing slips through the cracks.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Understand your progress'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Visual insights show your study patterns, productivity, and academic trends.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Balance performance and wellbeing'**
  String get onboardingTitle4;

  /// No description provided for @onboardingDesc4.
  ///
  /// In en, this message translates to:
  /// **'Monitor stress levels and build smarter study habits.'**
  String get onboardingDesc4;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @workloadBalanced.
  ///
  /// In en, this message translates to:
  /// **'Workload Balanced'**
  String get workloadBalanced;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @hoursAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursAbbreviation;

  /// No description provided for @minutesAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesAbbreviation;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated successfully'**
  String get avatarUpdated;

  /// No description provided for @avatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar'**
  String get avatarUploadFailed;

  /// No description provided for @mediumRisk.
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get mediumRisk;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRisk;

  /// No description provided for @riskScore.
  ///
  /// In en, this message translates to:
  /// **'Risk Score'**
  String get riskScore;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @studyLogged.
  ///
  /// In en, this message translates to:
  /// **'Study logged'**
  String get studyLogged;

  /// No description provided for @allTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'All tasks completed!'**
  String get allTasksCompleted;

  /// No description provided for @dontForgetTasks.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to finish them'**
  String get dontForgetTasks;

  /// No description provided for @academicProfileOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Academic Profile'**
  String get academicProfileOnboarding;

  /// No description provided for @basicIdentity.
  ///
  /// In en, this message translates to:
  /// **'Basic Identity'**
  String get basicIdentity;

  /// No description provided for @academicProgram.
  ///
  /// In en, this message translates to:
  /// **'Academic Program'**
  String get academicProgram;

  /// No description provided for @currentSemesterLoad.
  ///
  /// In en, this message translates to:
  /// **'Current Semester Load'**
  String get currentSemesterLoad;

  /// No description provided for @learningPatternCalibration.
  ///
  /// In en, this message translates to:
  /// **'Learning Patterns'**
  String get learningPatternCalibration;

  /// No description provided for @universityName.
  ///
  /// In en, this message translates to:
  /// **'University Name'**
  String get universityName;

  /// No description provided for @degreeType.
  ///
  /// In en, this message translates to:
  /// **'Degree Type'**
  String get degreeType;

  /// No description provided for @major.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get major;

  /// No description provided for @minor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get minor;

  /// No description provided for @academicYear.
  ///
  /// In en, this message translates to:
  /// **'Academic Year'**
  String get academicYear;

  /// No description provided for @expectedGraduationYear.
  ///
  /// In en, this message translates to:
  /// **'Expected Graduation Year'**
  String get expectedGraduationYear;

  /// No description provided for @currentSemesterNumber.
  ///
  /// In en, this message translates to:
  /// **'Current Semester'**
  String get currentSemesterNumber;

  /// No description provided for @coursesThisSemester.
  ///
  /// In en, this message translates to:
  /// **'Expected Courses'**
  String get coursesThisSemester;

  /// No description provided for @studyHoursPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Weekly Study Goal (Hours)'**
  String get studyHoursPerWeek;

  /// No description provided for @preferredStudyTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred Study Time'**
  String get preferredStudyTime;

  /// No description provided for @breakPattern.
  ///
  /// In en, this message translates to:
  /// **'Break Pattern'**
  String get breakPattern;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get night;

  /// No description provided for @deepWork.
  ///
  /// In en, this message translates to:
  /// **'Deep Work'**
  String get deepWork;

  /// No description provided for @mixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get mixed;

  /// No description provided for @bachelor.
  ///
  /// In en, this message translates to:
  /// **'Bachelor'**
  String get bachelor;

  /// No description provided for @master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get master;

  /// No description provided for @phd.
  ///
  /// In en, this message translates to:
  /// **'PhD'**
  String get phd;

  /// No description provided for @addSemester.
  ///
  /// In en, this message translates to:
  /// **'Add Semester'**
  String get addSemester;

  /// No description provided for @editSemester.
  ///
  /// In en, this message translates to:
  /// **'Edit Semester'**
  String get editSemester;

  /// No description provided for @semesterName.
  ///
  /// In en, this message translates to:
  /// **'Semester Name'**
  String get semesterName;

  /// No description provided for @semesterNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fall 2024'**
  String get semesterNameHint;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @createSemester.
  ///
  /// In en, this message translates to:
  /// **'Create Semester'**
  String get createSemester;

  /// No description provided for @updateSemester.
  ///
  /// In en, this message translates to:
  /// **'Update Semester'**
  String get updateSemester;

  /// No description provided for @courseManagement.
  ///
  /// In en, this message translates to:
  /// **'Course Management'**
  String get courseManagement;

  /// No description provided for @myCourses.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get myCourses;

  /// No description provided for @manageSemesters.
  ///
  /// In en, this message translates to:
  /// **'Manage Semesters'**
  String get manageSemesters;

  /// No description provided for @addCourse.
  ///
  /// In en, this message translates to:
  /// **'Add Course'**
  String get addCourse;

  /// No description provided for @editCourse.
  ///
  /// In en, this message translates to:
  /// **'Edit Course'**
  String get editCourse;

  /// No description provided for @courseCode.
  ///
  /// In en, this message translates to:
  /// **'Course Code'**
  String get courseCode;

  /// No description provided for @courseNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Advanced Mathematics'**
  String get courseNameHint;

  /// No description provided for @courseCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CS204'**
  String get courseCodeHint;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @courseColor.
  ///
  /// In en, this message translates to:
  /// **'Course Color'**
  String get courseColor;

  /// No description provided for @creditsLabel.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get creditsLabel;

  /// No description provided for @sortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get sortAlphabetical;

  /// No description provided for @sortStudyTime.
  ///
  /// In en, this message translates to:
  /// **'Study Time'**
  String get sortStudyTime;

  /// No description provided for @semester.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get semester;

  /// No description provided for @selectSemester.
  ///
  /// In en, this message translates to:
  /// **'Select Semester'**
  String get selectSemester;

  /// No description provided for @setAsActive.
  ///
  /// In en, this message translates to:
  /// **'Set as active semester'**
  String get setAsActive;

  /// No description provided for @noCoursesYet.
  ///
  /// In en, this message translates to:
  /// **'No courses added yet'**
  String get noCoursesYet;

  /// No description provided for @addFirstCourse.
  ///
  /// In en, this message translates to:
  /// **'Add your first course to start tracking.'**
  String get addFirstCourse;

  /// No description provided for @addFirstCourseBtn.
  ///
  /// In en, this message translates to:
  /// **'Add My First Course'**
  String get addFirstCourseBtn;

  /// No description provided for @deleteCourse.
  ///
  /// In en, this message translates to:
  /// **'Delete Course?'**
  String get deleteCourse;

  /// No description provided for @deleteCourseWarning.
  ///
  /// In en, this message translates to:
  /// **'This will also disconnect this course from all linked tasks and sessions.'**
  String get deleteCourseWarning;

  /// No description provided for @addCourseFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a course first'**
  String get addCourseFirst;

  /// No description provided for @selectCourse.
  ///
  /// In en, this message translates to:
  /// **'Select Course'**
  String get selectCourse;

  /// No description provided for @pleaseSelectCourse.
  ///
  /// In en, this message translates to:
  /// **'Please select a course'**
  String get pleaseSelectCourse;

  /// No description provided for @errorLoadingCourses.
  ///
  /// In en, this message translates to:
  /// **'Error loading courses'**
  String get errorLoadingCourses;

  /// No description provided for @academicInformation.
  ///
  /// In en, this message translates to:
  /// **'Academic Information'**
  String get academicInformation;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @manageCourses.
  ///
  /// In en, this message translates to:
  /// **'Manage Courses'**
  String get manageCourses;

  /// No description provided for @manageCoursesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add or edit your current courses'**
  String get manageCoursesSubtitle;

  /// No description provided for @yearCount.
  ///
  /// In en, this message translates to:
  /// **'Year {count}'**
  String yearCount(int count);

  /// No description provided for @studyGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly Study Goal'**
  String get studyGoal;

  /// No description provided for @studyGoalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed: {time}'**
  String studyGoalCompleted(String time);

  /// No description provided for @studyGoalRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {time}'**
  String studyGoalRemaining(String time);

  /// No description provided for @sessionReflectionTitle.
  ///
  /// In en, this message translates to:
  /// **'How was this session?'**
  String get sessionReflectionTitle;

  /// No description provided for @focused.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get focused;

  /// No description provided for @distracted.
  ///
  /// In en, this message translates to:
  /// **'Distracted'**
  String get distracted;

  /// No description provided for @veryProductive.
  ///
  /// In en, this message translates to:
  /// **'Very Productive'**
  String get veryProductive;

  /// No description provided for @sessionNotes.
  ///
  /// In en, this message translates to:
  /// **'Session Notes'**
  String get sessionNotes;

  /// No description provided for @identityDesc.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start with who you are and where you study.'**
  String get identityDesc;

  /// No description provided for @programDesc.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your field of study.'**
  String get programDesc;

  /// No description provided for @loadDesc.
  ///
  /// In en, this message translates to:
  /// **'Help us calibrate your expected workload.'**
  String get loadDesc;

  /// No description provided for @learningPatternDesc.
  ///
  /// In en, this message translates to:
  /// **'When and how do you learn best?'**
  String get learningPatternDesc;

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Hours'**
  String hoursCount(int count);

  /// No description provided for @recommendedFocus.
  ///
  /// In en, this message translates to:
  /// **'Recommended Focus'**
  String get recommendedFocus;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @studyPreferences.
  ///
  /// In en, this message translates to:
  /// **'Study Preferences'**
  String get studyPreferences;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @dataExport.
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExport;

  /// No description provided for @reminderSettings.
  ///
  /// In en, this message translates to:
  /// **'Reminder Settings'**
  String get reminderSettings;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications Enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationsDisabled;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccess;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @studyTimerDefaults.
  ///
  /// In en, this message translates to:
  /// **'Study Timer Defaults'**
  String get studyTimerDefaults;

  /// No description provided for @focusOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus on {title} - due soon!'**
  String focusOnTitle(String title);

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up! Maybe start a deep work session?'**
  String get allCaughtUp;

  /// No description provided for @bestStudyTime.
  ///
  /// In en, this message translates to:
  /// **'You study best in the {time}. Keep your first session then!'**
  String bestStudyTime(String time);

  /// No description provided for @discoverPattern.
  ///
  /// In en, this message translates to:
  /// **'Start a session to discover your productivity pattern.'**
  String get discoverPattern;

  /// No description provided for @startNewSession.
  ///
  /// In en, this message translates to:
  /// **'Start New Session'**
  String get startNewSession;

  /// No description provided for @sessionType.
  ///
  /// In en, this message translates to:
  /// **'Session Type'**
  String get sessionType;

  /// No description provided for @galleryPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Gallery Permission Required'**
  String get galleryPermissionRequired;

  /// No description provided for @galleryPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Please allow gallery access in settings to change your profile picture.'**
  String get galleryPermissionMessage;

  /// No description provided for @chooseACourse.
  ///
  /// In en, this message translates to:
  /// **'Choose a course'**
  String get chooseACourse;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get notEnoughData;

  /// No description provided for @addCoursesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add your courses to start tracking progress.'**
  String get addCoursesPrompt;

  /// No description provided for @noUpcomingDeadlines.
  ///
  /// In en, this message translates to:
  /// **'No upcoming deadlines'**
  String get noUpcomingDeadlines;

  /// No description provided for @caughtUp.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up!'**
  String get caughtUp;

  /// No description provided for @youStudiedFor.
  ///
  /// In en, this message translates to:
  /// **'You studied for {time}.'**
  String youStudiedFor(String time);

  /// No description provided for @efficiencyTip.
  ///
  /// In en, this message translates to:
  /// **'Efficiency Tip'**
  String get efficiencyTip;

  /// No description provided for @discoveryStudyPatterns.
  ///
  /// In en, this message translates to:
  /// **'Discover your best study patterns by logging more sessions.'**
  String get discoveryStudyPatterns;

  /// No description provided for @goalCompletionLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal Completion: {percentage}%'**
  String goalCompletionLabel(int percentage);

  /// No description provided for @keepGoingLeft.
  ///
  /// In en, this message translates to:
  /// **'Keep going! You have {time} left.'**
  String keepGoingLeft(String time);

  /// No description provided for @greatFocusSession.
  ///
  /// In en, this message translates to:
  /// **'Great focus session!'**
  String get greatFocusSession;

  /// No description provided for @focusLevel.
  ///
  /// In en, this message translates to:
  /// **'Focus Level'**
  String get focusLevel;

  /// No description provided for @deepFlow.
  ///
  /// In en, this message translates to:
  /// **'Deep Flow'**
  String get deepFlow;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @studyHoursByCourse.
  ///
  /// In en, this message translates to:
  /// **'Study Hours by Course'**
  String get studyHoursByCourse;

  /// No description provided for @weeklyTaskCompletion.
  ///
  /// In en, this message translates to:
  /// **'Weekly Task Completion'**
  String get weeklyTaskCompletion;

  /// No description provided for @dailyInsight.
  ///
  /// In en, this message translates to:
  /// **'Daily Insight'**
  String get dailyInsight;

  /// No description provided for @focusOnStudies.
  ///
  /// In en, this message translates to:
  /// **'Focus on your studies today.'**
  String get focusOnStudies;

  /// No description provided for @thisWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekLabel;

  /// No description provided for @noCourseSelected.
  ///
  /// In en, this message translates to:
  /// **'No Course Selected'**
  String get noCourseSelected;

  /// No description provided for @lastUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String lastUpdatedAt(String time);

  /// No description provided for @noPendingAlerts.
  ///
  /// In en, this message translates to:
  /// **'No pending alerts.'**
  String get noPendingAlerts;

  /// No description provided for @overdueTasksSummary.
  ///
  /// In en, this message translates to:
  /// **'There are {count} overdue tasks.'**
  String overdueTasksSummary(int count);

  /// No description provided for @deadlinesSoonSummary.
  ///
  /// In en, this message translates to:
  /// **'There are {count} deadlines within the next 3 days.'**
  String deadlinesSoonSummary(int count);

  /// No description provided for @allTasksUpToDate.
  ///
  /// In en, this message translates to:
  /// **'All current tasks are up-to-date.'**
  String get allTasksUpToDate;

  /// No description provided for @ectsLabel.
  ///
  /// In en, this message translates to:
  /// **'ECTS'**
  String get ectsLabel;

  /// No description provided for @sessionFocus.
  ///
  /// In en, this message translates to:
  /// **'Session Focus'**
  String get sessionFocus;

  /// No description provided for @academicLoad.
  ///
  /// In en, this message translates to:
  /// **'Academic Load'**
  String get academicLoad;

  /// No description provided for @studyDemand.
  ///
  /// In en, this message translates to:
  /// **'Study Demand'**
  String get studyDemand;

  /// No description provided for @workloadIntensity.
  ///
  /// In en, this message translates to:
  /// **'Workload Intensity'**
  String get workloadIntensity;

  /// No description provided for @totalEctsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total ECTS'**
  String get totalEctsLabel;

  /// No description provided for @overloaded.
  ///
  /// In en, this message translates to:
  /// **'Overloaded'**
  String get overloaded;

  /// No description provided for @highLoad.
  ///
  /// In en, this message translates to:
  /// **'High Load'**
  String get highLoad;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// No description provided for @lowLoad.
  ///
  /// In en, this message translates to:
  /// **'Low Load'**
  String get lowLoad;

  /// No description provided for @riskLow.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get riskLow;

  /// No description provided for @riskMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get riskMedium;

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get riskHigh;

  /// No description provided for @riskBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk Breakdown'**
  String get riskBreakdownTitle;

  /// No description provided for @riskOverdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue tasks'**
  String get riskOverdueTasks;

  /// No description provided for @riskUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks due soon'**
  String get riskUpcomingTasks;

  /// No description provided for @riskStudyDeficit.
  ///
  /// In en, this message translates to:
  /// **'Study deficit'**
  String get riskStudyDeficit;

  /// No description provided for @riskStatusMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue {count, plural, =1{task} other{tasks}}'**
  String riskStatusMessage(int count);

  /// No description provided for @riskInterpretationOnTrack.
  ///
  /// In en, this message translates to:
  /// **'You are on track. Keep your current study pace.'**
  String get riskInterpretationOnTrack;

  /// No description provided for @riskInterpretationHigh.
  ///
  /// In en, this message translates to:
  /// **'You are at high risk due to missed deadlines and insufficient study hours.'**
  String get riskInterpretationHigh;

  /// No description provided for @riskInterpretationMedium.
  ///
  /// In en, this message translates to:
  /// **'Your risk is moderate; keep an eye on upcoming tasks and study goals.'**
  String get riskInterpretationMedium;

  /// No description provided for @riskInterpretationLow.
  ///
  /// In en, this message translates to:
  /// **'You are in a safe range. Maintain your current progress.'**
  String get riskInterpretationLow;

  /// No description provided for @riskHoursRemaining.
  ///
  /// In en, this message translates to:
  /// **'{hours}h remaining'**
  String riskHoursRemaining(Object hours);

  /// No description provided for @riskGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get riskGoalReached;

  /// No description provided for @riskReasonOverdue.
  ///
  /// In en, this message translates to:
  /// **'You have {count} overdue tasks'**
  String riskReasonOverdue(int count);

  /// No description provided for @riskReasonStudyLow.
  ///
  /// In en, this message translates to:
  /// **'You studied less than your weekly goal'**
  String get riskReasonStudyLow;

  /// No description provided for @riskReasonUpcoming.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks due soon'**
  String riskReasonUpcoming(int count);

  /// No description provided for @riskTrendUp.
  ///
  /// In en, this message translates to:
  /// **'+{delta} risk increase'**
  String riskTrendUp(int delta);

  /// No description provided for @riskTrendDown.
  ///
  /// In en, this message translates to:
  /// **'-{delta} (improved)'**
  String riskTrendDown(int delta);

  /// No description provided for @riskTrendStable.
  ///
  /// In en, this message translates to:
  /// **'+0 (no change)'**
  String get riskTrendStable;

  /// No description provided for @riskNoData.
  ///
  /// In en, this message translates to:
  /// **'No active risk factors'**
  String get riskNoData;

  /// No description provided for @overviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTitle;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String lastUpdated(String time);

  /// No description provided for @overviewOverdueTasksAction.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks need attention'**
  String overviewOverdueTasksAction(int count);

  /// No description provided for @overviewUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'{count} upcoming deadlines'**
  String overviewUpcomingTasks(int count);

  /// No description provided for @overviewNoUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'No upcoming deadlines'**
  String get overviewNoUpcomingTasks;

  /// No description provided for @overviewCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks completed today'**
  String overviewCompletedToday(int count);

  /// No description provided for @overviewNoCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks completed today'**
  String get overviewNoCompletedToday;

  /// No description provided for @taskCompletion.
  ///
  /// In en, this message translates to:
  /// **'Task Completion'**
  String get taskCompletion;

  /// No description provided for @tasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} tasks completed'**
  String tasksCompleted(int completed, int total);

  /// No description provided for @tasksCompletedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Tasks due this week: {completed} of {total} completed'**
  String tasksCompletedThisWeek(int completed, int total);

  /// No description provided for @noStudyDataThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No study sessions this week'**
  String get noStudyDataThisWeek;

  /// No description provided for @noTasksThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No tasks scheduled this week'**
  String get noTasksThisWeek;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
