import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/adaptive/adaptive_engine.dart';
import '../domain/adaptive/adaptive_profile.dart';
import 'analytics_provider.dart';
import 'study_sessions_provider.dart';

final adaptiveProfileProvider = Provider<AdaptiveProfile>((ref) {
  final sessions = ref.watch(studySessionsProvider).valueOrNull ?? const [];
  final consistency = ref.watch(analyticsProvider).valueOrNull?.consistency ?? 1.0;
  return AdaptiveEngine.build(
    sessions,
    consistency: consistency,
  );
});
