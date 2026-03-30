import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../components/app_glass_card.dart';
import '../../providers/study_sessions_provider.dart';
import '../../models/study_session.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../l10n/app_localizations.dart';

class StudyHistoryScreen extends ConsumerWidget {
  const StudyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sessionsAsync = ref.watch(studySessionsProvider);

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme, l10n),
              Expanded(
                child: sessionsAsync.when(
                  data: (sessions) => sessions.isEmpty
                      ? _buildEmptyState(theme, l10n)
                      : _buildSessionList(context, theme, sessions, l10n),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          IconButton(
            icon: AppIcon(
              HeroIcons.chevronLeft,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.recentStudySessions,
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(HeroIcons.clock, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.noStudySessionsYet,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    ThemeData theme,
    List<StudySession> sessions,
    AppLocalizations l10n,
  ) {
    // Grouping by date
    final now = DateTime.now();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<StudySession>> grouped = {};
    for (var session in sessions) {
      final date = DateTime(session.createdAt.year, session.createdAt.month, session.createdAt.day);
      String key;
      if (date == today) {
        key = l10n.today;
      } else if (date == yesterday) {
        key = l10n.yesterday;
      } else {
        key = DateFormat('MMMM dd, yyyy', localeTag).format(date);
      }
      grouped.putIfAbsent(key, () => []).add(session);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final key = grouped.keys.elementAt(index);
        final daySessions = grouped[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                key,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ...daySessions.map((s) => _buildSessionItem(context, theme, s, l10n)),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

  Widget _buildSessionItem(
    BuildContext context,
    ThemeData theme,
    StudySession session,
    AppLocalizations l10n,
  ) {
    final color = session.course?.uiColor ?? theme.colorScheme.primary;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.course?.courseName ?? l10n.course,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatSessionType(l10n, session.sessionType),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${session.durationMinutes} ${l10n.minutesAbbreviation}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM d, HH:mm', localeTag).format(session.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSessionType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'pomodoro': return l10n.pomodoro;
      case 'deep_work': return l10n.deepWork;
      case 'review': return l10n.review;
      default: return type;
    }
  }
}
