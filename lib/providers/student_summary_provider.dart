import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

final courseCountForSemesterProvider =
    FutureProvider.family<int, String>((ref, semesterId) async {
  final service = ref.watch(courseServiceProvider);
  final courses = await service.getCourses(semesterId: semesterId);
  return courses.length;
});
