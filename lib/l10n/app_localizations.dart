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

  /// No description provided for @noTasksForThisCourse.
  ///
  /// In en, this message translates to:
  /// **'No tasks for this course'**
  String get noTasksForThisCourse;

  /// No description provided for @noDeadlinesForThisCourse.
  ///
  /// In en, this message translates to:
  /// **'No deadlines for this course'**
  String get noDeadlinesForThisCourse;

  /// No description provided for @noSessionsForThisCourse.
  ///
  /// In en, this message translates to:
  /// **'No sessions for this course'**
  String get noSessionsForThisCourse;

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

  /// No description provided for @quickMenu.
  ///
  /// In en, this message translates to:
  /// **'Quick Menu'**
  String get quickMenu;

  /// No description provided for @deadlineKindBadge.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadlineKindBadge;

  /// No description provided for @linkToAcademicDeadline.
  ///
  /// In en, this message translates to:
  /// **'Link to deadline (optional)'**
  String get linkToAcademicDeadline;

  /// No description provided for @noneLinkedDeadline.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneLinkedDeadline;

  /// No description provided for @relatedTasksSection.
  ///
  /// In en, this message translates to:
  /// **'Related tasks'**
  String get relatedTasksSection;

  /// No description provided for @addTaskToThisDeadline.
  ///
  /// In en, this message translates to:
  /// **'Add task to this deadline'**
  String get addTaskToThisDeadline;

  /// No description provided for @deadlineLinkedTasksProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} tasks completed'**
  String deadlineLinkedTasksProgress(int completed, int total);

  /// No description provided for @deadlineNoLinkedTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks linked to this deadline yet.'**
  String get deadlineNoLinkedTasks;

  /// No description provided for @taskLinkedToDeadline.
  ///
  /// In en, this message translates to:
  /// **'Linked to a deadline'**
  String get taskLinkedToDeadline;

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

  /// No description provided for @liveStudySessions.
  ///
  /// In en, this message translates to:
  /// **'Live Study Sessions'**
  String get liveStudySessions;

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

  /// No description provided for @focusLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusLabel;

  /// No description provided for @breakLabel.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakLabel;

  /// No description provided for @reviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @stopSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop Session'**
  String get stopSessionTitle;

  /// No description provided for @stopSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end this study session?'**
  String get stopSessionConfirm;

  /// No description provided for @sessionPaused.
  ///
  /// In en, this message translates to:
  /// **'Session paused. Take a breath.'**
  String get sessionPaused;

  /// No description provided for @refreshYourself.
  ///
  /// In en, this message translates to:
  /// **'Refresh yourself. You\'re doing great.'**
  String get refreshYourself;

  /// No description provided for @stayFocused.
  ///
  /// In en, this message translates to:
  /// **'Stay focused. You\'re doing well.'**
  String get stayFocused;

  /// No description provided for @deepWorkInProgress.
  ///
  /// In en, this message translates to:
  /// **'Deep work in progress...'**
  String get deepWorkInProgress;

  /// No description provided for @dontStopNow.
  ///
  /// In en, this message translates to:
  /// **'Don\'t stop now, you\'re on a roll!'**
  String get dontStopNow;

  /// No description provided for @focusOnProcess.
  ///
  /// In en, this message translates to:
  /// **'Focus on the process, not the results.'**
  String get focusOnProcess;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Keep pushing.'**
  String get almostThere;

  /// No description provided for @futureSelf.
  ///
  /// In en, this message translates to:
  /// **'Your future self will thank you.'**
  String get futureSelf;

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
  /// **'Deep focus'**
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

  /// No description provided for @academicReport.
  ///
  /// In en, this message translates to:
  /// **'Academic Report'**
  String get academicReport;

  /// No description provided for @academicHistory.
  ///
  /// In en, this message translates to:
  /// **'Academic History'**
  String get academicHistory;

  /// No description provided for @requiresFocus.
  ///
  /// In en, this message translates to:
  /// **'Requires focus'**
  String get requiresFocus;

  /// No description provided for @gradeAverage.
  ///
  /// In en, this message translates to:
  /// **'Grade average'**
  String get gradeAverage;

  /// No description provided for @semesterTrend.
  ///
  /// In en, this message translates to:
  /// **'Semester Trend'**
  String get semesterTrend;

  /// No description provided for @noAcademicHistory.
  ///
  /// In en, this message translates to:
  /// **'No academic history yet'**
  String get noAcademicHistory;

  /// No description provided for @startLoggingContext.
  ///
  /// In en, this message translates to:
  /// **'Log study sessions and complete tasks to build your historical profile.'**
  String get startLoggingContext;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @switchToSemester.
  ///
  /// In en, this message translates to:
  /// **'Switch to this Semester'**
  String get switchToSemester;

  /// No description provided for @setUpSemester.
  ///
  /// In en, this message translates to:
  /// **'Set up Semester'**
  String get setUpSemester;

  /// No description provided for @startAcademicTracking.
  ///
  /// In en, this message translates to:
  /// **'Start academic tracking'**
  String get startAcademicTracking;

  /// No description provided for @gpaPoints.
  ///
  /// In en, this message translates to:
  /// **'GPA Points'**
  String get gpaPoints;

  /// No description provided for @studyTimeDeltaMsg.
  ///
  /// In en, this message translates to:
  /// **'Your weekly study time has {action} by {percent}%'**
  String studyTimeDeltaMsg(String action, int percent);

  /// No description provided for @riskIncreased.
  ///
  /// In en, this message translates to:
  /// **'Risk increased by {value}%'**
  String riskIncreased(int value);

  /// No description provided for @riskDecreased.
  ///
  /// In en, this message translates to:
  /// **'Risk decreased by {value}%'**
  String riskDecreased(int value);

  /// No description provided for @increased.
  ///
  /// In en, this message translates to:
  /// **'increased'**
  String get increased;

  /// No description provided for @decreased.
  ///
  /// In en, this message translates to:
  /// **'decreased'**
  String get decreased;

  /// No description provided for @taskCompletionImproved.
  ///
  /// In en, this message translates to:
  /// **'You are completing more tasks than last semester'**
  String get taskCompletionImproved;

  /// No description provided for @taskCompletionDecreased.
  ///
  /// In en, this message translates to:
  /// **'Your task completion rate has dropped'**
  String get taskCompletionDecreased;

  /// No description provided for @academicRiskIncreased.
  ///
  /// In en, this message translates to:
  /// **'Your academic risk has increased'**
  String get academicRiskIncreased;

  /// No description provided for @academicPerformanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Performance Summary'**
  String get academicPerformanceSummary;

  /// No description provided for @performanceSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Long-term academic trends across all semesters'**
  String get performanceSummarySubtitle;

  /// No description provided for @bestSemester.
  ///
  /// In en, this message translates to:
  /// **'Best Semester'**
  String get bestSemester;

  /// No description provided for @worstSemester.
  ///
  /// In en, this message translates to:
  /// **'Worst Semester'**
  String get worstSemester;

  /// No description provided for @mostImproved.
  ///
  /// In en, this message translates to:
  /// **'Most Improved'**
  String get mostImproved;

  /// No description provided for @highestGPA.
  ///
  /// In en, this message translates to:
  /// **'Highest GPA'**
  String get highestGPA;

  /// No description provided for @startStudySessionCTA.
  ///
  /// In en, this message translates to:
  /// **'Start a study session'**
  String get startStudySessionCTA;

  /// No description provided for @addFirstTaskCTA.
  ///
  /// In en, this message translates to:
  /// **'Add your first task'**
  String get addFirstTaskCTA;

  /// No description provided for @startStudyingHint.
  ///
  /// In en, this message translates to:
  /// **'Start studying to see activity here'**
  String get startStudyingHint;

  /// No description provided for @viewHistoryMode.
  ///
  /// In en, this message translates to:
  /// **'Viewing History'**
  String get viewHistoryMode;

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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Acadia'**
  String get appName;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to your studies'**
  String get welcomeSubtitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to start managing your studies'**
  String get signupSubtitle;

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

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @googleLabel.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get googleLabel;

  /// No description provided for @appleLabel.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get appleLabel;

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
  /// **'Too many attempts. Email service is temporarily limited. Please wait a few minutes before trying again.'**
  String get tooManyRequests;

  /// No description provided for @emailRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Email service is temporarily limited. Please wait a few minutes.'**
  String get emailRateLimit;

  /// No description provided for @emailRateLimitWithTimer.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Email service is temporarily limited. Try again in {time}.'**
  String emailRateLimitWithTimer(String time);

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment before trying again.'**
  String get pleaseWait;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Try again.'**
  String get networkError;

  /// No description provided for @checkInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection.'**
  String get checkInternetConnection;

  /// No description provided for @requestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Try again.'**
  String get requestTimedOut;

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
  /// **'Please wait a moment before trying again.'**
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

  /// No description provided for @tryAgainIn.
  ///
  /// In en, this message translates to:
  /// **'Try again in {count}s'**
  String tryAgainIn(Object count);

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

  /// No description provided for @riskLevelCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get riskLevelCritical;

  /// No description provided for @riskLevelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get riskLevelWarning;

  /// No description provided for @riskLevelSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get riskLevelSafe;

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

  /// No description provided for @academicAnalyticsContext.
  ///
  /// In en, this message translates to:
  /// **'This information helps personalize your academic analytics and recommendations.'**
  String get academicAnalyticsContext;

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
  /// **'Current Semester'**
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

  /// No description provided for @currentSemesterHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your current semester number.'**
  String get currentSemesterHint;

  /// No description provided for @semesterTrackingSetup.
  ///
  /// In en, this message translates to:
  /// **'Semester Tracking Setup'**
  String get semesterTrackingSetup;

  /// No description provided for @optionalPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional Preferences'**
  String get optionalPreferencesTitle;

  /// No description provided for @optionalPreferencesDesc.
  ///
  /// In en, this message translates to:
  /// **'You can adjust these anytime in Study Preferences.'**
  String get optionalPreferencesDesc;

  /// No description provided for @graduationYearHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your expected graduation year (this year or later).'**
  String get graduationYearHint;

  /// No description provided for @graduationYearInvalid.
  ///
  /// In en, this message translates to:
  /// **'Graduation year must be this year or later.'**
  String get graduationYearInvalid;

  /// No description provided for @graduationYearSemesterMismatch.
  ///
  /// In en, this message translates to:
  /// **''**
  String get graduationYearSemesterMismatch;

  /// No description provided for @semesterNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Semester number must be at least 1.'**
  String get semesterNumberInvalid;

  /// No description provided for @weeklyStudyGoalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Weekly study goal must be between 5 and 40 hours.'**
  String get weeklyStudyGoalInvalid;

  /// No description provided for @onboardingRiskImpactHint.
  ///
  /// In en, this message translates to:
  /// **'Your semester and study goal are used to calculate academic risk and progress insights.'**
  String get onboardingRiskImpactHint;

  /// No description provided for @studyGoalRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommended: 10-25 hours per week'**
  String get studyGoalRecommendation;

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

  /// No description provided for @allSemesters.
  ///
  /// In en, this message translates to:
  /// **'All Semesters'**
  String get allSemesters;

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

  /// No description provided for @courseTitle.
  ///
  /// In en, this message translates to:
  /// **'Course Title'**
  String get courseTitle;

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

  /// No description provided for @academicSemester.
  ///
  /// In en, this message translates to:
  /// **'Academic Semester'**
  String get academicSemester;

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

  /// No description provided for @semesterSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get semesterSeason;

  /// No description provided for @fallSemester.
  ///
  /// In en, this message translates to:
  /// **'Fall'**
  String get fallSemester;

  /// No description provided for @springSemester.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get springSemester;

  /// No description provided for @academicYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Academic Year'**
  String get academicYearLabel;

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

  /// No description provided for @currentSemesterLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentSemesterLabel;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @noSemestersYet.
  ///
  /// In en, this message translates to:
  /// **'No semesters created yet'**
  String get noSemestersYet;

  /// No description provided for @createFirstSemester.
  ///
  /// In en, this message translates to:
  /// **'Create your first semester to organize your courses.'**
  String get createFirstSemester;

  /// No description provided for @deleteSemesterWarning.
  ///
  /// In en, this message translates to:
  /// **'This semester will be removed from your semester list.'**
  String get deleteSemesterWarning;

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

  /// No description provided for @ectsRequired.
  ///
  /// In en, this message translates to:
  /// **'ECTS is required'**
  String get ectsRequired;

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
  /// **'Start tracking to see trends'**
  String get notEnoughData;

  /// No description provided for @addCoursesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add your courses to start tracking progress.'**
  String get addCoursesPrompt;

  /// No description provided for @noUpcomingDeadlines.
  ///
  /// In en, this message translates to:
  /// **'No deadlines due soon'**
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

  /// No description provided for @riskSessionStress.
  ///
  /// In en, this message translates to:
  /// **'Session stress'**
  String get riskSessionStress;

  /// No description provided for @riskConsistencyImpact.
  ///
  /// In en, this message translates to:
  /// **'Consistency impact'**
  String get riskConsistencyImpact;

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
  /// **'Your risk is moderate. Focus on completing tasks and increasing study time.'**
  String get riskInterpretationMedium;

  /// No description provided for @riskInterpretationLow.
  ///
  /// In en, this message translates to:
  /// **'You are in a safe range. Keep your current progress.'**
  String get riskInterpretationLow;

  /// No description provided for @riskInterpretationStudyDeficit.
  ///
  /// In en, this message translates to:
  /// **'Increase study time immediately'**
  String get riskInterpretationStudyDeficit;

  /// No description provided for @studyDeficitTitle.
  ///
  /// In en, this message translates to:
  /// **'High Study Deficit'**
  String get studyDeficitTitle;

  /// No description provided for @studyDeficitBody.
  ///
  /// In en, this message translates to:
  /// **'Increase study time immediately to stay on track.'**
  String get studyDeficitBody;

  /// No description provided for @decisionHighSessionStressTitle.
  ///
  /// In en, this message translates to:
  /// **'High Study Stress'**
  String get decisionHighSessionStressTitle;

  /// No description provided for @decisionHighSessionStressBody.
  ///
  /// In en, this message translates to:
  /// **'Reduce session length to 30-40 min to prevent burnout.'**
  String get decisionHighSessionStressBody;

  /// No description provided for @decisionLowConsistencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Build Study Consistency'**
  String get decisionLowConsistencyTitle;

  /// No description provided for @decisionLowConsistencyBody.
  ///
  /// In en, this message translates to:
  /// **'Fix your schedule before increasing workload.'**
  String get decisionLowConsistencyBody;

  /// No description provided for @burnoutExplanationNew.
  ///
  /// In en, this message translates to:
  /// **'Burnout risk is driven by sustained high stress and severe study deficit.'**
  String get burnoutExplanationNew;

  /// No description provided for @startTrackingToSeeTrends.
  ///
  /// In en, this message translates to:
  /// **'Start tracking to see trends'**
  String get startTrackingToSeeTrends;

  /// No description provided for @noGpaDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No GPA data available'**
  String get noGpaDataAvailable;

  /// No description provided for @riskInterpretationFocusTasks.
  ///
  /// In en, this message translates to:
  /// **'Focus on completing tasks'**
  String get riskInterpretationFocusTasks;

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

  /// No description provided for @historicalConsistency.
  ///
  /// In en, this message translates to:
  /// **'Historical consistency'**
  String get historicalConsistency;

  /// No description provided for @historicalConsistencyScoreLine.
  ///
  /// In en, this message translates to:
  /// **'Historical consistency: {score}% ({trend})'**
  String historicalConsistencyScoreLine(Object score, Object trend);

  /// No description provided for @weeklyConsistency.
  ///
  /// In en, this message translates to:
  /// **'This week consistency'**
  String get weeklyConsistency;

  /// No description provided for @decisionHighStressOverrideTitle.
  ///
  /// In en, this message translates to:
  /// **'Reduce workload'**
  String get decisionHighStressOverrideTitle;

  /// No description provided for @decisionHighStressOverrideBody.
  ///
  /// In en, this message translates to:
  /// **'Focus on shorter sessions to prevent burnout.'**
  String get decisionHighStressOverrideBody;

  /// No description provided for @riskExplanationLowStudyHighStress.
  ///
  /// In en, this message translates to:
  /// **'High Risk due to low study activity and high stress'**
  String get riskExplanationLowStudyHighStress;

  /// No description provided for @riskExplanationDeficitOnly.
  ///
  /// In en, this message translates to:
  /// **'High Risk due to severe study deficit'**
  String get riskExplanationDeficitOnly;

  /// No description provided for @riskExplanationStressOnly.
  ///
  /// In en, this message translates to:
  /// **'High Risk due to critical stress levels'**
  String get riskExplanationStressOnly;

  /// No description provided for @riskExplanationGeneric.
  ///
  /// In en, this message translates to:
  /// **'High Risk due to combined academic signals'**
  String get riskExplanationGeneric;

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
  /// **'Increased by {delta} points from last week'**
  String riskTrendUp(int delta);

  /// No description provided for @riskTrendDown.
  ///
  /// In en, this message translates to:
  /// **'Improved by {delta} points from last week'**
  String riskTrendDown(int delta);

  /// No description provided for @riskTrendStable.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get riskTrendStable;

  /// No description provided for @riskTrendNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get riskTrendNew;

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
  /// **'No deadlines due soon'**
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

  /// No description provided for @examResults.
  ///
  /// In en, this message translates to:
  /// **'Course Results'**
  String get examResults;

  /// No description provided for @addResult.
  ///
  /// In en, this message translates to:
  /// **'Add Result'**
  String get addResult;

  /// No description provided for @editResult.
  ///
  /// In en, this message translates to:
  /// **'Edit Result'**
  String get editResult;

  /// No description provided for @noResultsYet.
  ///
  /// In en, this message translates to:
  /// **'No results added yet'**
  String get noResultsYet;

  /// No description provided for @addFirstResultPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add your first course result for this semester.'**
  String get addFirstResultPrompt;

  /// No description provided for @gradingComponents.
  ///
  /// In en, this message translates to:
  /// **'Grading Components'**
  String get gradingComponents;

  /// No description provided for @addComponent.
  ///
  /// In en, this message translates to:
  /// **'+ Add Component'**
  String get addComponent;

  /// No description provided for @finalSection.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get finalSection;

  /// No description provided for @finalAverage.
  ///
  /// In en, this message translates to:
  /// **'Final Average'**
  String get finalAverage;

  /// No description provided for @letterGrade.
  ///
  /// In en, this message translates to:
  /// **'Letter Grade'**
  String get letterGrade;

  /// No description provided for @resultStatus.
  ///
  /// In en, this message translates to:
  /// **'Course Status'**
  String get resultStatus;

  /// No description provided for @resultSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get resultSuccessful;

  /// No description provided for @resultFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get resultFailed;

  /// No description provided for @component.
  ///
  /// In en, this message translates to:
  /// **'Component'**
  String get component;

  /// No description provided for @componentTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get componentTitle;

  /// No description provided for @componentTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Midterm, Project, Final, Quiz'**
  String get componentTitleHint;

  /// No description provided for @scoreHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 85'**
  String get scoreHint;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @percentageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 40'**
  String get percentageHint;

  /// No description provided for @finalAverageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 78.5'**
  String get finalAverageHint;

  /// No description provided for @numberRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get numberRequired;

  /// No description provided for @completeComponentsError.
  ///
  /// In en, this message translates to:
  /// **'Complete all components before saving'**
  String get completeComponentsError;

  /// No description provided for @percentageNot100Warning.
  ///
  /// In en, this message translates to:
  /// **'Warning: total percentage is not 100'**
  String get percentageNot100Warning;

  /// No description provided for @gradeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Grade Distribution'**
  String get gradeDistribution;

  /// No description provided for @noGradeDistributionYet.
  ///
  /// In en, this message translates to:
  /// **'No grade distribution data yet'**
  String get noGradeDistributionYet;

  /// No description provided for @pleaseSelectLetterGrade.
  ///
  /// In en, this message translates to:
  /// **'Please select a letter grade'**
  String get pleaseSelectLetterGrade;

  /// No description provided for @noCoursesForSemester.
  ///
  /// In en, this message translates to:
  /// **'No courses found for this semester'**
  String get noCoursesForSemester;

  /// No description provided for @semesterAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This semester already exists'**
  String get semesterAlreadyExists;

  /// No description provided for @semesterStartBeforeEndError.
  ///
  /// In en, this message translates to:
  /// **'Start date must be before end date'**
  String get semesterStartBeforeEndError;

  /// No description provided for @gradeRangeError.
  ///
  /// In en, this message translates to:
  /// **'Value must be between 0 and 100'**
  String get gradeRangeError;

  /// No description provided for @trendAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Trend Analysis'**
  String get trendAnalysis;

  /// No description provided for @studyTrend.
  ///
  /// In en, this message translates to:
  /// **'Study Trend'**
  String get studyTrend;

  /// No description provided for @taskCompletionTrend.
  ///
  /// In en, this message translates to:
  /// **'Task Completion Trend'**
  String get taskCompletionTrend;

  /// No description provided for @workloadTrend.
  ///
  /// In en, this message translates to:
  /// **'Workload Trend'**
  String get workloadTrend;

  /// No description provided for @performanceTrend.
  ///
  /// In en, this message translates to:
  /// **'Performance Trend'**
  String get performanceTrend;

  /// No description provided for @daysFilter.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysFilter(int count);

  /// No description provided for @trendTodayDuration.
  ///
  /// In en, this message translates to:
  /// **'{duration} today'**
  String trendTodayDuration(String duration);

  /// No description provided for @trendCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'{count} completed today'**
  String trendCompletedToday(int count);

  /// No description provided for @trendNewToday.
  ///
  /// In en, this message translates to:
  /// **'{count} new today'**
  String trendNewToday(int count);

  /// No description provided for @trendStudySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hours studied per day over the selected period'**
  String get trendStudySubtitle;

  /// No description provided for @trendTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks per day over the selected period'**
  String get trendTaskSubtitle;

  /// No description provided for @trendWorkloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks and deadlines added per day'**
  String get trendWorkloadSubtitle;

  /// No description provided for @trendPerformanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'GPA change based on course results'**
  String get trendPerformanceSubtitle;

  /// No description provided for @trendTasksOneDayHint.
  ///
  /// In en, this message translates to:
  /// **'Most tasks were completed on one day.'**
  String get trendTasksOneDayHint;

  /// No description provided for @trendWorkloadEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No data yet.\nAdd tasks or deadlines to see workload trends.'**
  String get trendWorkloadEmptyMessage;

  /// No description provided for @trendStudyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No data yet.\nStart logging study sessions to see trends.'**
  String get trendStudyEmptyMessage;

  /// No description provided for @trendTaskEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks in this period.\nComplete tasks to track progress.'**
  String get trendTaskEmptyMessage;

  /// No description provided for @trendPerformanceEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add course results to track performance.'**
  String get trendPerformanceEmptyMessage;

  /// No description provided for @trendPerformanceNeedThreeResults.
  ///
  /// In en, this message translates to:
  /// **'Add at least 3 course results to see performance trends.'**
  String get trendPerformanceNeedThreeResults;

  /// No description provided for @trendSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Trend Summary'**
  String get trendSummaryTitle;

  /// No description provided for @trendOverallStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Overall Status'**
  String get trendOverallStatusTitle;

  /// No description provided for @trendNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data'**
  String get trendNotEnoughData;

  /// No description provided for @trendStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get trendStable;

  /// No description provided for @trendImproving.
  ///
  /// In en, this message translates to:
  /// **'Improving'**
  String get trendImproving;

  /// No description provided for @trendDeclining.
  ///
  /// In en, this message translates to:
  /// **'Declining'**
  String get trendDeclining;

  /// No description provided for @trendLessThan30Minutes.
  ///
  /// In en, this message translates to:
  /// **'Less than 30 minutes in this period'**
  String get trendLessThan30Minutes;

  /// No description provided for @trendHoursInPeriod.
  ///
  /// In en, this message translates to:
  /// **'{hours}h in this period'**
  String trendHoursInPeriod(String hours);

  /// No description provided for @trendTasksCompletedFraction.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} completed'**
  String trendTasksCompletedFraction(int completed, int total);

  /// No description provided for @trendTasksDeadlinesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks/deadlines added'**
  String trendTasksDeadlinesAdded(int count);

  /// No description provided for @trendVeryLowActivity.
  ///
  /// In en, this message translates to:
  /// **'Very low activity'**
  String get trendVeryLowActivity;

  /// No description provided for @trendLowActivity.
  ///
  /// In en, this message translates to:
  /// **'Low activity'**
  String get trendLowActivity;

  /// No description provided for @trendNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get trendNoTasks;

  /// No description provided for @trendNoTasksCompletedPeriod.
  ///
  /// In en, this message translates to:
  /// **'No tasks completed in this period'**
  String get trendNoTasksCompletedPeriod;

  /// No description provided for @trendZeroCompleted.
  ///
  /// In en, this message translates to:
  /// **'0% completed'**
  String get trendZeroCompleted;

  /// No description provided for @trendPercentCompleted.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completed'**
  String trendPercentCompleted(int percent);

  /// No description provided for @trendNoWorkload.
  ///
  /// In en, this message translates to:
  /// **'No workload'**
  String get trendNoWorkload;

  /// No description provided for @trendIncreased.
  ///
  /// In en, this message translates to:
  /// **'Increased'**
  String get trendIncreased;

  /// No description provided for @trendReducedComparedLastPeriod.
  ///
  /// In en, this message translates to:
  /// **'Reduced compared to last period'**
  String get trendReducedComparedLastPeriod;

  /// No description provided for @trendStatusOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get trendStatusOnTrack;

  /// No description provided for @trendStatusLowAndBehind.
  ///
  /// In en, this message translates to:
  /// **'Low activity and falling behind'**
  String get trendStatusLowAndBehind;

  /// No description provided for @trendStatusStudyNeedsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Study consistency needs improvement'**
  String get trendStatusStudyNeedsImprovement;

  /// No description provided for @trendStatusTaskIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Task progress is incomplete'**
  String get trendStatusTaskIncomplete;

  /// No description provided for @trendStatusStableProgress.
  ///
  /// In en, this message translates to:
  /// **'Stable progress'**
  String get trendStatusStableProgress;

  /// No description provided for @trendStatusOnTrackDetail.
  ///
  /// In en, this message translates to:
  /// **'Your recent activity looks balanced. Keep this pace.'**
  String get trendStatusOnTrackDetail;

  /// No description provided for @trendStatusNeedsFocusDetail.
  ///
  /// In en, this message translates to:
  /// **'Your activity is low and task progress is incomplete. Focus on completing tasks and increasing study time.'**
  String get trendStatusNeedsFocusDetail;

  /// No description provided for @trendStatusLowActivityHighCompletion.
  ///
  /// In en, this message translates to:
  /// **'Your activity is low, but task completion is strong.'**
  String get trendStatusLowActivityHighCompletion;

  /// No description provided for @trendStatusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get trendStatusNeedsAttention;

  /// No description provided for @trendStatusNeedsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Needs improvement'**
  String get trendStatusNeedsImprovement;

  /// No description provided for @trendStatusCriticalRiskDetail.
  ///
  /// In en, this message translates to:
  /// **'Risk factors identified. Review your study habits.'**
  String get trendStatusCriticalRiskDetail;

  /// No description provided for @trendInsightBuildConsistencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Build study consistency'**
  String get trendInsightBuildConsistencyTitle;

  /// No description provided for @trendInsightStudyIncreasedSignificantlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Study increased significantly'**
  String get trendInsightStudyIncreasedSignificantlyTitle;

  /// No description provided for @trendInsightStudyImprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Study improved'**
  String get trendInsightStudyImprovedTitle;

  /// No description provided for @trendInsightStudyDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Study declined'**
  String get trendInsightStudyDeclinedTitle;

  /// No description provided for @trendInsightNoTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this period'**
  String get trendInsightNoTasksTitle;

  /// No description provided for @trendInsightTaskLowTitle.
  ///
  /// In en, this message translates to:
  /// **'Task completion is low'**
  String get trendInsightTaskLowTitle;

  /// No description provided for @trendInsightNoWorkloadTitle.
  ///
  /// In en, this message translates to:
  /// **'No new workload'**
  String get trendInsightNoWorkloadTitle;

  /// No description provided for @trendInsightWorkloadSharpTitle.
  ///
  /// In en, this message translates to:
  /// **'Workload increased sharply'**
  String get trendInsightWorkloadSharpTitle;

  /// No description provided for @trendInsightWorkloadRisingTitle.
  ///
  /// In en, this message translates to:
  /// **'Workload is rising'**
  String get trendInsightWorkloadRisingTitle;

  /// No description provided for @trendInsightPerformanceDecliningTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance declining'**
  String get trendInsightPerformanceDecliningTitle;

  /// No description provided for @trendInsightPerformanceImprovingTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance improving'**
  String get trendInsightPerformanceImprovingTitle;

  /// No description provided for @trendInsightPerformanceStableTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance stable'**
  String get trendInsightPerformanceStableTitle;

  /// No description provided for @trendInsightStableTitle.
  ///
  /// In en, this message translates to:
  /// **'Stable trends'**
  String get trendInsightStableTitle;

  /// No description provided for @trendInsightBuildConsistencyMessage.
  ///
  /// In en, this message translates to:
  /// **'Start building a daily study habit.'**
  String get trendInsightBuildConsistencyMessage;

  /// No description provided for @trendInsightStudyIncreasedMessage.
  ///
  /// In en, this message translates to:
  /// **'Study increased by {percent}%. Keep this pace to stay ahead.'**
  String trendInsightStudyIncreasedMessage(int percent);

  /// No description provided for @trendInsightStudyDroppedMessage.
  ///
  /// In en, this message translates to:
  /// **'Study dropped by {percent}%. Consider scheduling extra sessions.'**
  String trendInsightStudyDroppedMessage(int percent);

  /// No description provided for @trendInsightNoTasksMessage.
  ///
  /// In en, this message translates to:
  /// **'No tasks were due in this period.'**
  String get trendInsightNoTasksMessage;

  /// No description provided for @trendInsightNoTasksCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'No tasks completed yet. Start completing tasks to track performance.'**
  String get trendInsightNoTasksCompletedMessage;

  /// No description provided for @trendInsightTaskCompletedFractionMessage.
  ///
  /// In en, this message translates to:
  /// **'You completed {completed} of {total} tasks. Try to complete more next period.'**
  String trendInsightTaskCompletedFractionMessage(int completed, int total);

  /// No description provided for @trendInsightNoWorkloadMessage.
  ///
  /// In en, this message translates to:
  /// **'No new tasks or deadlines were added in this period.'**
  String get trendInsightNoWorkloadMessage;

  /// No description provided for @trendInsightWorkloadAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'You added {count} tasks/deadlines in this period. Plan ahead to avoid overload.'**
  String trendInsightWorkloadAddedMessage(int count);

  /// No description provided for @trendInsightPerformanceDecliningMessage.
  ///
  /// In en, this message translates to:
  /// **'Performance trend is decreasing. Review weak courses this week.'**
  String get trendInsightPerformanceDecliningMessage;

  /// No description provided for @trendInsightPerformanceImprovingMessage.
  ///
  /// In en, this message translates to:
  /// **'Performance trend is improving. Keep the same study consistency.'**
  String get trendInsightPerformanceImprovingMessage;

  /// No description provided for @trendInsightPerformanceStableMessage.
  ///
  /// In en, this message translates to:
  /// **'Performance trend is stable. Keep up the consistent effort.'**
  String get trendInsightPerformanceStableMessage;

  /// No description provided for @trendInsightStableMessage.
  ///
  /// In en, this message translates to:
  /// **'No significant change yet. Keep logging consistently.'**
  String get trendInsightStableMessage;

  /// No description provided for @trendInsightLimitedDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Limited data for period'**
  String get trendInsightLimitedDataTitle;

  /// No description provided for @trendInsightLimitedDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Not enough sessions tracked in this specific time range to calculate reliable trends.'**
  String get trendInsightLimitedDataMessage;

  /// No description provided for @trendWorsening.
  ///
  /// In en, this message translates to:
  /// **'Worsening'**
  String get trendWorsening;

  /// No description provided for @trendUnstable.
  ///
  /// In en, this message translates to:
  /// **'Unstable'**
  String get trendUnstable;

  /// No description provided for @trendModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get trendModerate;

  /// No description provided for @recoveryMessage.
  ///
  /// In en, this message translates to:
  /// **'You are recovering. Keep this pattern.'**
  String get recoveryMessage;

  /// No description provided for @burnoutTrendNoHistory.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to detect trend yet.'**
  String get burnoutTrendNoHistory;

  /// No description provided for @burnoutTrendNoRecovery.
  ///
  /// In en, this message translates to:
  /// **'No recovery trend detected yet.'**
  String get burnoutTrendNoRecovery;

  /// No description provided for @dashboardRiskLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk Level'**
  String get dashboardRiskLevelTitle;

  /// No description provided for @dashboardRiskLevelValue.
  ///
  /// In en, this message translates to:
  /// **'Risk Level: {level}'**
  String dashboardRiskLevelValue(String level);

  /// No description provided for @dashboardTodaySnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Today Snapshot'**
  String get dashboardTodaySnapshotTitle;

  /// No description provided for @dashboardStudyToday.
  ///
  /// In en, this message translates to:
  /// **'Study: {time} today'**
  String dashboardStudyToday(String time);

  /// No description provided for @dashboardTasksCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'Tasks: {count} completed'**
  String dashboardTasksCompletedToday(int count);

  /// No description provided for @dashboardWorkloadAddedToday.
  ///
  /// In en, this message translates to:
  /// **'Workload: {count} added'**
  String dashboardWorkloadAddedToday(int count);

  /// No description provided for @dashboardKeyInsightTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Insight'**
  String get dashboardKeyInsightTitle;

  /// No description provided for @dashboardNoInsightAvailable.
  ///
  /// In en, this message translates to:
  /// **'No key insight available yet.'**
  String get dashboardNoInsightAvailable;

  /// No description provided for @dashboardQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActionsTitle;

  /// No description provided for @dashboardProgressOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress Overview'**
  String get dashboardProgressOverviewTitle;

  /// No description provided for @dashboardViewDetailedAnalysis.
  ///
  /// In en, this message translates to:
  /// **'View detailed analysis ->'**
  String get dashboardViewDetailedAnalysis;

  /// No description provided for @analyticsSparseDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Building your analytics'**
  String get analyticsSparseDataTitle;

  /// No description provided for @analyticsSparseDataBody.
  ///
  /// In en, this message translates to:
  /// **'Log study sessions, add tasks, and record grades. Charts fill in as you use the app.'**
  String get analyticsSparseDataBody;

  /// No description provided for @startTrackingYourSemester.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your semester'**
  String get startTrackingYourSemester;

  /// No description provided for @whatYouCanTrack.
  ///
  /// In en, this message translates to:
  /// **'What you can track'**
  String get whatYouCanTrack;

  /// No description provided for @trackTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get trackTasks;

  /// No description provided for @trackStudySessions.
  ///
  /// In en, this message translates to:
  /// **'Study sessions'**
  String get trackStudySessions;

  /// No description provided for @trackGrades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get trackGrades;

  /// No description provided for @whyItMatters.
  ///
  /// In en, this message translates to:
  /// **'Why it matters'**
  String get whyItMatters;

  /// No description provided for @monitorProgress.
  ///
  /// In en, this message translates to:
  /// **'Monitor your progress'**
  String get monitorProgress;

  /// No description provided for @reduceAcademicRisk.
  ///
  /// In en, this message translates to:
  /// **'Reduce academic risk'**
  String get reduceAcademicRisk;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @customDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom: {minutes}m'**
  String customDurationLabel(int minutes);

  /// No description provided for @enterMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter minutes'**
  String get enterMinutes;

  /// No description provided for @quickPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick Presets'**
  String get quickPresets;

  /// No description provided for @setDuration.
  ///
  /// In en, this message translates to:
  /// **'Set Duration'**
  String get setDuration;

  /// No description provided for @focusedTime.
  ///
  /// In en, this message translates to:
  /// **'Focused time'**
  String get focusedTime;

  /// No description provided for @startAnotherSession.
  ///
  /// In en, this message translates to:
  /// **'Start another session'**
  String get startAnotherSession;

  /// No description provided for @sessionInsightShort.
  ///
  /// In en, this message translates to:
  /// **'Short session. Try longer focus next time.'**
  String get sessionInsightShort;

  /// No description provided for @sessionInsightMedium.
  ///
  /// In en, this message translates to:
  /// **'Good session. Stay consistent.'**
  String get sessionInsightMedium;

  /// No description provided for @sessionInsightLong.
  ///
  /// In en, this message translates to:
  /// **'Strong focus session.'**
  String get sessionInsightLong;

  /// No description provided for @addedToWeeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'+{minutes}m added to weekly goal'**
  String addedToWeeklyGoal(int minutes);

  /// No description provided for @minimumSessionMessage.
  ///
  /// In en, this message translates to:
  /// **'Minimum session is 10 minutes'**
  String get minimumSessionMessage;

  /// No description provided for @durationRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter duration (10–240 minutes)'**
  String get durationRangeHint;

  /// No description provided for @selectCourseToStart.
  ///
  /// In en, this message translates to:
  /// **'Select a course to start'**
  String get selectCourseToStart;

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today: {completed} / {goal}'**
  String todayProgress(String completed, String goal);

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'This week: {completed} / {goal}'**
  String weeklyProgress(String completed, String goal);

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} day{count, plural, =1{} other{s}}'**
  String streakDays(int count);

  /// No description provided for @noStreak.
  ///
  /// In en, this message translates to:
  /// **'Start a streak today'**
  String get noStreak;

  /// No description provided for @insightTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short. Aim for at least 20 minutes.'**
  String get insightTooShort;

  /// No description provided for @insightDecent.
  ///
  /// In en, this message translates to:
  /// **'Decent start. Try extending your next session.'**
  String get insightDecent;

  /// No description provided for @insightStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong focus. Keep this consistency.'**
  String get insightStrong;

  /// No description provided for @lowFocus.
  ///
  /// In en, this message translates to:
  /// **'Low Focus'**
  String get lowFocus;

  /// No description provided for @mediumFocus.
  ///
  /// In en, this message translates to:
  /// **'Medium Focus'**
  String get mediumFocus;

  /// No description provided for @highFocus.
  ///
  /// In en, this message translates to:
  /// **'High Focus'**
  String get highFocus;

  /// No description provided for @goodFocus.
  ///
  /// In en, this message translates to:
  /// **'Good focus'**
  String get goodFocus;

  /// No description provided for @todayFocusedContext.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m focused tonight • {sessions} sessions'**
  String todayFocusedContext(int minutes, int sessions);

  /// No description provided for @studyIntent.
  ///
  /// In en, this message translates to:
  /// **'Study Intent'**
  String get studyIntent;

  /// No description provided for @studyIntentHint.
  ///
  /// In en, this message translates to:
  /// **'What is your main focus for this session?'**
  String get studyIntentHint;

  /// No description provided for @studyIntentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Read Chapter 4, Solve Calculus set...'**
  String get studyIntentPlaceholder;

  /// No description provided for @endsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at {time}'**
  String endsAt(String time);

  /// No description provided for @endsAround.
  ///
  /// In en, this message translates to:
  /// **'Ends around {time}'**
  String endsAround(String time);

  /// Label for structure-based sessions like Pomodoro
  ///
  /// In en, this message translates to:
  /// **'Structured session'**
  String get structuredSession;

  /// No description provided for @remainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining time'**
  String get remainingTime;

  /// No description provided for @sessionProgress.
  ///
  /// In en, this message translates to:
  /// **'Session {current} of {total}'**
  String sessionProgress(int current, int total);

  /// No description provided for @stayFocusedMsg.
  ///
  /// In en, this message translates to:
  /// **'Stay focused. You\'re doing well.'**
  String get stayFocusedMsg;

  /// No description provided for @halfwayMsg.
  ///
  /// In en, this message translates to:
  /// **'Halfway there!'**
  String get halfwayMsg;

  /// No description provided for @almostDoneMsg.
  ///
  /// In en, this message translates to:
  /// **'Almost there, keeps it up!'**
  String get almostDoneMsg;

  /// No description provided for @youStayedFocused.
  ///
  /// In en, this message translates to:
  /// **'You stayed focused for {minutes} minutes'**
  String youStayedFocused(int minutes);

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @weeklyGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly Goal Progress'**
  String get weeklyGoalProgress;

  /// No description provided for @weeklyGoalTag.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal}m'**
  String weeklyGoalTag(int goal);

  /// No description provided for @minutesDone.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m done'**
  String minutesDone(int minutes);

  /// No description provided for @sessionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Session Too Short'**
  String get sessionTooShort;

  /// No description provided for @sessionTooShortDescription.
  ///
  /// In en, this message translates to:
  /// **'Minimum session duration is 10 minutes to ensure effective focus. This session was not recorded.'**
  String get sessionTooShortDescription;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @weeklyStudyGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly Study Goal'**
  String get weeklyStudyGoal;

  /// No description provided for @behindThisWeek.
  ///
  /// In en, this message translates to:
  /// **'You\'re behind this week — take action today'**
  String get behindThisWeek;

  /// No description provided for @justGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Just getting started'**
  String get justGettingStarted;

  /// No description provided for @remainingHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h remaining'**
  String remainingHours(int hours);

  /// No description provided for @catchUpMessage.
  ///
  /// In en, this message translates to:
  /// **'{hours}h remaining • You need to catch up'**
  String catchUpMessage(int hours);

  /// No description provided for @focusScore.
  ///
  /// In en, this message translates to:
  /// **'Focus Score'**
  String get focusScore;

  /// No description provided for @moderateFocus.
  ///
  /// In en, this message translates to:
  /// **'Moderate Focus'**
  String get moderateFocus;

  /// No description provided for @patternConsistent.
  ///
  /// In en, this message translates to:
  /// **'Pattern: Consistent'**
  String get patternConsistent;

  /// No description provided for @patternIrregular.
  ///
  /// In en, this message translates to:
  /// **'Pattern: Irregular'**
  String get patternIrregular;

  /// No description provided for @confidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'Confidence: High'**
  String get confidenceHigh;

  /// No description provided for @confidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Confidence: Medium'**
  String get confidenceMedium;

  /// No description provided for @confidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Confidence: Low'**
  String get confidenceLow;

  /// No description provided for @basedOnSessions.
  ///
  /// In en, this message translates to:
  /// **'(based on {count} sessions)'**
  String basedOnSessions(int count);

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get gettingStarted;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @noDataForSemesterYet.
  ///
  /// In en, this message translates to:
  /// **'No data for this semester yet'**
  String get noDataForSemesterYet;

  /// No description provided for @statusStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get statusStable;

  /// No description provided for @statusImproving.
  ///
  /// In en, this message translates to:
  /// **'Improving'**
  String get statusImproving;

  /// No description provided for @statusDeclining.
  ///
  /// In en, this message translates to:
  /// **'Declining'**
  String get statusDeclining;

  /// No description provided for @statusModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get statusModerate;

  /// No description provided for @trySessionNow.
  ///
  /// In en, this message translates to:
  /// **'Try a {duration}-minute session now'**
  String trySessionNow(int duration);

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get startNow;

  /// No description provided for @sessionTooShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Too Short'**
  String get sessionTooShortTitle;

  /// No description provided for @sessionTooShortMessage.
  ///
  /// In en, this message translates to:
  /// **'Minimum session duration is 10 minutes. This session was not recorded.'**
  String get sessionTooShortMessage;

  /// No description provided for @focusRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining time'**
  String get focusRemaining;

  /// No description provided for @shortSessionInsight.
  ///
  /// In en, this message translates to:
  /// **'Short session. Try longer focus next time.'**
  String get shortSessionInsight;

  /// No description provided for @goodSessionInsight.
  ///
  /// In en, this message translates to:
  /// **'Good session. Stay consistent.'**
  String get goodSessionInsight;

  /// No description provided for @strongSessionInsight.
  ///
  /// In en, this message translates to:
  /// **'Strong focus session.'**
  String get strongSessionInsight;

  /// No description provided for @sessionEndedEarly.
  ///
  /// In en, this message translates to:
  /// **'Session ended early — try staying at least 15 min'**
  String get sessionEndedEarly;

  /// No description provided for @niceProgressToday.
  ///
  /// In en, this message translates to:
  /// **'Nice progress today'**
  String get niceProgressToday;

  /// No description provided for @studyConsistent.
  ///
  /// In en, this message translates to:
  /// **'Stay consistent this week'**
  String get studyConsistent;

  /// No description provided for @next15m.
  ///
  /// In en, this message translates to:
  /// **'Start a 15-minute session to rebuild focus'**
  String get next15m;

  /// No description provided for @next25m.
  ///
  /// In en, this message translates to:
  /// **'Continue with a 25-minute focus session'**
  String get next25m;

  /// No description provided for @next45m.
  ///
  /// In en, this message translates to:
  /// **'You’re in deep focus mode. Try a 45-minute session'**
  String get next45m;

  /// No description provided for @sessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sessions} =1{1 session} other{{count} sessions}}'**
  String sessionsCount(num count);

  /// No description provided for @minutesFocused.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m focused'**
  String minutesFocused(Object minutes);

  /// No description provided for @patternLabel.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get patternLabel;

  /// No description provided for @statusVariable.
  ///
  /// In en, this message translates to:
  /// **'Variable'**
  String get statusVariable;

  /// No description provided for @burnoutTrendForming.
  ///
  /// In en, this message translates to:
  /// **'Burnout risk is driven by sustained high study stress and severe study deficit.'**
  String get burnoutTrendForming;

  /// No description provided for @burnoutRiskIncreasing.
  ///
  /// In en, this message translates to:
  /// **'Risk is increasing due to low consistency and goal deficit.'**
  String get burnoutRiskIncreasing;

  /// No description provided for @burnoutReasonBehindGoal.
  ///
  /// In en, this message translates to:
  /// **'You are behind your weekly goal by {hours}h.'**
  String burnoutReasonBehindGoal(String hours);

  /// No description provided for @burnoutReasonInconsistent.
  ///
  /// In en, this message translates to:
  /// **'Your study pattern is inconsistent this week.'**
  String get burnoutReasonInconsistent;

  /// No description provided for @burnoutReasonFrequentSwitching.
  ///
  /// In en, this message translates to:
  /// **'You are switching study times frequently.'**
  String get burnoutReasonFrequentSwitching;

  /// No description provided for @burnoutReasonLoadAboveGoal.
  ///
  /// In en, this message translates to:
  /// **'Your total study load is above your weekly goal.'**
  String get burnoutReasonLoadAboveGoal;

  /// No description provided for @burnoutReasonNoSignals.
  ///
  /// In en, this message translates to:
  /// **'No major burnout signals detected yet.'**
  String get burnoutReasonNoSignals;

  /// No description provided for @burnoutReasonDeficit.
  ///
  /// In en, this message translates to:
  /// **'You are falling behind your weekly study goal.'**
  String get burnoutReasonDeficit;

  /// No description provided for @burnoutReasonStress.
  ///
  /// In en, this message translates to:
  /// **'High stress detected during study sessions.'**
  String get burnoutReasonStress;

  /// No description provided for @burnoutReasonConsistency.
  ///
  /// In en, this message translates to:
  /// **'Low study consistency over the last 7 days.'**
  String get burnoutReasonConsistency;

  /// No description provided for @burnoutReasonMood.
  ///
  /// In en, this message translates to:
  /// **'A declining mood trend has been detected.'**
  String get burnoutReasonMood;

  /// No description provided for @burnoutRecStable1.
  ///
  /// In en, this message translates to:
  /// **'Keep your current routine steady.'**
  String get burnoutRecStable1;

  /// No description provided for @burnoutRecStable2.
  ///
  /// In en, this message translates to:
  /// **'Continue tracking your weekly goal.'**
  String get burnoutRecStable2;

  /// No description provided for @burnoutRecWarning1.
  ///
  /// In en, this message translates to:
  /// **'Reduce session length a little.'**
  String get burnoutRecWarning1;

  /// No description provided for @burnoutRecWarning2.
  ///
  /// In en, this message translates to:
  /// **'Keep your study time in one consistent slot.'**
  String get burnoutRecWarning2;

  /// No description provided for @burnoutRecHighRisk1.
  ///
  /// In en, this message translates to:
  /// **'Shorten sessions and take breaks more often.'**
  String get burnoutRecHighRisk1;

  /// No description provided for @burnoutRecHighRisk2.
  ///
  /// In en, this message translates to:
  /// **'Focus on one study time window this week.'**
  String get burnoutRecHighRisk2;

  /// No description provided for @burnoutRecHighRisk3.
  ///
  /// In en, this message translates to:
  /// **'Take a recovery day if you feel drained.'**
  String get burnoutRecHighRisk3;

  /// No description provided for @burnoutRecRisk1.
  ///
  /// In en, this message translates to:
  /// **'Reduce session length right away.'**
  String get burnoutRecRisk1;

  /// No description provided for @burnoutRecRisk2.
  ///
  /// In en, this message translates to:
  /// **'Increase break frequency and simplify goals.'**
  String get burnoutRecRisk2;

  /// No description provided for @burnoutRecRisk3.
  ///
  /// In en, this message translates to:
  /// **'Take a recovery day before pushing harder.'**
  String get burnoutRecRisk3;

  /// No description provided for @overloadWarning.
  ///
  /// In en, this message translates to:
  /// **'You\'re pushing too hard. Take a proper break.'**
  String get overloadWarning;

  /// No description provided for @focusTrendMessage.
  ///
  /// In en, this message translates to:
  /// **'{trend} focus pattern this week'**
  String focusTrendMessage(String trend);

  /// No description provided for @focusAnalysisBasis.
  ///
  /// In en, this message translates to:
  /// **'Based on recent sessions, consistency, and stability.'**
  String get focusAnalysisBasis;

  /// No description provided for @longBreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get longBreakLabel;

  /// No description provided for @focusSessionCount.
  ///
  /// In en, this message translates to:
  /// **'Focus {current}/{total}'**
  String focusSessionCount(int current, int total);

  /// No description provided for @improving.
  ///
  /// In en, this message translates to:
  /// **'Improving'**
  String get improving;

  /// No description provided for @declining.
  ///
  /// In en, this message translates to:
  /// **'Declining'**
  String get declining;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @focusShort.
  ///
  /// In en, this message translates to:
  /// **'Short Focus'**
  String get focusShort;

  /// No description provided for @focusGood.
  ///
  /// In en, this message translates to:
  /// **'Good Focus'**
  String get focusGood;

  /// No description provided for @focusDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep Focus'**
  String get focusDeep;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusStoppedEarly.
  ///
  /// In en, this message translates to:
  /// **'Stopped early'**
  String get statusStoppedEarly;

  /// No description provided for @tryLongerFocus.
  ///
  /// In en, this message translates to:
  /// **'Try longer focus next time'**
  String get tryLongerFocus;

  /// No description provided for @solidSession.
  ///
  /// In en, this message translates to:
  /// **'Solid session, keep it up'**
  String get solidSession;

  /// No description provided for @excellentDeepWork.
  ///
  /// In en, this message translates to:
  /// **'Excellent deep work'**
  String get excellentDeepWork;

  /// No description provided for @focusScoreImpact.
  ///
  /// In en, this message translates to:
  /// **'Focus Score Impact'**
  String get focusScoreImpact;

  /// No description provided for @completedYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get completedYes;

  /// No description provided for @completedNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get completedNo;

  /// No description provided for @cycles.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get cycles;

  /// No description provided for @breaksSkipped.
  ///
  /// In en, this message translates to:
  /// **'Breaks skipped'**
  String get breaksSkipped;

  /// No description provided for @weeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get weeklyActivity;

  /// No description provided for @streakWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'🔥 Don\'t break your streak. Study today to keep it alive!'**
  String get streakWarningMessage;

  /// No description provided for @preivousWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get preivousWeekLabel;

  /// No description provided for @newWeekStart.
  ///
  /// In en, this message translates to:
  /// **'New week start'**
  String get newWeekStart;

  /// No description provided for @noStudyActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No study activity yet'**
  String get noStudyActivityYet;

  /// No description provided for @studiedOnlyOneDay.
  ///
  /// In en, this message translates to:
  /// **'You studied only one day this week'**
  String get studiedOnlyOneDay;

  /// No description provided for @gettingStartedExtend.
  ///
  /// In en, this message translates to:
  /// **'Getting started. Try to extend sessions'**
  String get gettingStartedExtend;

  /// No description provided for @buildingConsistency.
  ///
  /// In en, this message translates to:
  /// **'Building consistency'**
  String get buildingConsistency;

  /// No description provided for @strongConsistentPattern.
  ///
  /// In en, this message translates to:
  /// **'Strong and consistent study pattern'**
  String get strongConsistentPattern;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get noActivity;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @weeklyProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get weeklyProgressLabel;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New ⭐'**
  String get newBadge;

  /// No description provided for @weeklyGoalProgressHours.
  ///
  /// In en, this message translates to:
  /// **'{current} / {goal}'**
  String weeklyGoalProgressHours(String current, String goal);

  /// No description provided for @activeDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active day{count, plural, =1{} other{s}}'**
  String activeDaysCount(int count);

  /// No description provided for @peakDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Peak: {day}'**
  String peakDayLabel(String day);

  /// No description provided for @streakAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Streak at Risk!'**
  String get streakAtRisk;

  /// No description provided for @studyHabit.
  ///
  /// In en, this message translates to:
  /// **'Study Habit'**
  String get studyHabit;

  /// No description provided for @startStreakToday.
  ///
  /// In en, this message translates to:
  /// **'Start your streak today'**
  String get startStreakToday;

  /// No description provided for @streakDay1.
  ///
  /// In en, this message translates to:
  /// **'Day 1 completed. Build consistency tomorrow'**
  String get streakDay1;

  /// No description provided for @strongHabitForming.
  ///
  /// In en, this message translates to:
  /// **'Strong habit forming'**
  String get strongHabitForming;

  /// No description provided for @excellentDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Excellent discipline'**
  String get excellentDiscipline;

  /// No description provided for @lightFocus.
  ///
  /// In en, this message translates to:
  /// **'Light focus'**
  String get lightFocus;

  /// No description provided for @insightCycle.
  ///
  /// In en, this message translates to:
  /// **'High-quality focus pattern. Keep this cycle.'**
  String get insightCycle;

  /// No description provided for @insightStart.
  ///
  /// In en, this message translates to:
  /// **'Strong start. Extend beyond 30m for deeper focus.'**
  String get insightStart;

  /// No description provided for @insightMomentum.
  ///
  /// In en, this message translates to:
  /// **'Building momentum toward deep work.'**
  String get insightMomentum;

  /// No description provided for @focusPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String focusPoints(String points);

  /// No description provided for @pomodoroFocusStep.
  ///
  /// In en, this message translates to:
  /// **'Focus • 25 min'**
  String get pomodoroFocusStep;

  /// No description provided for @pomodoroBreakStep.
  ///
  /// In en, this message translates to:
  /// **'Break • 5 min'**
  String get pomodoroBreakStep;

  /// No description provided for @pomodoroRepeatStep.
  ///
  /// In en, this message translates to:
  /// **'4 cycles total'**
  String get pomodoroRepeatStep;

  /// No description provided for @pomodoroTotalFocusSummary.
  ///
  /// In en, this message translates to:
  /// **'Total focus: {minutes} min'**
  String pomodoroTotalFocusSummary(int minutes);

  /// No description provided for @pomodoroCompleted.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro completed'**
  String get pomodoroCompleted;

  /// No description provided for @cyclesCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} cycles completed'**
  String cyclesCompleted(int count);

  /// No description provided for @focusTimeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Focus time: {minutes} min'**
  String focusTimeBreakdown(int minutes);

  /// No description provided for @breakTimeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Break time: {minutes} min'**
  String breakTimeBreakdown(int minutes);

  /// No description provided for @excellentConsistency.
  ///
  /// In en, this message translates to:
  /// **'Excellent consistency'**
  String get excellentConsistency;

  /// No description provided for @totalFocusTime.
  ///
  /// In en, this message translates to:
  /// **'Total focus time'**
  String get totalFocusTime;

  /// No description provided for @streakDaysInARow.
  ///
  /// In en, this message translates to:
  /// **'{count} day{count, plural, =1{} other{s}} in a row'**
  String streakDaysInARow(int count);

  /// No description provided for @pomodoroMetrics.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get pomodoroMetrics;

  /// No description provided for @pomodoroPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get pomodoroPerformance;

  /// No description provided for @pomodoroTimeline.
  ///
  /// In en, this message translates to:
  /// **'Cycle Timeline'**
  String get pomodoroTimeline;

  /// No description provided for @pomodoroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro • {done}/{total} cycles'**
  String pomodoroSubtitle(int done, int total);

  /// No description provided for @focusCycleDone.
  ///
  /// In en, this message translates to:
  /// **'Focus {index}  •  {minutes} min'**
  String focusCycleDone(int index, int minutes);

  /// No description provided for @focusCycleInProgress.
  ///
  /// In en, this message translates to:
  /// **'Focus {index}  •  in progress'**
  String focusCycleInProgress(int index);

  /// No description provided for @focusCycleNotReached.
  ///
  /// In en, this message translates to:
  /// **'Focus {index}  •  not reached'**
  String focusCycleNotReached(int index);

  /// No description provided for @breakDone.
  ///
  /// In en, this message translates to:
  /// **'Break  •  {minutes} min'**
  String breakDone(int minutes);

  /// No description provided for @breakPending.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakPending;

  /// No description provided for @focusTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTimeLabel;

  /// No description provided for @breakTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Break Time'**
  String get breakTimeLabel;

  /// No description provided for @completionOfCycles.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of planned cycles'**
  String completionOfCycles(int percent);

  /// No description provided for @minutesFocusedLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min focused'**
  String minutesFocusedLabel(int minutes);

  /// No description provided for @pomodoroHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} cycles • {time}'**
  String pomodoroHistorySubtitle(int done, int total, String time);

  /// No description provided for @sessionHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{type} • {minutes}m • {time}'**
  String sessionHistorySubtitle(String type, int minutes, String time);

  /// No description provided for @statusBadgeCompleted.
  ///
  /// In en, this message translates to:
  /// **'✔ Completed'**
  String get statusBadgeCompleted;

  /// No description provided for @statusBadgeStopped.
  ///
  /// In en, this message translates to:
  /// **'⏸ Stopped early'**
  String get statusBadgeStopped;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorLoading(String error);

  /// No description provided for @pomodoroInsightConsistent.
  ///
  /// In en, this message translates to:
  /// **'You consistently complete full Pomodoro cycles'**
  String get pomodoroInsightConsistent;

  /// No description provided for @pomodoroInsightPartial.
  ///
  /// In en, this message translates to:
  /// **'You often stop mid-cycle. Try shorter sessions'**
  String get pomodoroInsightPartial;

  /// No description provided for @pomodoroInsightNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'You rarely complete Pomodoro cycles. Consider reducing duration'**
  String get pomodoroInsightNeedsWork;

  /// No description provided for @studyActivity.
  ///
  /// In en, this message translates to:
  /// **'Study Activity'**
  String get studyActivity;

  /// No description provided for @heatmapTooltip.
  ///
  /// In en, this message translates to:
  /// **'{date}: {minutes}m • {sessions} sessions • Score: {score}'**
  String heatmapTooltip(String date, int minutes, int sessions, int score);

  /// No description provided for @heatmapLegendLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get heatmapLegendLess;

  /// No description provided for @heatmapLegendMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get heatmapLegendMore;

  /// No description provided for @heatmapDayDetails.
  ///
  /// In en, this message translates to:
  /// **'Day Details'**
  String get heatmapDayDetails;

  /// No description provided for @streakCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} day streak}}'**
  String streakCount(num count);

  /// No description provided for @studyIntensitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily study intensity over time'**
  String get studyIntensitySubtitle;

  /// No description provided for @buildStreak.
  ///
  /// In en, this message translates to:
  /// **'BUILD YOUR STREAK'**
  String get buildStreak;

  /// No description provided for @buildStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your study activity history will appear here'**
  String get buildStreakSubtitle;

  /// No description provided for @goodConsistency.
  ///
  /// In en, this message translates to:
  /// **'Good consistency'**
  String get goodConsistency;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @heatmapActivityLegendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Activity: {label}'**
  String heatmapActivityLegendTooltip(Object label);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(Object count);

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// No description provided for @targetPrefix.
  ///
  /// In en, this message translates to:
  /// **'Target: {target}'**
  String targetPrefix(String target);

  /// No description provided for @recommendedForYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYouTitle;

  /// No description provided for @keepMyPreference.
  ///
  /// In en, this message translates to:
  /// **'Keep my preference'**
  String get keepMyPreference;

  /// No description provided for @followActualBehavior.
  ///
  /// In en, this message translates to:
  /// **'Follow actual behavior'**
  String get followActualBehavior;

  /// No description provided for @bestStudyTimeBullet.
  ///
  /// In en, this message translates to:
  /// **'• Best study time: {time}'**
  String bestStudyTimeBullet(String time);

  /// No description provided for @suggestedSessionBullet.
  ///
  /// In en, this message translates to:
  /// **'• Suggested session: {minutes} min ({pattern})'**
  String suggestedSessionBullet(int minutes, String pattern);

  /// No description provided for @dailyTargetNeededBullet.
  ///
  /// In en, this message translates to:
  /// **'• You need ~{hours} hours/day to stay on track'**
  String dailyTargetNeededBullet(String hours);

  /// No description provided for @burnoutInputsHumanized.
  ///
  /// In en, this message translates to:
  /// **'• Study deficit: {deficit}h\n• Consistency: {inconsistency}%'**
  String burnoutInputsHumanized(String deficit, int inconsistency);

  /// No description provided for @patternIrregularThisWeek.
  ///
  /// In en, this message translates to:
  /// **'• Pattern note: your study times are currently irregular this week.'**
  String get patternIrregularThisWeek;

  /// No description provided for @adaptiveHintRecentStudyTime.
  ///
  /// In en, this message translates to:
  /// **'You seem to study more in {time} recently.'**
  String adaptiveHintRecentStudyTime(String time);

  /// No description provided for @weekSessionsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'This week sessions: morning {morning}, afternoon {afternoon}, night {night}.'**
  String weekSessionsBreakdown(int morning, int afternoon, int night);

  /// No description provided for @confidenceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Confidence: behavior {behavior}% • preference match {preference}% {trendText}'**
  String confidenceBreakdown(int behavior, int preference, String trendText);

  /// No description provided for @trendDeltaVsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'• trend {delta} vs last week'**
  String trendDeltaVsLastWeek(String delta);

  /// No description provided for @weeklyGoalBehindDetailed.
  ///
  /// In en, this message translates to:
  /// **'You are behind your weekly goal ({logged}h logged vs {expected}h expected by now).'**
  String weeklyGoalBehindDetailed(String logged, String expected);

  /// No description provided for @warningActionStartSession.
  ///
  /// In en, this message translates to:
  /// **'Start a 25-40 min session now to get back on track.'**
  String get warningActionStartSession;

  /// No description provided for @weeklyGoalSlightlyBehind.
  ///
  /// In en, this message translates to:
  /// **'You are slightly behind your weekly goal. Keep your current pace.'**
  String get weeklyGoalSlightlyBehind;

  /// No description provided for @burnoutStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Burnout Status'**
  String get burnoutStatusTitle;

  /// No description provided for @burnoutOverallTrend.
  ///
  /// In en, this message translates to:
  /// **'Overall: {status}'**
  String burnoutOverallTrend(String status);

  /// No description provided for @burnoutTrendLine.
  ///
  /// In en, this message translates to:
  /// **'Trend: {status} {direction}'**
  String burnoutTrendLine(String status, String direction);

  /// No description provided for @burnoutDeficitLine.
  ///
  /// In en, this message translates to:
  /// **'Deficit: {status} {direction}'**
  String burnoutDeficitLine(String status, String direction);

  /// No description provided for @burnoutConsistencyLine.
  ///
  /// In en, this message translates to:
  /// **'Consistency: {status} {direction}'**
  String burnoutConsistencyLine(String status, String direction);

  /// No description provided for @noRecoveryTrendDetectedYet.
  ///
  /// In en, this message translates to:
  /// **'No recovery trend detected yet.'**
  String get noRecoveryTrendDetectedYet;

  /// No description provided for @notEnoughDataTrendYet.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to detect trend yet.'**
  String get notEnoughDataTrendYet;

  /// No description provided for @recoveryImprovingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Your study pattern is improving this week.'**
  String get recoveryImprovingThisWeek;

  /// No description provided for @studyDeficitBasedOnWeeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'Study deficit is based on your weekly goal ({hours}h).'**
  String studyDeficitBasedOnWeeklyGoal(String hours);

  /// No description provided for @softInterventionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Soft interventions'**
  String get softInterventionsTitle;

  /// No description provided for @burnoutLevelStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get burnoutLevelStable;

  /// No description provided for @burnoutLevelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get burnoutLevelWarning;

  /// No description provided for @burnoutLevelHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get burnoutLevelHighRisk;

  /// No description provided for @burnoutLevelBurnoutRisk.
  ///
  /// In en, this message translates to:
  /// **'Burnout Risk'**
  String get burnoutLevelBurnoutRisk;

  /// No description provided for @burnoutExplanationStable.
  ///
  /// In en, this message translates to:
  /// **'Your study pattern looks balanced right now.'**
  String get burnoutExplanationStable;

  /// No description provided for @burnoutExplanationWarning.
  ///
  /// In en, this message translates to:
  /// **'Your study pattern is becoming inconsistent and you are falling behind your weekly goal.'**
  String get burnoutExplanationWarning;

  /// No description provided for @burnoutExplanationHighRisk.
  ///
  /// In en, this message translates to:
  /// **'You are showing signs of inconsistent study and deficit.'**
  String get burnoutExplanationHighRisk;

  /// No description provided for @burnoutExplanationBurnoutRisk.
  ///
  /// In en, this message translates to:
  /// **'Your load is high and your routine is becoming unstable.'**
  String get burnoutExplanationBurnoutRisk;

  /// No description provided for @burnoutReasonInconsistentPattern.
  ///
  /// In en, this message translates to:
  /// **'Your study pattern is inconsistent this week.'**
  String get burnoutReasonInconsistentPattern;

  /// No description provided for @burnoutReasonSwitchingTimes.
  ///
  /// In en, this message translates to:
  /// **'You are switching study times frequently.'**
  String get burnoutReasonSwitchingTimes;

  /// No description provided for @burnoutReasonNoMajorSignals.
  ///
  /// In en, this message translates to:
  /// **'No major burnout signals detected yet.'**
  String get burnoutReasonNoMajorSignals;

  /// No description provided for @burnoutRecommendationStable1.
  ///
  /// In en, this message translates to:
  /// **'Keep your current routine steady.'**
  String get burnoutRecommendationStable1;

  /// No description provided for @burnoutRecommendationStable2.
  ///
  /// In en, this message translates to:
  /// **'Continue tracking your weekly goal.'**
  String get burnoutRecommendationStable2;

  /// No description provided for @burnoutRecommendationWarning1.
  ///
  /// In en, this message translates to:
  /// **'Reduce session length a little.'**
  String get burnoutRecommendationWarning1;

  /// No description provided for @burnoutRecommendationWarning2.
  ///
  /// In en, this message translates to:
  /// **'Keep your study time in one consistent slot.'**
  String get burnoutRecommendationWarning2;

  /// No description provided for @burnoutRecommendationHigh1.
  ///
  /// In en, this message translates to:
  /// **'Shorten sessions and take breaks more often.'**
  String get burnoutRecommendationHigh1;

  /// No description provided for @burnoutRecommendationHigh2.
  ///
  /// In en, this message translates to:
  /// **'Focus on one study time window this week.'**
  String get burnoutRecommendationHigh2;

  /// No description provided for @burnoutRecommendationHigh3.
  ///
  /// In en, this message translates to:
  /// **'Take a recovery day if you feel drained.'**
  String get burnoutRecommendationHigh3;

  /// No description provided for @burnoutRecommendationBurnout1.
  ///
  /// In en, this message translates to:
  /// **'Reduce session length right away.'**
  String get burnoutRecommendationBurnout1;

  /// No description provided for @burnoutRecommendationBurnout2.
  ///
  /// In en, this message translates to:
  /// **'Increase break frequency and simplify goals.'**
  String get burnoutRecommendationBurnout2;

  /// No description provided for @burnoutRecommendationBurnout3.
  ///
  /// In en, this message translates to:
  /// **'Take a recovery day before pushing harder.'**
  String get burnoutRecommendationBurnout3;

  /// No description provided for @decisionNextActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Next Action'**
  String get decisionNextActionTitle;

  /// No description provided for @decisionStudyAnyCourse.
  ///
  /// In en, this message translates to:
  /// **'Study your priority course'**
  String get decisionStudyAnyCourse;

  /// No description provided for @decisionStudyCourse.
  ///
  /// In en, this message translates to:
  /// **'Study {course}'**
  String decisionStudyCourse(String course);

  /// No description provided for @decisionMinutesToday.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes today'**
  String decisionMinutesToday(int minutes);

  /// No description provided for @decisionFocusRecommendationTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Recommendation'**
  String get decisionFocusRecommendationTitle;

  /// No description provided for @decisionWhatChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'What Changed'**
  String get decisionWhatChangedTitle;

  /// No description provided for @decisionTaskLoadLabel.
  ///
  /// In en, this message translates to:
  /// **'Task Load'**
  String get decisionTaskLoadLabel;

  /// No description provided for @decisionConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Confidence: Low (based on recent activity)'**
  String get decisionConfidenceLow;

  /// No description provided for @startedFromAnalyticsRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Started from Analytics recommendation'**
  String get startedFromAnalyticsRecommendation;

  /// No description provided for @followedPlanToday.
  ///
  /// In en, this message translates to:
  /// **'Nice. You followed your plan today.'**
  String get followedPlanToday;

  /// No description provided for @sessionImpactAddedToCourse.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} min added to {course}'**
  String sessionImpactAddedToCourse(int minutes, String course);

  /// No description provided for @sessionImpactCloserToGoal.
  ///
  /// In en, this message translates to:
  /// **'You\'re now closer to your weekly goal'**
  String get sessionImpactCloserToGoal;

  /// No description provided for @decisionReasonOverdueAttention.
  ///
  /// In en, this message translates to:
  /// **'Overdue tasks need immediate attention'**
  String get decisionReasonOverdueAttention;

  /// No description provided for @decisionReasonLeastStudied.
  ///
  /// In en, this message translates to:
  /// **'You studied this course the least this week'**
  String get decisionReasonLeastStudied;

  /// No description provided for @decisionReasonNoUrgentDeadlines.
  ///
  /// In en, this message translates to:
  /// **'No urgent deadlines. Stay consistent.'**
  String get decisionReasonNoUrgentDeadlines;

  /// No description provided for @decisionReasonBehindWeeklyTarget.
  ///
  /// In en, this message translates to:
  /// **'You are behind your weekly target'**
  String get decisionReasonBehindWeeklyTarget;

  /// No description provided for @decisionReasonHeavyWorkload.
  ///
  /// In en, this message translates to:
  /// **'Heavy open workload in this course'**
  String get decisionReasonHeavyWorkload;

  /// No description provided for @decisionReasonHighestPriority.
  ///
  /// In en, this message translates to:
  /// **'This is your highest-priority course right now'**
  String get decisionReasonHighestPriority;

  /// No description provided for @decisionReasonBuildRoutine.
  ///
  /// In en, this message translates to:
  /// **'Start building your routine'**
  String get decisionReasonBuildRoutine;

  /// No description provided for @decisionReasonLowestStudyWeek.
  ///
  /// In en, this message translates to:
  /// **'Lowest study time this week'**
  String get decisionReasonLowestStudyWeek;

  /// No description provided for @decisionReasonNoStudyLogged.
  ///
  /// In en, this message translates to:
  /// **'No study logged this week'**
  String get decisionReasonNoStudyLogged;

  /// No description provided for @decisionReasonFallbackConsistency.
  ///
  /// In en, this message translates to:
  /// **'Fallback recommendation: keep your consistency this week'**
  String get decisionReasonFallbackConsistency;

  /// No description provided for @decisionReasonStudyProgress.
  ///
  /// In en, this message translates to:
  /// **'You studied {studied}h of your {target}h target'**
  String decisionReasonStudyProgress(String studied, String target);

  /// No description provided for @decisionReasonImportantCourse.
  ///
  /// In en, this message translates to:
  /// **'Important course ({ects} ECTS)'**
  String decisionReasonImportantCourse(int ects);

  /// No description provided for @decisionReasonHigherPriorityThan.
  ///
  /// In en, this message translates to:
  /// **'More urgent than {course}'**
  String decisionReasonHigherPriorityThan(String course);

  /// No description provided for @decisionReasonHigherPriorityGeneral.
  ///
  /// In en, this message translates to:
  /// **'More urgent than other courses this week'**
  String get decisionReasonHigherPriorityGeneral;

  /// No description provided for @todayPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Today Plan'**
  String get todayPlanTitle;

  /// No description provided for @todayMinutesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Today: {minutes} min completed'**
  String todayMinutesCompleted(int minutes);

  /// No description provided for @recoveryPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Plan'**
  String get recoveryPlanTitle;

  /// No description provided for @recoveryPlanSplitFromWeeklyDeficit.
  ///
  /// In en, this message translates to:
  /// **'Split based on your weekly deficit'**
  String get recoveryPlanSplitFromWeeklyDeficit;

  /// No description provided for @planDay3Label.
  ///
  /// In en, this message translates to:
  /// **'Day 3'**
  String get planDay3Label;

  /// No description provided for @suggestedSplitSessionsToday.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {count} × {minutes} min sessions today'**
  String suggestedSplitSessionsToday(int count, int minutes);

  /// No description provided for @suggestedFlexibleSessionsToday.
  ///
  /// In en, this message translates to:
  /// **'Suggested: 2-3 focused sessions today'**
  String get suggestedFlexibleSessionsToday;

  /// No description provided for @suggestedShorterSessionsToday.
  ///
  /// In en, this message translates to:
  /// **'Suggested: 3-4 shorter sessions today'**
  String get suggestedShorterSessionsToday;

  /// No description provided for @recoveryMessageStressHigh.
  ///
  /// In en, this message translates to:
  /// **'Focus on shorter sessions today to avoid burnout'**
  String get recoveryMessageStressHigh;

  /// No description provided for @needHoursTodayToStayOnTrack.
  ///
  /// In en, this message translates to:
  /// **'You need {hours}h today to stay on track'**
  String needHoursTodayToStayOnTrack(String hours);

  /// No description provided for @minutesRemainingShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m left'**
  String minutesRemainingShort(int minutes);

  /// No description provided for @decisionReasonDeadlineLowStudy.
  ///
  /// In en, this message translates to:
  /// **'Deadline in {days} days and you studied less than usual this week'**
  String decisionReasonDeadlineLowStudy(int days);

  /// No description provided for @decisionReasonDeadlineInDays.
  ///
  /// In en, this message translates to:
  /// **'Deadline in {days} days'**
  String decisionReasonDeadlineInDays(int days);

  /// No description provided for @decisionReasonLowestStudyWithDeadline.
  ///
  /// In en, this message translates to:
  /// **'Lowest study time this week and deadline in {days} days'**
  String decisionReasonLowestStudyWithDeadline(int days);

  /// No description provided for @decisionReasonLowestStudyWithOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'Lowest study time this week and {count} open tasks'**
  String decisionReasonLowestStudyWithOpenTasks(int count);

  /// No description provided for @decisionReasonHighCourseWeight.
  ///
  /// In en, this message translates to:
  /// **'High course weight ({ects} ECTS)'**
  String decisionReasonHighCourseWeight(int ects);

  /// Button label to reset a study session timer
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Label for the current status of a study session or item
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @logMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Mood'**
  String get logMoodTitle;

  /// No description provided for @moodAfterSessionPrompt.
  ///
  /// In en, this message translates to:
  /// **'How do you feel after this study session?'**
  String get moodAfterSessionPrompt;

  /// No description provided for @moodManualPrompt.
  ///
  /// In en, this message translates to:
  /// **'Track your current mood and stress to improve your study insights.'**
  String get moodManualPrompt;

  /// No description provided for @moodLevel.
  ///
  /// In en, this message translates to:
  /// **'Mood Level'**
  String get moodLevel;

  /// No description provided for @stressLevel.
  ///
  /// In en, this message translates to:
  /// **'Stress Level'**
  String get stressLevel;

  /// No description provided for @energyLevel.
  ///
  /// In en, this message translates to:
  /// **'Energy Level'**
  String get energyLevel;

  /// No description provided for @moodFactors.
  ///
  /// In en, this message translates to:
  /// **'Factors'**
  String get moodFactors;

  /// No description provided for @moodFactorSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get moodFactorSleep;

  /// No description provided for @moodFactorWorkload.
  ///
  /// In en, this message translates to:
  /// **'Workload'**
  String get moodFactorWorkload;

  /// No description provided for @moodFactorHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get moodFactorHealth;

  /// No description provided for @moodFactorMotivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get moodFactorMotivation;

  /// No description provided for @moodFactorSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get moodFactorSocial;

  /// No description provided for @moodFactorExams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get moodFactorExams;

  /// No description provided for @saveMood.
  ///
  /// In en, this message translates to:
  /// **'Save Mood'**
  String get saveMood;

  /// No description provided for @moodSaved.
  ///
  /// In en, this message translates to:
  /// **'Mood log saved.'**
  String get moodSaved;

  /// No description provided for @moodSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save mood log.'**
  String get moodSaveFailed;

  /// No description provided for @moodAndStressTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood & Stress'**
  String get moodAndStressTitle;

  /// No description provided for @moodAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average Mood'**
  String get moodAverageLabel;

  /// No description provided for @stressAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average Stress'**
  String get stressAverageLabel;

  /// No description provided for @moodNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get moodNoData;

  /// No description provided for @moodSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood & Stress Settings'**
  String get moodSettingsTitle;

  /// No description provided for @enableMoodTracking.
  ///
  /// In en, this message translates to:
  /// **'Enable Mood Tracking'**
  String get enableMoodTracking;

  /// No description provided for @enableMoodReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable Reminders'**
  String get enableMoodReminders;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTimeLabel;

  /// No description provided for @reminderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder Type'**
  String get reminderTypeLabel;

  /// No description provided for @reminderTypeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get reminderTypeDaily;

  /// No description provided for @reminderTypeAfterStudy.
  ///
  /// In en, this message translates to:
  /// **'After Study'**
  String get reminderTypeAfterStudy;

  /// No description provided for @reminderTypeBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get reminderTypeBoth;

  /// No description provided for @moodHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood History'**
  String get moodHistoryTitle;

  /// No description provided for @moodDailyPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get moodDailyPromptTitle;

  /// No description provided for @moodDailyPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track mood and stress to improve your study decisions.'**
  String get moodDailyPromptSubtitle;

  /// No description provided for @moodReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood check-in'**
  String get moodReminderTitle;

  /// No description provided for @moodReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Take a minute to log your mood and stress.'**
  String get moodReminderBody;

  /// No description provided for @moodLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Mood over last 7 days'**
  String get moodLast7Days;

  /// No description provided for @moodOverLastDays.
  ///
  /// In en, this message translates to:
  /// **'Mood over last {count} days'**
  String moodOverLastDays(int count);

  /// No description provided for @moodKeepLogging.
  ///
  /// In en, this message translates to:
  /// **'Keep logging your mood'**
  String get moodKeepLogging;

  /// No description provided for @moodTrendNeedsData.
  ///
  /// In en, this message translates to:
  /// **'Keep logging your mood to see your personal emotional trend chart.'**
  String get moodTrendNeedsData;

  /// No description provided for @dailyMoodHistory.
  ///
  /// In en, this message translates to:
  /// **'Daily Mood History'**
  String get dailyMoodHistory;

  /// No description provided for @olderLabel.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get olderLabel;

  /// No description provided for @decisionSmartInsights.
  ///
  /// In en, this message translates to:
  /// **'Smart Insights'**
  String get decisionSmartInsights;

  /// No description provided for @decisionHighStress.
  ///
  /// In en, this message translates to:
  /// **'High stress detected'**
  String get decisionHighStress;

  /// No description provided for @decisionShortSessions.
  ///
  /// In en, this message translates to:
  /// **'Use shorter sessions today'**
  String get decisionShortSessions;

  /// No description provided for @decisionDeepWork.
  ///
  /// In en, this message translates to:
  /// **'You are in a strong state for deep work'**
  String get decisionDeepWork;

  /// No description provided for @decisionBurnoutWarning.
  ///
  /// In en, this message translates to:
  /// **'Burnout risk is increasing'**
  String get decisionBurnoutWarning;

  /// No description provided for @decisionStressRising.
  ///
  /// In en, this message translates to:
  /// **'Your stress is rising this week'**
  String get decisionStressRising;

  /// No description provided for @decisionMoodDeclining.
  ///
  /// In en, this message translates to:
  /// **'Your mood is declining'**
  String get decisionMoodDeclining;

  /// No description provided for @decisionDeadlinePressure.
  ///
  /// In en, this message translates to:
  /// **'High pressure detected. Break tasks down'**
  String get decisionDeadlinePressure;

  /// No description provided for @decisionLowActivityHighStress.
  ///
  /// In en, this message translates to:
  /// **'Low Activity, High Stress'**
  String get decisionLowActivityHighStress;

  /// No description provided for @decisionLightTasksOnly.
  ///
  /// In en, this message translates to:
  /// **'Mood is low today. Stick to lighter tasks.'**
  String get decisionLightTasksOnly;

  /// No description provided for @decisionMainFactor.
  ///
  /// In en, this message translates to:
  /// **'Main Factor: {factor}'**
  String decisionMainFactor(String factor);

  /// No description provided for @decisionWorstDay.
  ///
  /// In en, this message translates to:
  /// **'Difficult {day} ahead'**
  String decisionWorstDay(String day);

  /// No description provided for @decisionMorningPlanning.
  ///
  /// In en, this message translates to:
  /// **'Morning Strategy'**
  String get decisionMorningPlanning;

  /// No description provided for @decisionAfternoonExecution.
  ///
  /// In en, this message translates to:
  /// **'Afternoon Peak'**
  String get decisionAfternoonExecution;

  /// No description provided for @decisionNightLightReview.
  ///
  /// In en, this message translates to:
  /// **'Night Review'**
  String get decisionNightLightReview;

  /// No description provided for @decisionActionShortSessions.
  ///
  /// In en, this message translates to:
  /// **'High stress with low activity detected. Try 15-min sessions.'**
  String get decisionActionShortSessions;

  /// No description provided for @decisionActionBreakDown.
  ///
  /// In en, this message translates to:
  /// **'Break down large tasks to reduce session stress.'**
  String get decisionActionBreakDown;

  /// No description provided for @decisionActionMonitorWeekly.
  ///
  /// In en, this message translates to:
  /// **'Monitor this pattern through the week'**
  String get decisionActionMonitorWeekly;

  /// No description provided for @decisionActionPlanning.
  ///
  /// In en, this message translates to:
  /// **'Start with planning. Clear goals reduce session anxiety.'**
  String get decisionActionPlanning;

  /// No description provided for @decisionActionExecution.
  ///
  /// In en, this message translates to:
  /// **'Execute difficult tasks now while energy is high.'**
  String get decisionActionExecution;

  /// No description provided for @decisionActionLightReview.
  ///
  /// In en, this message translates to:
  /// **'Stress is trending up. Consider a lighter study session.'**
  String get decisionActionLightReview;

  /// No description provided for @startRecommendedSession.
  ///
  /// In en, this message translates to:
  /// **'Start Recommended Session ({minutes} min)'**
  String startRecommendedSession(int minutes);

  /// No description provided for @smartInsightUpdated.
  ///
  /// In en, this message translates to:
  /// **'Smart Insight Updated'**
  String get smartInsightUpdated;

  /// No description provided for @moodSavedPositive1.
  ///
  /// In en, this message translates to:
  /// **'Saved. Great consistency.'**
  String get moodSavedPositive1;

  /// No description provided for @moodSavedPositive2.
  ///
  /// In en, this message translates to:
  /// **'Saved. Keep going.'**
  String get moodSavedPositive2;

  /// No description provided for @moodSavedPositive3.
  ///
  /// In en, this message translates to:
  /// **'Saved. Nice progress.'**
  String get moodSavedPositive3;

  /// No description provided for @moodSavedPositive4.
  ///
  /// In en, this message translates to:
  /// **'Saved. You are doing well.'**
  String get moodSavedPositive4;

  /// No description provided for @todaysMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Mood'**
  String get todaysMoodTitle;

  /// No description provided for @stressOutOfTen.
  ///
  /// In en, this message translates to:
  /// **'Stress {value}/10'**
  String stressOutOfTen(int value);

  /// No description provided for @takeItSlowerTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Take it slower today'**
  String get takeItSlowerTodayTitle;

  /// No description provided for @takeItSlowerTodayBody.
  ///
  /// In en, this message translates to:
  /// **'You have multiple deadlines soon. Pace yourself.'**
  String get takeItSlowerTodayBody;

  /// No description provided for @strongStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Peak Focus State'**
  String get strongStateTitle;

  /// No description provided for @strongStateBody.
  ///
  /// In en, this message translates to:
  /// **'You are in a great mood with low stress. Tackle a difficult task!'**
  String get strongStateBody;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @focusRecommendationPrimary.
  ///
  /// In en, this message translates to:
  /// **'Focus Recommendation (Primary)'**
  String get focusRecommendationPrimary;

  /// No description provided for @decisionConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'Confidence: High (based on recent activity)'**
  String get decisionConfidenceHigh;

  /// No description provided for @decisionConfidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Confidence: Medium (based on recent activity)'**
  String get decisionConfidenceMedium;

  /// No description provided for @decisionBurnoutDurationCap.
  ///
  /// In en, this message translates to:
  /// **'Shorter sessions recommended to prevent burnout.'**
  String get decisionBurnoutDurationCap;

  /// No description provided for @decisionFixedSchedule.
  ///
  /// In en, this message translates to:
  /// **'Build a fixed schedule'**
  String get decisionFixedSchedule;

  /// No description provided for @decisionActionFixedSchedule.
  ///
  /// In en, this message translates to:
  /// **'Establishing a routine can lower daily session stress.'**
  String get decisionActionFixedSchedule;

  /// No description provided for @postSessionMoodImproved.
  ///
  /// In en, this message translates to:
  /// **'Your mood improved after studying'**
  String get postSessionMoodImproved;

  /// No description provided for @postSessionStressIncreased.
  ///
  /// In en, this message translates to:
  /// **'Long sessions may be increasing your stress'**
  String get postSessionStressIncreased;

  /// No description provided for @postSessionFeedbackLogged.
  ///
  /// In en, this message translates to:
  /// **'Post-session feedback captured'**
  String get postSessionFeedbackLogged;

  /// No description provided for @consistencyScoreLine.
  ///
  /// In en, this message translates to:
  /// **'Consistency: {score}% ({trend})'**
  String consistencyScoreLine(int score, String trend);

  /// No description provided for @predictionStressTitle.
  ///
  /// In en, this message translates to:
  /// **'Predicted Stress (Next 3 Days)'**
  String get predictionStressTitle;

  /// No description provided for @predictionPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended Plan'**
  String get predictionPlanTitle;

  /// No description provided for @predictionLevelLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get predictionLevelLow;

  /// No description provided for @predictionLevelMedium.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get predictionLevelMedium;

  /// No description provided for @predictionLevelHigh.
  ///
  /// In en, this message translates to:
  /// **'Stress trend: Increasing'**
  String get predictionLevelHigh;

  /// No description provided for @predictionReasonHighStressToday.
  ///
  /// In en, this message translates to:
  /// **'Stress: {stress}/10'**
  String predictionReasonHighStressToday(String stress);

  /// No description provided for @predictionReasonLowConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency: {percent}%'**
  String predictionReasonLowConsistency(String percent);

  /// No description provided for @predictionReasonUpcomingWorkload.
  ///
  /// In en, this message translates to:
  /// **'Deadlines: {count}'**
  String predictionReasonUpcomingWorkload(int count);

  /// No description provided for @predictionMainReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Main reason:'**
  String get predictionMainReasonTitle;

  /// No description provided for @predictionWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why this plan?'**
  String get predictionWhyTitle;

  /// No description provided for @predictionReasonStressHigh.
  ///
  /// In en, this message translates to:
  /// **'Stress: {stress}/10'**
  String predictionReasonStressHigh(String stress);

  /// No description provided for @predictionReasonLowConsistencyDetail.
  ///
  /// In en, this message translates to:
  /// **'Consistency: {delta}%'**
  String predictionReasonLowConsistencyDetail(String delta);

  /// No description provided for @predictionReasonTasksPending.
  ///
  /// In en, this message translates to:
  /// **'Pending tasks: {count}'**
  String predictionReasonTasksPending(int count);

  /// No description provided for @predictionReasonDeadlinesSoon.
  ///
  /// In en, this message translates to:
  /// **'Deadlines: {count}'**
  String predictionReasonDeadlinesSoon(int count);

  /// No description provided for @predictionAffectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Affected:'**
  String get predictionAffectedTitle;

  /// No description provided for @predictionPlanLine.
  ///
  /// In en, this message translates to:
  /// **'{day} at {time} • {minutes} min {focus} session'**
  String predictionPlanLine(String day, String time, int minutes, String focus);

  /// No description provided for @predictionPlanLineSimple.
  ///
  /// In en, this message translates to:
  /// **'• {day}: {minutes} min {focus}'**
  String predictionPlanLineSimple(String day, int minutes, String focus);

  /// No description provided for @predictionPlanLightFocus.
  ///
  /// In en, this message translates to:
  /// **'Light Focus Session'**
  String get predictionPlanLightFocus;

  /// No description provided for @predictionPlanFocusExecution.
  ///
  /// In en, this message translates to:
  /// **'Focus Execution Session'**
  String get predictionPlanFocusExecution;

  /// No description provided for @predictionPlanDeepExecution.
  ///
  /// In en, this message translates to:
  /// **'Deep Execution Session'**
  String get predictionPlanDeepExecution;

  /// No description provided for @predictionPlanLightReview.
  ///
  /// In en, this message translates to:
  /// **'Light Review Session'**
  String get predictionPlanLightReview;

  /// No description provided for @predictionPerformanceRisk.
  ///
  /// In en, this message translates to:
  /// **'Performance Risk: {level}'**
  String predictionPerformanceRisk(String level);

  /// No description provided for @predictionPerformanceRiskLagging.
  ///
  /// In en, this message translates to:
  /// **'Performance Risk: {level} • Falling behind: {courses}'**
  String predictionPerformanceRiskLagging(String level, String courses);

  /// No description provided for @moodNameAwful.
  ///
  /// In en, this message translates to:
  /// **'Awful'**
  String get moodNameAwful;

  /// No description provided for @moodNameBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get moodNameBad;

  /// No description provided for @moodNameNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNameNeutral;

  /// No description provided for @moodNameGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodNameGood;

  /// No description provided for @moodNameGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get moodNameGreat;

  /// No description provided for @imFeelingMood.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling {mood}'**
  String imFeelingMood(String mood);

  /// No description provided for @saveMoodDots.
  ///
  /// In en, this message translates to:
  /// **'Save Mood • {mood} • Stress {stress}'**
  String saveMoodDots(String mood, String stress);

  /// No description provided for @addQuickNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a quick note (optional)'**
  String get addQuickNoteOptional;

  /// No description provided for @analyticsMoodPerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'🧠 Mood vs Performance'**
  String get analyticsMoodPerformanceTitle;

  /// No description provided for @analyticsMoodPerformanceGoodDesc.
  ///
  /// In en, this message translates to:
  /// **'Your high mood positively impacts your focus duration.'**
  String get analyticsMoodPerformanceGoodDesc;

  /// No description provided for @analyticsMoodLabel.
  ///
  /// In en, this message translates to:
  /// **'🙂 {label}: {value} {trend}'**
  String analyticsMoodLabel(String label, String value, String trend);

  /// No description provided for @analyticsStressLabel.
  ///
  /// In en, this message translates to:
  /// **'⚡ {label}: {value} {trend}'**
  String analyticsStressLabel(String label, String value, String trend);

  /// No description provided for @analyticsImpactPositive.
  ///
  /// In en, this message translates to:
  /// **'🚀 +{minutes}m'**
  String analyticsImpactPositive(int minutes);

  /// No description provided for @analyticsImpactNegative.
  ///
  /// In en, this message translates to:
  /// **'📉 -{minutes}m'**
  String analyticsImpactNegative(int minutes);

  /// No description provided for @analyticsMoodPerformanceBadDesc.
  ///
  /// In en, this message translates to:
  /// **'Low mood is restricting your session efficiency.'**
  String get analyticsMoodPerformanceBadDesc;

  /// No description provided for @analyticsMoodPerformanceStableDesc.
  ///
  /// In en, this message translates to:
  /// **'Your mood is stable, allowing for consistent focus.'**
  String get analyticsMoodPerformanceStableDesc;

  /// No description provided for @analyticsMoodBetterMood.
  ///
  /// In en, this message translates to:
  /// **'Better Mood'**
  String get analyticsMoodBetterMood;

  /// No description provided for @analyticsMoodHighStress.
  ///
  /// In en, this message translates to:
  /// **'High Stress'**
  String get analyticsMoodHighStress;

  /// No description provided for @analyticsMoodFocusBoost.
  ///
  /// In en, this message translates to:
  /// **'Focus Boost'**
  String get analyticsMoodFocusBoost;

  /// No description provided for @analyticsMoodFocusDrain.
  ///
  /// In en, this message translates to:
  /// **'Focus Drain'**
  String get analyticsMoodFocusDrain;

  /// No description provided for @analyticsMoodDifference.
  ///
  /// In en, this message translates to:
  /// **'{plusMinus}{minutes}m'**
  String analyticsMoodDifference(Object minutes, Object plusMinus);

  /// No description provided for @burnoutMessageEmotionalRisk.
  ///
  /// In en, this message translates to:
  /// **'Emotional volatility detected in recent sessions. Prioritize mental health.'**
  String get burnoutMessageEmotionalRisk;

  /// No description provided for @decisionStatusModerateStress.
  ///
  /// In en, this message translates to:
  /// **'Moderate stress detected'**
  String get decisionStatusModerateStress;

  /// No description provided for @decisionStatusLowStress.
  ///
  /// In en, this message translates to:
  /// **'Low stress'**
  String get decisionStatusLowStress;

  /// No description provided for @decisionStatusHighStress.
  ///
  /// In en, this message translates to:
  /// **'High stress detected'**
  String get decisionStatusHighStress;

  /// No description provided for @predictionStressLikelyIncrease.
  ///
  /// In en, this message translates to:
  /// **'Stress likely to increase due to low recovery and rising pressure'**
  String get predictionStressLikelyIncrease;

  /// No description provided for @analyticsNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get analyticsNotEnoughData;

  /// No description provided for @decisionRisingStressUnstablePattern.
  ///
  /// In en, this message translates to:
  /// **'Your stress is rising while your routine is unstable'**
  String get decisionRisingStressUnstablePattern;

  /// No description provided for @decisionActionFixedScheduleFocus.
  ///
  /// In en, this message translates to:
  /// **'Study at the same time for 3 days to stabilize focus'**
  String get decisionActionFixedScheduleFocus;

  /// No description provided for @burnoutRisingStressInconsistentPattern.
  ///
  /// In en, this message translates to:
  /// **'Your stress is increasing while your study pattern is inconsistent'**
  String get burnoutRisingStressInconsistentPattern;

  /// No description provided for @predictionPressureLikelyToIncrease.
  ///
  /// In en, this message translates to:
  /// **'Study deficit: {hours}h'**
  String predictionPressureLikelyToIncrease(String hours);

  /// No description provided for @analyticsMoodCorrelationDetected.
  ///
  /// In en, this message translates to:
  /// **'Correlation detected'**
  String get analyticsMoodCorrelationDetected;

  /// No description provided for @analyticsMoodStudyDropped.
  ///
  /// In en, this message translates to:
  /// **'Study dropped by {percent}%'**
  String analyticsMoodStudyDropped(String percent);

  /// No description provided for @analyticsMoodMoodDropped.
  ///
  /// In en, this message translates to:
  /// **'Mood dropped by {percent}%'**
  String analyticsMoodMoodDropped(String percent);

  /// No description provided for @burnoutShortExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your study pattern looks balanced right now.'**
  String get burnoutShortExplanation;

  /// No description provided for @signalStressHigh.
  ///
  /// In en, this message translates to:
  /// **'High stress'**
  String get signalStressHigh;

  /// No description provided for @signalStressMedium.
  ///
  /// In en, this message translates to:
  /// **'Moderate stress'**
  String get signalStressMedium;

  /// No description provided for @signalMoodLow.
  ///
  /// In en, this message translates to:
  /// **'Low mood'**
  String get signalMoodLow;

  /// No description provided for @signalConsistencyLow.
  ///
  /// In en, this message translates to:
  /// **'Unstable routine'**
  String get signalConsistencyLow;

  /// No description provided for @signalDeficitHigh.
  ///
  /// In en, this message translates to:
  /// **'Study deficit'**
  String get signalDeficitHigh;

  /// No description provided for @consistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get consistency;

  /// No description provided for @stress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get stress;

  /// No description provided for @moodTrends.
  ///
  /// In en, this message translates to:
  /// **'Mood Trends'**
  String get moodTrends;

  /// No description provided for @studyProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Study Profile'**
  String get studyProfileTitle;

  /// No description provided for @studyProfileOptimalDuration.
  ///
  /// In en, this message translates to:
  /// **'Optimal Session: {min}-{max} min'**
  String studyProfileOptimalDuration(int min, int max);

  /// No description provided for @studyProfileStressThreshold.
  ///
  /// In en, this message translates to:
  /// **'Focus drops when stress > {value}'**
  String studyProfileStressThreshold(String value);

  /// No description provided for @studyProfilePeakWindow.
  ///
  /// In en, this message translates to:
  /// **'Peak Productivity: {window}'**
  String studyProfilePeakWindow(String window);

  /// No description provided for @studyProfileMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get studyProfileMorning;

  /// No description provided for @studyProfileAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get studyProfileAfternoon;

  /// No description provided for @studyProfileEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get studyProfileEvening;

  /// No description provided for @studyProfileMainFactor.
  ///
  /// In en, this message translates to:
  /// **'Main factor: {factor}'**
  String studyProfileMainFactor(String factor);

  /// No description provided for @studyProfileSecondaryFactor.
  ///
  /// In en, this message translates to:
  /// **'Secondary: {factor}'**
  String studyProfileSecondaryFactor(String factor);

  /// No description provided for @completion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get completion;

  /// No description provided for @moodEnergyLevel.
  ///
  /// In en, this message translates to:
  /// **'Energy Level'**
  String get moodEnergyLevel;

  /// No description provided for @moodLoggedSession.
  ///
  /// In en, this message translates to:
  /// **'Logged after study session'**
  String get moodLoggedSession;

  /// No description provided for @moodLoggedManual.
  ///
  /// In en, this message translates to:
  /// **'Logged manually'**
  String get moodLoggedManual;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @academic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get academic;

  /// No description provided for @dailyBaseline.
  ///
  /// In en, this message translates to:
  /// **'Daily Baseline'**
  String get dailyBaseline;

  /// No description provided for @studySessions.
  ///
  /// In en, this message translates to:
  /// **'Study Sessions'**
  String get studySessions;

  /// No description provided for @notificationOverdue.
  ///
  /// In en, this message translates to:
  /// **'is overdue'**
  String get notificationOverdue;

  /// No description provided for @notificationDueToday.
  ///
  /// In en, this message translates to:
  /// **'is due today'**
  String get notificationDueToday;

  /// No description provided for @notificationDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'is due tomorrow'**
  String get notificationDueTomorrow;

  /// No description provided for @notificationDueSoon.
  ///
  /// In en, this message translates to:
  /// **'is due soon'**
  String get notificationDueSoon;

  /// No description provided for @weeklyStudyGoalMissed.
  ///
  /// In en, this message translates to:
  /// **'Weekly study goal missed'**
  String get weeklyStudyGoalMissed;

  /// No description provided for @weeklyStudyGoalMissedMessage.
  ///
  /// In en, this message translates to:
  /// **'You studied {actual}h of {goal}h this week.'**
  String weeklyStudyGoalMissedMessage(Object actual, Object goal);

  /// No description provided for @decisionRisingStressTitle.
  ///
  /// In en, this message translates to:
  /// **'Rising Stress Levels'**
  String get decisionRisingStressTitle;

  /// No description provided for @decisionStatusDeficit.
  ///
  /// In en, this message translates to:
  /// **'Large study deficit'**
  String get decisionStatusDeficit;

  /// No description provided for @decisionStatusInconsistent.
  ///
  /// In en, this message translates to:
  /// **'Inconsistency detected'**
  String get decisionStatusInconsistent;

  /// No description provided for @baseline.
  ///
  /// In en, this message translates to:
  /// **'Baseline'**
  String get baseline;

  /// No description provided for @predictionCollectingData.
  ///
  /// In en, this message translates to:
  /// **'Collecting Data'**
  String get predictionCollectingData;

  /// No description provided for @predictionCollectingDataDetail.
  ///
  /// In en, this message translates to:
  /// **'Studying 5 or more sessions will activate full AI insights.'**
  String get predictionCollectingDataDetail;

  /// No description provided for @decisionRecommendedSession.
  ///
  /// In en, this message translates to:
  /// **'Recommended: {minutes} min'**
  String decisionRecommendedSession(int minutes);

  /// No description provided for @moodTerrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get moodTerrible;

  /// No description provided for @moodBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get moodBad;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodAmazing.
  ///
  /// In en, this message translates to:
  /// **'Amazing'**
  String get moodAmazing;

  /// No description provided for @moodUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get moodUnknown;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get hideDetails;

  /// No description provided for @viewFullAnalysis.
  ///
  /// In en, this message translates to:
  /// **'View full analysis'**
  String get viewFullAnalysis;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @selectedSemester.
  ///
  /// In en, this message translates to:
  /// **'Selected Semester'**
  String get selectedSemester;

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesValue(int minutes);

  /// No description provided for @minutesCourseValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {course}'**
  String minutesCourseValue(int minutes, String course);

  /// No description provided for @smartAiInsights.
  ///
  /// In en, this message translates to:
  /// **'Smart AI Insights'**
  String get smartAiInsights;

  /// No description provided for @burnoutExplanationFallingBehind.
  ///
  /// In en, this message translates to:
  /// **'You are showing signs of mental fatigue and irregular study habits.'**
  String get burnoutExplanationFallingBehind;

  /// No description provided for @burnoutBehaviorHighFatigue.
  ///
  /// In en, this message translates to:
  /// **'Elevated mental fatigue levels detected.'**
  String get burnoutBehaviorHighFatigue;

  /// No description provided for @burnoutBehaviorMoodInstability.
  ///
  /// In en, this message translates to:
  /// **'Increasing mood variability impacting focus.'**
  String get burnoutBehaviorMoodInstability;

  /// No description provided for @burnoutBehaviorIrregularRest.
  ///
  /// In en, this message translates to:
  /// **'Inconsistent rest periods between sessions.'**
  String get burnoutBehaviorIrregularRest;

  /// No description provided for @burnoutBehaviorUnpredictableRhythm.
  ///
  /// In en, this message translates to:
  /// **'Unpredictable study rhythm and timing.'**
  String get burnoutBehaviorUnpredictableRhythm;

  /// No description provided for @burnoutBehaviorSwitchingContext.
  ///
  /// In en, this message translates to:
  /// **'Frequent context switching affecting deep focus.'**
  String get burnoutBehaviorSwitchingContext;

  /// No description provided for @burnoutBehaviorMentalOverload.
  ///
  /// In en, this message translates to:
  /// **'Cognitive load exceeding typical recovery rates.'**
  String get burnoutBehaviorMentalOverload;

  /// No description provided for @consistencyPercentage.
  ///
  /// In en, this message translates to:
  /// **'Consistency: {score}%'**
  String consistencyPercentage(Object score);

  /// No description provided for @labelWithColon.
  ///
  /// In en, this message translates to:
  /// **'{label}:'**
  String labelWithColon(Object label);

  /// No description provided for @labelWithColonAndSpace.
  ///
  /// In en, this message translates to:
  /// **'{label}: '**
  String labelWithColonAndSpace(Object label);
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
