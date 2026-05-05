import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';

import '../../components/app_back_button.dart';
import '../../components/app_button.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_spacing.dart';
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

  String _formatDateTime(DateTime value, Locale locale, AppLocalizations l10n) {
    final localeTag = locale.toLanguageTag();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final date = DateFormat('EEE, MMM d', localeTag).format(value);
    final time = DateFormat('HH:mm', localeTag).format(value);
    if (_isSameDate(value, now)) return '${l10n.today} • $time';
    if (_isSameDate(value, tomorrow)) return '${l10n.tomorrow} • $time';
    return '$date • $time';
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

  Future<void> _confirmDeleteExam(BuildContext context, ExamModel exam) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const HeroIcon(
                                HeroIcons.exclamationTriangle,
                                color: Color(0xFFEF4444),
                                size: 36,
                                style: HeroIconStyle.solid,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.examDetailDeletePrompt,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.examDetailDeleteWarning,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.examDetailDeleteWarningStrong,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: _WarningDialogButton(
                                    label: l10n.cancel,
                                    isOutline: true,
                                    onPressed: () => Navigator.of(context).pop(false),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _WarningDialogButton(
                                    label: l10n.delete,
                                    isDanger: true,
                                    onPressed: () => Navigator.of(context).pop(true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    if (confirmed != true) return;

    Haptics.vibrate(HapticsType.error);
    await ref.read(examsProvider.notifier).deleteExam(exam.id);
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
            icon: const Icon(Icons.calendar_month),
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
              error: (_, __) => Center(child: Text(l10n.examsLoadError)),
              data: (exams) {
                final filteredExams = exams.where((exam) {
                  if (_selectedFilter == null) return true;
                  return exam.typeEnum == _selectedFilter;
                }).toList();
                final now = DateTime.now();
                final upcoming = filteredExams.where((e) => !e.examDateTime.isBefore(now)).toList()
                  ..sort((a, b) => a.examDateTime.compareTo(b.examDateTime));
                final past = filteredExams.where((e) => e.examDateTime.isBefore(now)).toList()
                  ..sort((a, b) => b.examDateTime.compareTo(a.examDateTime));

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
                    AppButton(
                      onPressed: () => context.push('/create-exam'),
                      text: l10n.examsAddCta,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(title: l10n.examsUpcomingSectionTitle),
                    const SizedBox(height: AppSpacing.sm),
                    _ExamTypeTabs(
                      selectedFilter: _selectedFilter,
                      onChanged: (value) => setState(() => _selectedFilter = value),
                      allLabel: l10n.all,
                      midtermLabel: l10n.examsTypeMidterm,
                      finalLabel: l10n.examsTypeFinal,
                      quizLabel: l10n.examsTypeQuiz,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (upcoming.isEmpty)
                      _EmptySection(
                        message: _selectedFilter == null ? l10n.examsNoUpcoming : l10n.examsNoItems,
                        subtitle: l10n.examsNoUpcomingSubtitle,
                        actionLabel: l10n.examsAddCta,
                        onAction: () => context.push('/create-exam'),
                      )
                    else
                      ...upcoming.map(
                        (exam) => _ExamCard(
                          exam: exam,
                          typeLabel: _typeLabel(l10n, exam.typeEnum),
                          subtitleDate: _formatDateTime(exam.examDateTime, locale, l10n),
                          onTap: () => context.push('/exam-detail?id=${Uri.encodeComponent(exam.id)}'),
                          onEdit: () => context.push('/edit-exam?id=${Uri.encodeComponent(exam.id)}'),
                          onDelete: () => _confirmDeleteExam(context, exam),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(title: l10n.examsPastSectionTitle),
                    const SizedBox(height: AppSpacing.sm),
                    if (past.isEmpty)
                      _EmptySection(message: _selectedFilter == null ? l10n.examsNoPast : l10n.examsNoItems)
                    else
                      ...past.map(
                        (exam) => _ExamCard(
                          exam: exam,
                          typeLabel: _typeLabel(l10n, exam.typeEnum),
                          subtitleDate: _formatDateTime(exam.examDateTime, locale, l10n),
                          onTap: () => context.push('/exam-detail?id=${Uri.encodeComponent(exam.id)}'),
                          onEdit: () => context.push('/edit-exam?id=${Uri.encodeComponent(exam.id)}'),
                          onDelete: () => _confirmDeleteExam(context, exam),
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

class _WarningDialogButton extends StatelessWidget {
  const _WarningDialogButton({
    required this.label,
    required this.onPressed,
    this.isDanger = false,
    this.isOutline = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDanger;
  final bool isOutline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isOutline
              ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
              : isDanger
                  ? const Color(0xFFEF4444)
                  : theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          border: isOutline
              ? Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1.5,
                )
              : null,
          boxShadow: !isOutline
              ? [
                  BoxShadow(
                    color: (isDanger ? const Color(0xFFEF4444) : const Color(0xFF3B82F6))
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isOutline
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                  : theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

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

    Widget tabChip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          elevation: 0,
          onSelected: (_) {
            Haptics.vibrate(HapticsType.selection);
            onTap();
          },
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: selected
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(
                    alpha: isDark ? 0.6 : 0.85,
                  ),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
          ),
          selectedColor: theme.colorScheme.secondary,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.secondary
                  : (isDark
                      ? Colors.transparent
                      : theme.colorScheme.outline.withValues(alpha: 0.35)),
              width: 1,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          tabChip(
            label: allLabel,
            selected: selectedFilter == null,
            onTap: () => onChanged(null),
          ),
          tabChip(
            label: midtermLabel,
            selected: selectedFilter == ExamType.midterm,
            onTap: () => onChanged(ExamType.midterm),
          ),
          tabChip(
            label: finalLabel,
            selected: selectedFilter == ExamType.finalExam,
            onTap: () => onChanged(ExamType.finalExam),
          ),
          tabChip(
            label: quizLabel,
            selected: selectedFilter == ExamType.quiz,
            onTap: () => onChanged(ExamType.quiz),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        message,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ).let((title) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: AppButton(
                    onPressed: onAction,
                    text: actionLabel!,
                    variant: AppButtonVariant.secondary,
                  ),
                ),
              ],
            ],
          )),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.typeLabel,
    required this.subtitleDate,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ExamModel exam;
  final String typeLabel;
  final String subtitleDate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _prettyClassroom(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;
    return value.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final typeColor = getExamTypeColor(exam.typeEnum);
    final modeLabel = exam.isOnline ? l10n.examsLocationOnline : l10n.examsLocationFaceToFace;
    final modeIcon = exam.isOnline ? '🌐' : '🏫';
    final hasClassroom = exam.classroom != null && exam.classroom!.trim().isNotEmpty;
    final hasInstructor = exam.instructorName != null && exam.instructorName!.trim().isNotEmpty;
    final hasCourse = exam.courseName != null && exam.courseName!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: typeColor, width: 4)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: AppGlassCard(
            borderOnly: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              exam.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: typeColor.withValues(alpha: 0.45)),
                            ),
                            child: Text(
                              typeLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.editExam,
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      tooltip: l10n.delete,
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: theme.colorScheme.error,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 2),
                StreamBuilder<int>(
                  stream: Stream.periodic(const Duration(minutes: 1), (count) => count),
                  builder: (_, __) {
                    return Text(
                      getCountdownText(exam.examDateTime, completedLabel: l10n.completed),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text('$modeIcon $modeLabel', style: theme.textTheme.bodyMedium),
                if (!exam.isOnline && hasClassroom)
                  Text(
                    '📍 ${l10n.examsLocationClassroomPrefix} ${_prettyClassroom(exam.classroom!)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                if (hasInstructor)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '👤 ${l10n.examsInstructorPrefix} ${exam.instructorName!.trim()}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                if (hasCourse)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '📚 ${l10n.examsCoursePrefix} ${exam.courseName!.trim()}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _WidgetLetExt on Widget {
  Widget let(Widget Function(Widget it) fn) => fn(this);
}
