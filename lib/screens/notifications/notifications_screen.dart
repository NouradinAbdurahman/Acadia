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
import '../../providers/notifications_provider.dart';
import '../../providers/bottom_nav_provider.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_back_button.dart';
import '../../core/theme/app_colors.dart';

enum _NotificationGroup {
  today,
  tomorrow,
  earlier,
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    await ref.read(notificationsProvider.notifier).loadNotifications();
  }

  _NotificationGroup _groupForNotification(dynamic notification) {
    switch (notification.type) {
      case 'due_today':
        return _NotificationGroup.today;
      case 'due_tomorrow':
        return _NotificationGroup.tomorrow;
      case 'overdue':
      case 'task_overdue':
        return _NotificationGroup.earlier;
      default:
        return _NotificationGroup.today;
    }
  }

  String _groupTitle(AppLocalizations l10n, _NotificationGroup group) {
    switch (group) {
      case _NotificationGroup.today:
        return l10n.today;
      case _NotificationGroup.tomorrow:
        return l10n.tomorrow;
      case _NotificationGroup.earlier:
        return l10n.earlier;
    }
  }

  HeroIcons _iconForType(String type) {
    switch (type) {
      case 'overdue':
      case 'task_overdue':
        return HeroIcons.exclamationTriangle;
      default:
        return HeroIcons.calendarDays;
    }
  }

  Color _statusColor(String type, ThemeData theme) {
    switch (type) {
      case 'overdue':
      case 'task_overdue':
        return AppColors.error;
      case 'due_tomorrow':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _extractCourseName(String message) {
    final parts = message.split(' • ');
    if (parts.isEmpty) return '';
    return parts.first.trim();
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    dynamic notification,
  ) async {
    Haptics.vibrate(HapticsType.selection);
    await ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    if (!context.mounted) return;

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

    if (notification.type == 'study_goal') {
      ref.read(bottomNavProvider.notifier).state = 2;
      context.go('/home');
      return;
    }

    context.push('/tasks');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsProvider);
    final courses = ref.watch(courseProvider).value ?? [];
    final courseColorByName = <String, Color>{
      for (final course in courses) course.courseName: course.uiColor,
    };

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text(l10n.notifications),
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _onRefresh(ref),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(
                              HeroIcons.checkCircle,
                              size: 64,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.notificationsCaughtUp,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final grouped = <_NotificationGroup, List<dynamic>>{
              _NotificationGroup.today: [],
              _NotificationGroup.tomorrow: [],
              _NotificationGroup.earlier: [],
            };

            for (final notification in notifications) {
              grouped[_groupForNotification(notification)]!.add(notification);
            }

            final orderedGroups = [
              _NotificationGroup.today,
              _NotificationGroup.tomorrow,
              _NotificationGroup.earlier,
            ];

            return RefreshIndicator(
              onRefresh: () => _onRefresh(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  for (final group in orderedGroups)
                    if (grouped[group]!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          _groupTitle(l10n, group),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      for (var i = 0; i < grouped[group]!.length; i++) ...[
                        Builder(
                          builder: (context) {
                            final n = grouped[group]![i];
                            final statusColor = _statusColor(n.type, theme);
                            final isOverdue =
                                n.type == 'overdue' || n.type == 'task_overdue';
                            final courseName = _extractCourseName(n.message);
                            final courseColor = courseColorByName[courseName];
                            final identityColor =
                                courseColor ?? theme.colorScheme.outline.withValues(alpha: 0.45);

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _handleNotificationTap(context, ref, n),
                              child: AppGlassCard(
                                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: isOverdue
                                        ? AppColors.error.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isOverdue
                                          ? AppColors.error.withValues(alpha: 0.2)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: identityColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.14),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: AppIcon(
                                                  _iconForType(n.type),
                                                  size: 16,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.md),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    n.title,
                                                    style: theme.textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                      color: n.isRead
                                                          ? theme.colorScheme.onSurface.withValues(alpha: 0.75)
                                                          : (isOverdue
                                                              ? AppColors.error
                                                              : theme.colorScheme.onSurface),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    n.message,
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
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
                                .animate(delay: Duration(milliseconds: i * 45))
                                .fade(duration: AppDurations.fast)
                                .slideY(begin: 0.05);
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                    ],
                ],
              ).animate().fade(duration: AppDurations.slow),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(l10n.networkError),
          ),
          ),
        ),
      ),
    );
  }
}
