import 'package:flutter/material.dart';

import '../models/exam.dart';

String getCountdownText(DateTime examTime, {String completedLabel = 'Completed'}) {
  final now = DateTime.now().toLocal();
  final localExamTime = examTime.toLocal();
  final diff = localExamTime.difference(now);
  if (diff.isNegative) return completedLabel;

  final days = diff.inDays;
  final hours = diff.inHours % 24;
  final minutes = diff.inMinutes % 60;

  if (days > 0) return 'in ${days}d ${hours}h';
  if (hours > 0) return 'in ${hours}h ${minutes}m';
  return 'in ${minutes}m';
}

Color getExamTypeColor(ExamType type) {
  switch (type) {
    case ExamType.midterm:
      return Colors.purple;
    case ExamType.finalExam:
      return Colors.red;
    case ExamType.quiz:
      return Colors.blue;
  }
}
