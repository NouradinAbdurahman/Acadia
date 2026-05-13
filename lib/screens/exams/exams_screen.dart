import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';

import '../../components/app_back_button.dart';
import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exam.dart';
import '../../providers/exams_provider.dart';
import '../../utils/exam_ui_utils.dart';
import '../../widgets/auth/auth_background_container.dart';

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> {
  ExamType? _selectedFilter;

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Splits [upcoming] (sorted ascending) into the four time buckets.
  /// Returns a map with keys: 'today', 'week', 'month', 'later'.
  Map<String, List<ExamModel>> _groupUpcoming(List<ExamModel> upcoming) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Sunday of the current week
    final endOfWeek = today.add(Duration(days: DateTime.sunday - today.weekday + (today.weekday == DateTime.sunday ? 0 : 0)));
    // Last day of the current month
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final result = <String, List<ExamModel>>{
      'today': [],
      'week': [],
      'month': [],
      'later': [],
    };

    for (final exam in upcoming) {
      final d = DateTime(exam.examDateTime.year, exam.examDateTime.month, exam.examDateTime.day);
      if (d == today) {
        result['today']!.add(exam);
      } else if (!d.isAfter(endOfWeek)) {
        result['week']!.add(exam);
      } else if (!d.isAfter(endOfMonth)) {
        result['month']!.add(exam);
      } else {
        result['later']!.add(exam);
      }
    }

    return result;
  }

  String _formatDateTime(DateTime value, Locale locale, AppLocalizations l10n) {
    final localeTag = locale.toLanguageTag();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final date = DateFormat('EEE, MMM d', localeTag).format(value);
    final time = DateFormat('HH:mm', localeTag).format(value);
    if (_isSameDate(value, now)) return '${l10n.today} · $time';
    if (_isSameDate(value, tomorrow)) return '${l10n.tomorrow} · $time';
    return '$date · $time';
  }

  String _typeLabel(AppLocalizations l10n, ExamType type) {
    switch (type) {
      case ExamType.midterm:
        return l10n.examsTypeMidterm;
      case ExamType.finalExam:
        return l10n.examsTypeFinal;
      case ExamType.quiz:
        return l10n.examsTypeQuiz;
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final examsAsync = ref.watch(examsProvider);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.examsTitle),
        actions: [
          IconButton(
            tooltip: l10n.examsCalendarOpenTooltip,
            icon: AppIcon(HeroIcons.calendarDays),
            onPressed: () => context.push('/exams-calendar'),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => ref.read(examsProvider.notifier).refresh(),
            child: examsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text(l10n.examsLoadError)),
              data: (exams) {
                final filteredExams = exams.where((exam) {
                  if (_selectedFilter == null) return true;
                  return exam.typeEnum == _selectedFilter;
                }).toList();
                final now = DateTime.now();
                final upcoming = filteredExams
                    .where((e) => !e.examDateTime.isBefore(now))
                    .toList()
                  ..sort((a, b) => a.examDateTime.compareTo(b.examDateTime));
                final past = filteredExams
                    .where((e) => e.examDateTime.isBefore(now))
                    .toList()
                  ..sort((a, b) => b.examDateTime.compareTo(a.examDateTime));

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    // Compact add button row
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            onPressed: () => context.push('/create-exam'),
                            text: l10n.examsAddCta,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _SectionLabel(title: l10n.examsUpcomingSectionTitle),
                    const SizedBox(height: 8),
                    _ExamTypeTabs(
                      selectedFilter: _selectedFilter,
                      onChanged: (value) => setState(() => _selectedFilter = value),
                      allLabel: l10n.all,
                      midtermLabel: l10n.examsTypeMidterm,
                      finalLabel: l10n.examsTypeFinal,
                      quizLabel: l10n.examsTypeQuiz,
                    ),
                    const SizedBox(height: 10),
                    if (upcoming.isEmpty)
                      _EmptySection(
                        message: _selectedFilter == null
                            ? l10n.examsNoUpcoming
                            : l10n.examsNoItems,
                        subtitle: l10n.examsNoUpcomingSubtitle,
                        actionLabel: l10n.examsAddCta,
                        onAction: () => context.push('/create-exam'),
                      )
                    else ...[
                      ...() {
                        final groups = _groupUpcoming(upcoming);
                        final buckets = [
                          (l10n.examsGroupToday, groups['today']!),
                          (l10n.examsGroupThisWeek, groups['week']!),
                          (l10n.examsGroupThisMonth, groups['month']!),
                          (l10n.examsGroupLater, groups['later']!),
                        ];
                        final widgets = <Widget>[];
                        for (final (label, items) in buckets) {
                          if (items.isEmpty) continue;
                          widgets.add(_GroupLabel(title: label));
                          widgets.add(const SizedBox(height: 6));
                          for (final exam in items) {
                            widgets.add(_ExamCard(
                              exam: exam,
                              typeLabel: _typeLabel(l10n, exam.typeEnum),
                              subtitleDate: _formatDateTime(exam.examDateTime, locale, l10n),
                              onTap: () => context.push(
                                  '/exam-detail?id=${Uri.encodeComponent(exam.id)}'),
                            ));
                          }
                          widgets.add(const SizedBox(height: 12));
                        }
                        return widgets;
                      }(),
                    ],

                    const SizedBox(height: 20),
                    _SectionLabel(title: l10n.examsPastSectionTitle),
                    const SizedBox(height: 10),
                    if (past.isEmpty)
                      _EmptySection(
                        message: _selectedFilter == null
                            ? l10n.examsNoPast
                            : l10n.examsNoItems,
                      )
                    else
                      ...past.map(
                        (exam) => _ExamCard(
                          exam: exam,
                          typeLabel: _typeLabel(l10n, exam.typeEnum),
                          subtitleDate: _formatDateTime(exam.examDateTime, locale, l10n),
                          onTap: () => context.push(
                              '/exam-detail?id=${Uri.encodeComponent(exam.id)}'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Compact section label ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        color: Colors.blueAccent,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ─── Group label (sub-heading inside upcoming) ────────────────────────────────

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─── Compact filter pills ─────────────────────────────────────────────────────

class _ExamTypeTabs extends StatelessWidget {
  const _ExamTypeTabs({
    required this.selectedFilter,
    required this.onChanged,
    required this.allLabel,
    required this.midtermLabel,
    required this.finalLabel,
    required this.quizLabel,
  });

  final ExamType? selectedFilter;
  final ValueChanged<ExamType?> onChanged;
  final String allLabel;
  final String midtermLabel;
  final String finalLabel;
  final String quizLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget tab({required String label, required bool selected, required VoidCallback onTap}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Haptics.vibrate(HapticsType.selection);
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : theme.colorScheme.outline.withValues(alpha: 0.25)),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurface
                          .withValues(alpha: isDark ? 0.65 : 0.8),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: Row(
        children: [
          tab(label: allLabel, selected: selectedFilter == null, onTap: () => onChanged(null)),
          tab(label: midtermLabel, selected: selectedFilter == ExamType.midterm, onTap: () => onChanged(ExamType.midterm)),
          tab(label: finalLabel, selected: selectedFilter == ExamType.finalExam, onTap: () => onChanged(ExamType.finalExam)),
          tab(label: quizLabel, selected: selectedFilter == ExamType.quiz, onTap: () => onChanged(ExamType.quiz)),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: AppButton(
                onPressed: onAction,
                text: actionLabel!,
                variant: AppButtonVariant.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Exam card ────────────────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.typeLabel,
    required this.subtitleDate,
    required this.onTap,
  });

  final ExamModel exam;
  final String typeLabel;
  final String subtitleDate;
  final VoidCallback onTap;

  String _prettyClassroom(String raw) => raw.trim().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = getExamTypeColor(exam.typeEnum);
    final hasClassroom =
        exam.classroom != null && exam.classroom!.trim().isNotEmpty;
    final hasInstructor =
        exam.instructorName != null && exam.instructorName!.trim().isNotEmpty;
    final hasCourse =
        exam.courseName != null && exam.courseName!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AppGlassCard(
            borderOnly: true,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row + type badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        exam.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: typeColor.withValues(alpha: 0.35), width: 1),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: typeColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Date + countdown inline
                Row(
                  children: [
                    AppIcon(
                      HeroIcons.clock,
                      size: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitleDate,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<int>(
                      stream: Stream.periodic(
                          const Duration(minutes: 1), (count) => count),
                      builder: (context2, snap) {
                        final countdown = getCountdownText(exam.examDateTime,
                            completedLabel: l10n.completed);
                        return Text(
                          countdown,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.withValues(alpha: 0.9),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Meta info row
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                      icon: exam.isOnline
                          ? HeroIcons.globeAlt
                          : HeroIcons.buildingOffice2,
                      label: exam.isOnline
                          ? l10n.examsLocationOnline
                          : l10n.examsLocationFaceToFace,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.45),
                    ),
                    if (!exam.isOnline && hasClassroom)
                      _MetaChip(
                        icon: HeroIcons.mapPin,
                        label:
                            '${l10n.examsLocationClassroomPrefix} ${_prettyClassroom(exam.classroom!)}',
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.45),
                      ),
                    if (hasInstructor)
                      _MetaChip(
                        icon: HeroIcons.userCircle,
                        label: exam.instructorName!.trim(),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.45),
                      ),
                    if (hasCourse)
                      _MetaChip(
                        icon: HeroIcons.bookOpen,
                        label: exam.courseName!.trim(),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.45),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}


class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final HeroIcons icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

