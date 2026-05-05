import 'package:heroicons/heroicons.dart';

import '../../l10n/app_localizations.dart';

/// Shared shortcuts for the home quick strip and the "All" bottom sheet.
/// Keep routes aligned with [GoRouter] in `main.dart`.
class QuickMenuNavItem {
  const QuickMenuNavItem({
    required this.icon,
    required this.title,
    required this.route,
  });

  final HeroIcons icon;
  final String title;
  final String route;
}

List<QuickMenuNavItem> buildQuickMenuNavItems(AppLocalizations l10n) {
  return <QuickMenuNavItem>[
    QuickMenuNavItem(
      icon: HeroIcons.academicCap,
      title: l10n.myCourses,
      route: '/courses',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.rectangleStack,
      title: l10n.tasks,
      route: '/tasks',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.clipboardDocumentList,
      title: l10n.examsTitle,
      route: '/exams',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.documentPlus,
      title: l10n.examsAddCta,
      route: '/create-exam',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.calendarDays,
      title: l10n.examsCalendarTitle,
      route: '/exams-calendar',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.chartBar,
      title: l10n.examResults,
      route: '/course-results',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.calendar,
      title: l10n.manageSemesters,
      route: '/semesters',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.bookOpen,
      title: l10n.academicHistory,
      route: '/academic-history',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.plusCircle,
      title: l10n.addCourse,
      route: '/create-course',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.checkCircle,
      title: l10n.createTask,
      route: '/create-task',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.clock,
      title: l10n.createDeadline,
      route: '/create-deadline',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.faceSmile,
      title: l10n.logMoodTitle,
      route: '/mood/log',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.clock,
      title: l10n.moodHistoryTitle,
      route: '/mood/history',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.bell,
      title: l10n.notifications,
      route: '/notifications',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.userCircle,
      title: l10n.editProfile,
      route: '/profile/edit',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.adjustmentsHorizontal,
      title: l10n.studyPreferences,
      route: '/profile/study-preferences',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.cog6Tooth,
      title: l10n.moodSettingsTitle,
      route: '/settings/mood-stress',
    ),
    QuickMenuNavItem(
      icon: HeroIcons.lockClosed,
      title: l10n.changePassword,
      route: '/profile/change-password',
    ),
  ];
}
