import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../components/app_back_button.dart';
import '../../components/app_glass_card.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exam.dart';
import '../../providers/exams_provider.dart';
import '../../utils/exam_ui_utils.dart';
import '../../widgets/auth/auth_background_container.dart';

class ExamsCalendarScreen extends ConsumerStatefulWidget {
  const ExamsCalendarScreen({super.key});

  @override
  ConsumerState<ExamsCalendarScreen> createState() => _ExamsCalendarScreenState();
}

class _ExamsCalendarScreenState extends ConsumerState<ExamsCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<ExamModel> _eventsForDay(DateTime day, List<ExamModel> exams) {
    return exams.where((e) => _isSameDate(e.examDateTime, day)).toList()
      ..sort((a, b) => a.examDateTime.compareTo(b.examDateTime));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final examsAsync = ref.watch(examsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.examsCalendarTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          bottom: false,
          child: examsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(l10n.examsLoadError)),
            data: (exams) {
              final selected = _selectedDay ?? _focusedDay;
              final dayEvents = _eventsForDay(selected, exams);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: AppGlassCard(
                      borderOnly: true,
                      child: TableCalendar<ExamModel>(
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2035),
                        focusedDay: _focusedDay,
                        locale: localeTag,
                        eventLoader: (day) => _eventsForDay(day, exams),
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          markerDecoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ) ??
                              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        calendarBuilders: CalendarBuilders<ExamModel>(
                          markerBuilder: (context, day, events) {
                            if (events.isEmpty) return const SizedBox.shrink();
                            final uniqueTypes = events.map((e) => e.typeEnum).toSet().toList();
                            return Positioned(
                              bottom: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: uniqueTypes.take(3).map((type) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: getExamTypeColor(type),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: dayEvents.isEmpty
                        ? Center(
                            child: Text(
                              l10n.examsNoItemsForDay,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              0,
                              AppSpacing.lg,
                              AppSpacing.xl,
                            ),
                            itemCount: dayEvents.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (_, i) {
                              final exam = dayEvents[i];
                              final examType = exam.typeEnum;
                              final typeColor = getExamTypeColor(examType);
                              final timeText = DateFormat('HH:mm', localeTag).format(exam.examDateTime);
                              final typeText = switch (examType) {
                                ExamType.midterm => l10n.examsTypeMidterm,
                                ExamType.finalExam => l10n.examsTypeFinal,
                                ExamType.quiz => l10n.examsTypeQuiz,
                              };

                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => context.push('/exam-detail?id=${Uri.encodeComponent(exam.id)}'),
                                child: AppGlassCard(
                                  borderOnly: true,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: typeColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exam.title,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$typeText • $timeText',
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
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
