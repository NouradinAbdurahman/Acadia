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
import '../../providers/analytics_provider.dart';
import 'session_detail_screen.dart';

class StudyHistoryScreen extends ConsumerWidget {
  const StudyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sessionsAsync = ref.watch(studySessionsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      primary: false,
      body: AuthBackgroundContainer(
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme, l10n),
              Expanded(
                child: sessionsAsync.when(
                  data: (sessions) => sessions.isEmpty
                      ? _buildEmptyState(theme, l10n)
                      : _buildSessionList(context, theme, ref, sessions, l10n),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text(l10n.errorLoading(err.toString()))),
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
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, MediaQuery.of(context).padding.top + 8, AppSpacing.lg, AppSpacing.lg),
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
    WidgetRef ref,
    List<StudySession> sessions,
    AppLocalizations l10n,
  ) {
    // Grouping by date
    final now = DateTime.now();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Filter out invalid/short sessions and degenerate Pomodoro records (0 cycles, 0 focus)
    final validSessions = sessions.where((s) {
      if (s.isPomodoro) {
        return (s.cyclesCompleted ?? 0) > 0 && (s.totalFocusMinutes ?? s.durationMinutes) > 0;
      }
      return s.durationMinutes >= 10;
    }).toList();
    if (validSessions.isEmpty) return _buildEmptyState(theme, l10n);

    final analytics = ref.watch(studyAnalyticsProvider);

    final Map<String, List<StudySession>> grouped = {};
    for (var session in validSessions) {
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
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              child: Text(
                key,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            ...daySessions.map(
              (s) => _buildSessionItem(context, theme, s, l10n, analytics),
            ),
            const SizedBox(height: AppSpacing.sm),
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
    StudyAnalytics analytics,
  ) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    
    Color _getSessionColor(StudySession session) {
      if (session.course?.color != null) {
        return session.course!.uiColor;
      }
      switch (session.sessionType) {
        case 'pomodoro': return Colors.orange;
        case 'deep_work': return Colors.blue;
        case 'review': return Colors.green;
        default: return theme.colorScheme.primary;
      }
    }

    final color = _getSessionColor(session);
    final timeFormatted = DateFormat('HH:mm', localeTag).format(session.createdAt);
    final courseName = _toReadableCourseName(
      session.course?.courseName ?? l10n.course,
    );
    final durationLabel = _formatDurationHuman(session.durationMinutes);
    final sessionTypeStr = _formatSessionType(l10n, session.sessionType);
    final focusLabel = analytics.getFocusLabel(session.durationMinutes, l10n);
    final insight = analytics.getInsight(session, l10n).trim();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session),
            ),
          );
        },
        child: AppGlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      courseName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sessionTypeStr • $durationLabel • $timeFormatted',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          focusLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                          ),
                        ),
                        if (session.completed) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppIcon(
                                  HeroIcons.check,
                                  color: Colors.greenAccent,
                                  size: 12,
                                  solid: true,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.statusCompleted,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (insight.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '"$insight"',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSessionType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'pomodoro':
        return l10n.pomodoro;
      case 'deep_work':
        return l10n.deepWork;
      case 'review':
        return l10n.review;
      default:
        return type;
    }
  }

  String _formatDurationHuman(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (rem == 0) return '${hours}h';
    return '${hours}h ${rem}m';
  }

  String _toReadableCourseName(String value) {
    final normalized = value
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return value;

    final words = normalized.split(' ');
    const lowerWords = {'and', 'or', 'of', 'the', 'in', 'to', 'for'};
    final formatted = <String>[];

    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      final lower = w.toLowerCase();
      final isAllCaps = w == w.toUpperCase() && RegExp(r'^[A-Z0-9]+$').hasMatch(w);

      if (isAllCaps) {
        formatted.add(w);
      } else if (i > 0 && lowerWords.contains(lower)) {
        formatted.add(lower);
      } else {
        formatted.add(lower[0].toUpperCase() + lower.substring(1));
      }
    }
    return formatted.join(' ');
  }
}
