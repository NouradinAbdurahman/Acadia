import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class ExamDetailScreen extends ConsumerWidget {
  const ExamDetailScreen({super.key, required this.examId});

  final String examId;

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _relativeDayLabel(DateTime value, AppLocalizations l10n) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    if (_isSameDate(value, now)) return l10n.today;
    if (_isSameDate(value, tomorrow)) return l10n.tomorrow;
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final exams = ref.watch(examsProvider).valueOrNull ?? const <ExamModel>[];
    ExamModel? exam;
    for (final item in exams) {
      if (item.id == examId) {
        exam = item;
        break;
      }
    }

    if (exam == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(l10n.examDetailTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: AuthBackgroundContainer(
          child: Center(child: Text(l10n.examsNotFound)),
        ),
      );
    }
    final examData = exam;

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final typeColor = getExamTypeColor(examData.typeEnum);
    final dateText = DateFormat('EEE, MMM d, yyyy', localeTag).format(examData.examDateTime);
    final timeText = DateFormat('HH:mm', localeTag).format(examData.examDateTime);
    final dayLabel = _relativeDayLabel(examData.examDateTime, l10n);
    final countdownText = getCountdownText(examData.examDateTime, completedLabel: l10n.completed);
    final typeLabel = switch (examData.typeEnum) {
      ExamType.midterm => l10n.examsTypeMidterm,
      ExamType.finalExam => l10n.examsTypeFinal,
      ExamType.quiz => l10n.examsTypeQuiz,
    };
    final locationText = examData.isOnline
        ? l10n.examsLocationOnline
        : (examData.classroom?.trim().isNotEmpty ?? false)
            ? '${l10n.examsLocationClassroomPrefix} ${examData.classroom!.trim().toUpperCase()}'
            : l10n.examsLocationFaceToFace;

    Future<void> handleDelete() async {
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
      await ref.read(examsProvider.notifier).deleteExam(examData.id);
      if (context.mounted) context.pop();
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.examDetailTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppGlassCard(
                  borderOnly: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              examData.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              typeLabel,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        countdownText,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppGlassCard(
                  borderOnly: true,
                  child: Column(
                    children: [
                      _InfoRow(label: l10n.examsDateField, value: dateText),
                      _InfoRow(label: l10n.examsTimeField, value: dayLabel.isEmpty ? timeText : '$dayLabel • $timeText'),
                      _InfoRow(label: l10n.examsLocationFaceToFace, value: locationText),
                      _InfoRow(
                        label: l10n.examsInstructorField,
                        value: examData.instructorName?.trim().isNotEmpty == true
                            ? examData.instructorName!.trim()
                            : '-',
                      ),
                      _InfoRow(
                        label: l10n.examsCourseOptionalField,
                        value: examData.courseName?.trim().isNotEmpty == true
                            ? examData.courseName!.trim()
                            : '-',
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        onPressed: () => context.push('/edit-exam?id=${Uri.encodeComponent(examData.id)}'),
                        text: l10n.editExam,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        onPressed: handleDelete,
                        text: l10n.delete,
                        variant: AppButtonVariant.secondary,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.delete,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: AppSpacing.sm),
          Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
