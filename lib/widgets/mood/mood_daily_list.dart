import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/mood_log.dart';
import '../../core/design/app_spacing.dart';
import './mood_details_bottom_sheet.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class MoodDailyList extends StatelessWidget {
  final AsyncValue<List<MoodLog>> moodLogsAsync;
  final int days;
  final bool showDate;
  final bool isFixed;

  const MoodDailyList({
    super.key,
    required this.moodLogsAsync,
    required this.days,
    this.showDate = true,
    this.isFixed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return moodLogsAsync.when(
      data: (logs) {
        if (logs.isEmpty) return const SizedBox.shrink();

        // Group logs by date
        final dailyMoods = <DateTime, MoodLog>{};
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        for (var i = 0; i < days; i++) {
          final date = today.subtract(Duration(days: i));
          final dateOnly = DateTime(date.year, date.month, date.day);
          
          final dayLogs = logs.where((l) {
            final logDate = l.createdAt.toLocal();
            return logDate.year == dateOnly.year &&
                logDate.month == dateOnly.month &&
                logDate.day == dateOnly.day;
          }).toList();
          
          if (dayLogs.isNotEmpty) {
            // Use the last mood log for that day
            dailyMoods[dateOnly] = dayLogs.first;
          }
        }

        // Generate the list of dates to display (chronological)
        final displayDates = List.generate(days, (i) {
          final date = today.subtract(Duration(days: days - 1 - i));
          return DateTime(date.year, date.month, date.day);
        });

        if (isFixed) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: displayDates.map((date) {
              final log = dailyMoods[date];
              final moodLevel = log?.moodLevel;
              final locale = Localizations.localeOf(context).toString();
              final dayName = DateFormat.E(locale).format(date);
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: log == null ? null : () {
                      Haptics.vibrate(HapticsType.selection);
                      MoodDetailsBottomSheet.show(context, log);
                    },
                    child: MoodEmojiCircle(moodLevel: moodLevel, size: 36),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        }

        return SizedBox(
          height: showDate ? 100 : 85,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: displayDates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final date = displayDates[index];
              final log = dailyMoods[date];
              final moodLevel = log?.moodLevel;
              
              final locale = Localizations.localeOf(context).toString();
              final dayName = DateFormat.E(locale).format(date);
              final dateLabel = DateFormat.Md(locale).format(date);
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: log == null ? null : () {
                      Haptics.vibrate(HapticsType.selection);
                      MoodDetailsBottomSheet.show(context, log);
                    },
                    child: MoodEmojiCircle(moodLevel: moodLevel),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showDate)
                    Text(
                      dateLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class MoodEmojiCircle extends StatelessWidget {
  final int? moodLevel;
  final double size;

  const MoodEmojiCircle({super.key, this.moodLevel, this.size = 48});

  String _emojiForMood(int level) {
    switch (level) {
      case 1: return '😞';
      case 2: return '🙁';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😄';
      default: return '😐';
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1: return const Color(0xFFE53935);
      case 2: return const Color(0xFFFF7043);
      case 3: return const Color(0xFFFFC107);
      case 4: return const Color(0xFF66BB6A);
      case 5: return const Color(0xFF2ECC71);
      default: return const Color(0xFFFFC107);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (moodLevel == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.08),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.15),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.horizontal_rule_rounded,
            size: size * 0.4,
            color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.2 : 0.3),
          ),
        ),
      );
    }

    final color = _getMoodColor(moodLevel!);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: isDark ? 0.12 : 0.15),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.35),
          width: 1,
        ),
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.25 : 0.3),
            color.withValues(alpha: isDark ? 0.05 : 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.2 : 0.15),
            blurRadius: isDark ? 10 : 8,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _emojiForMood(moodLevel!),
        style: TextStyle(fontSize: size * 0.54),
      ),
    );
  }
}
