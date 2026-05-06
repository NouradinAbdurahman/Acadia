import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../core/design/app_icons.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/course_provider.dart';
import '../../providers/exams_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/bottom_nav_provider.dart';
import '../../providers/mood_provider.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_back_button.dart';
import '../../core/theme/app_colors.dart';
import '../../models/notification.dart';

enum _NotificationGroup {
  today,
  upcoming,
  past,
}

enum _NotificationCategory {
  all,
  tasks,
  deadlines,
  exams,
  mood,
  academic,
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _NotificationCategory _selectedCategory = _NotificationCategory.all;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    // Add hysteresis to prevent rapid top-edge toggling (flicker),
    // especially visible in light mode during bounce/overscroll.
    const showThreshold = 12.0;
    const hideThreshold = 4.0;
    final offset = _scrollController.offset;

    final next = _isScrolled
        ? offset > hideThreshold
        : offset > showThreshold;

    if (next != _isScrolled && mounted) {
      setState(() => _isScrolled = next);
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(notificationsProvider.notifier).loadNotifications();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  _NotificationGroup _groupForNotification(
    NotificationModel notification, {
    required DateTime now,
    required Map<String, DateTime> examTimeByRef,
  }) {
    if (notification.type == 'exam') {
      final refId = notification.referenceId ?? '';
      final examTime = examTimeByRef[refId];
      if (examTime != null) {
        if (_isSameDay(examTime, now)) return _NotificationGroup.today;
        if (examTime.isAfter(now)) return _NotificationGroup.upcoming;
        return _NotificationGroup.past;
      }
    }

    switch (notification.type) {
      case 'due_today':
      case 'risk':
      case 'stress':
      case 'academic_summary':
      case 'study_goal':
      case 'mood':
      case 'mood_check':
        return _NotificationGroup.today;
      case 'due_tomorrow':
        return _NotificationGroup.upcoming;
      case 'overdue':
      case 'overdue_batch':
      case 'task_overdue':
        return _NotificationGroup.past;
      default:
        return _NotificationGroup.today;
    }
  }

  String _groupTitle(AppLocalizations l10n, _NotificationGroup group) {
    switch (group) {
      case _NotificationGroup.today:
        return l10n.today;
      case _NotificationGroup.upcoming:
        return l10n.examsUpcomingSectionTitle;
      case _NotificationGroup.past:
        return l10n.examsPastSectionTitle;
    }
  }

  HeroIcons _iconForType(String type) {
    switch (type) {
      case 'overdue':
      case 'overdue_batch':
      case 'task_overdue':
        return HeroIcons.exclamationTriangle;
      case 'risk':
        return HeroIcons.shieldExclamation;
      case 'stress':
        return HeroIcons.fire;
      case 'academic_summary':
        return HeroIcons.academicCap;
      case 'mood':
      case 'mood_check':
        return HeroIcons.faceSmile;
      case 'study_goal':
        return HeroIcons.trophy;
      case 'exam':
        return HeroIcons.academicCap;
      case 'deadline':
      case 'deadline_batch':
      case 'due_today':
      case 'due_tomorrow':
        return HeroIcons.calendarDays;
      default:
        return HeroIcons.bellAlert;
    }
  }

  Color _statusColor(String type, ThemeData theme) {
    switch (type) {
      case 'overdue':
      case 'overdue_batch':
      case 'task_overdue':
      case 'risk':
        return AppColors.error;
      case 'stress':
        return Colors.deepOrange;
      case 'due_today':
        return theme.colorScheme.primary;
      case 'due_tomorrow':
        return theme.colorScheme.secondary;
      case 'exam':
        return Colors.indigo;
      case 'mood':
      case 'mood_check':
        return Colors.orange;
      case 'study_goal':
        return Colors.amber;
      case 'academic_summary':
        return Colors.teal;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _extractCourseName(String message) {
    final parts = message.split(' • ');
    if (parts.isEmpty) return '';
    return parts.first.trim();
  }

  bool _matchesCategory(NotificationModel n, _NotificationCategory category) {
    if (category == _NotificationCategory.all) return true;

    final refId = n.referenceId ?? '';
    final type = n.type;

    switch (category) {
      case _NotificationCategory.tasks:
        return refId.startsWith('task:') || type == 'task_overdue';
      case _NotificationCategory.deadlines:
        return refId.startsWith('deadline:') ||
            type == 'deadline' ||
            type == 'deadline_batch';
      case _NotificationCategory.exams:
        return type == 'exam' || refId.startsWith('exam:');
      case _NotificationCategory.mood:
        return type == 'mood' ||
            type == 'mood_check' ||
            type == 'stress';
      case _NotificationCategory.academic:
        return type == 'risk' ||
            type == 'academic_summary' ||
            type == 'study_goal' ||
            type == 'due_today' ||
            type == 'due_tomorrow' ||
            type == 'overdue' ||
            type == 'task_overdue' ||
            type == 'deadline' ||
            type == 'deadline_batch' ||
            type == 'overdue_batch' ||
            type == 'system';
      default:
        return true;
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    Haptics.vibrate(HapticsType.selection);
    await ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    if (!mounted) return;

    final referenceId = notification.referenceId?.toString();
    if (referenceId != null && referenceId.startsWith('task:')) {
      final taskId = referenceId.substring(5);
      context.push('/task-detail?id=${Uri.encodeComponent(taskId)}');
      return;
    }

    if (referenceId != null && referenceId.startsWith('deadline:')) {
      final deadlineId = referenceId.substring(9);
      context.push('/deadline-detail?id=${Uri.encodeComponent(deadlineId)}');
      return;
    }

    if (referenceId != null && referenceId.startsWith('exam:')) {
      final examId = referenceId.substring(5);
      context.push('/exam-detail?id=${Uri.encodeComponent(examId)}');
      return;
    }

    switch (notification.type) {
      case 'due_today':
      case 'due_tomorrow':
      case 'overdue':
      case 'task_overdue':
      case 'deadline':
      case 'deadline_batch':
      case 'overdue_batch':
        context.push('/tasks');
        return;
      case 'exam':
        context.push('/exams');
        return;
      case 'risk':
      case 'academic_summary':
      case 'study_goal':
        ref.read(bottomNavProvider.notifier).state = 0;
        context.go('/home');
        return;
      case 'mood':
      case 'mood_check':
        final hasTodayMood = await ref.read(todayMoodProvider.future);
        if (!mounted) return;
        if (!hasTodayMood) {
          context.push('/mood/log?source=notification');
          return;
        }
        context.push('/mood/history');
        return;
      case 'stress':
        ref.read(bottomNavProvider.notifier).state = 0;
        context.go('/home');
        return;
      default:
        context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final topChromeColor = theme.brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : theme.colorScheme.surface;
    final notificationsAsync = ref.watch(notificationsProvider);
    final courses = ref.watch(courseProvider).value ?? [];
    final exams = ref.watch(examsProvider).value ?? [];
    final courseColorByName = <String, Color>{
      for (final course in courses) course.courseName: course.uiColor,
    };
    final examTimeByRef = <String, DateTime>{
      for (final exam in exams) 'exam:${exam.id}': exam.examDateTime,
    };

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.notifications),
        backgroundColor: topChromeColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildCategoryTabs(l10n, theme, topChromeColor),
              Expanded(
                child: notificationsAsync.when(
                  data: (notifications) {
                    final filtered = notifications.where((n) => _matchesCategory(n, _selectedCategory)).toList();
                    
                    if (filtered.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AppIcon(
                                      _emptyStateIconForCategory(),
                                      size: 64,
                                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      _emptyStateTitleForCategory(l10n),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final grouped = <_NotificationGroup, List<NotificationModel>>{
                      _NotificationGroup.today: [],
                      _NotificationGroup.upcoming: [],
                      _NotificationGroup.past: [],
                    };

                    final now = DateTime.now();
                    for (final notification in filtered) {
                      grouped[_groupForNotification(
                        notification,
                        now: now,
                        examTimeByRef: examTimeByRef,
                      )]!.add(notification);
                    }

                    final orderedGroups = [
                      _NotificationGroup.today,
                      _NotificationGroup.upcoming,
                      _NotificationGroup.past,
                    ];

                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        children: [
                          for (final group in orderedGroups)
                            if (grouped[group]!.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
                                child: Text(
                                  _groupTitle(l10n, group),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              for (var i = 0; i < grouped[group]!.length; i++) ...[
                                _buildNotificationCard(grouped[group]![i], theme, courseColorByName),
                              ],
                              const SizedBox(height: AppSpacing.md),
                            ],
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Text(l10n.networkError),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(
    AppLocalizations l10n,
    ThemeData theme,
    Color topChromeColor,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    Widget catChip(_NotificationCategory category, String label) {
      final selected = _selectedCategory == category;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          elevation: 0,
          onSelected: (val) {
            if (val) {
              Haptics.vibrate(HapticsType.selection);
              setState(() => _selectedCategory = category);
            }
          },
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: selected
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.6 : 0.85),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
          selectedColor: theme.colorScheme.primary,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.primary
                  : (isDark
                      ? Colors.transparent
                      : theme.colorScheme.outline.withValues(alpha: 0.35)),
              width: 1,
            ),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: AppDurations.fast,
      height: 84,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: topChromeColor,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.only(left: AppSpacing.md),
        children: [
          catChip(_NotificationCategory.all, l10n.all),
          catChip(_NotificationCategory.tasks, l10n.tasks),
          catChip(_NotificationCategory.deadlines, l10n.deadlines),
          catChip(_NotificationCategory.exams, l10n.examsTitle),
          catChip(_NotificationCategory.mood, l10n.mood),
          catChip(_NotificationCategory.academic, l10n.academic),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }

  HeroIcons _emptyStateIconForCategory() {
    switch (_selectedCategory) {
      case _NotificationCategory.mood:
        return HeroIcons.faceSmile;
      case _NotificationCategory.academic:
        return HeroIcons.academicCap;
      default:
        return HeroIcons.checkCircle;
    }
  }

  String _emptyStateTitleForCategory(AppLocalizations l10n) {
    switch (_selectedCategory) {
      case _NotificationCategory.mood:
        return l10n.noMoodNotificationsYet;
      case _NotificationCategory.academic:
        return l10n.noAcademicNotificationsYet;
      default:
        return l10n.notificationsCaughtUp;
    }
  }

  Widget _buildNotificationCard(NotificationModel n, ThemeData theme, Map<String, Color> courseColorByName) {
    final isLight = theme.brightness == Brightness.light;
    final statusColor = _statusColor(n.type, theme);
    final isOverdue = n.type == 'overdue' || n.type == 'task_overdue';
    final courseName = _extractCourseName(n.message);
    final courseColor = courseColorByName[courseName];
    final identityColor = courseColor ?? theme.colorScheme.outline.withValues(alpha: 0.45);
    final isUnread = !n.isRead;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleNotificationTap(n),
      child: AppGlassCard(
        borderOnly: true,
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Opacity(
          opacity: isUnread ? 1.0 : (isLight ? 0.9 : 0.72),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identity bar
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: identityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Circle
                    Stack(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: AppIcon(
                              _iconForType(n.type),
                              size: 18,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.cardColor, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                    color: isOverdue
                                        ? (isLight ? const Color(0xFFB42318) : AppColors.error)
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: isUnread
                                    ? (isLight ? 0.92 : 0.8)
                                    : (isLight ? 0.75 : 0.6),
                              ),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
    .animate()
    .fade(duration: AppDurations.fast)
    .slideY(begin: 0.05);
  }
}
