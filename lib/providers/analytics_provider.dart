import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analytics_data.dart';
import '../models/deadline.dart';
import '../models/mood_log.dart';
import '../models/study_session.dart';
import '../models/task.dart';
import 'app_providers.dart';
import 'study_sessions_provider.dart';
import 'tasks_provider.dart';
import 'deadlines_provider.dart';
import 'course_provider.dart';
import 'mood_provider.dart';
import 'student_profile_provider.dart';
import 'semester_provider.dart';
import '../domain/decision/decision_rules.dart';
import '../domain/adaptive/adaptive_engine.dart';


final analyticsJumpToTrendsTokenProvider = StateProvider<int>((ref) => 0);

enum AdaptationMode {
  keepPreference,
  followBehavior,
}

class StudyAdaptationModeNotifier extends StateNotifier<AdaptationMode> {
  StudyAdaptationModeNotifier() : super(AdaptationMode.keepPreference) {
    _load();
  }

  static const _prefsKey = 'follow_behavior';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final followBehavior = prefs.getBool(_prefsKey) ?? false;
    state = followBehavior
        ? AdaptationMode.followBehavior
        : AdaptationMode.keepPreference;
  }

  Future<void> setMode(AdaptationMode nextMode) async {
    state = nextMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, nextMode == AdaptationMode.followBehavior);
  }
}

final studyAdaptationModeProvider =
    StateNotifierProvider<StudyAdaptationModeNotifier, AdaptationMode>(
  (ref) => StudyAdaptationModeNotifier(),
);

const DEFAULT_WEEKLY_GOAL = 15;

final weeklyStudyGoalHoursProvider = Provider<int>((ref) {
  final activeSemesterAsync = ref.watch(activeSemesterFullProvider);

  return activeSemesterAsync.when(
    data: (activeSemester) {
      if (activeSemester == null) return DEFAULT_WEEKLY_GOAL;
      final weeklyGoal = activeSemester.weeklyStudyGoal;
      if (weeklyGoal == null || weeklyGoal <= 0 || weeklyGoal > 100) {
        return DEFAULT_WEEKLY_GOAL;
      }
      return weeklyGoal;
    },
    loading: () => DEFAULT_WEEKLY_GOAL,
    error: (_, __) => DEFAULT_WEEKLY_GOAL,
  );
});

enum BurnoutLevel {
  stable,
  warning,
  highRisk,
  burnoutRisk,
}

class BurnoutSnapshot {
  final DateTime date;
  final double score;
  final double deficitHours;
  final double inconsistencyScore;

  const BurnoutSnapshot({
    required this.date,
    required this.score,
    required this.deficitHours,
    required this.inconsistencyScore,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'score': score,
        'deficitHours': deficitHours,
        'inconsistencyScore': inconsistencyScore,
      };

  factory BurnoutSnapshot.fromJson(Map<String, dynamic> json) {
    return BurnoutSnapshot(
      date: DateTime.parse(json['date'] as String),
      score: (json['score'] as num).toDouble(),
      deficitHours: (json['deficitHours'] as num).toDouble(),
      inconsistencyScore: (json['inconsistencyScore'] as num).toDouble(),
    );
  }
}

DateTime _burnoutDay(DateTime value) => DateTime(value.year, value.month, value.day);

String _burnoutDayKey(DateTime value) {
  final normalized = _burnoutDay(value);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}

class BurnoutHistoryNotifier extends StateNotifier<List<BurnoutSnapshot>> {
  BurnoutHistoryNotifier() : super(const []) {
    _load();
  }

  static const String _boxName = 'burnout_history';

  Future<void> _load() async {
    final box = await Hive.openBox(_boxName);
    final entries = <BurnoutSnapshot>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        try {
          entries.add(BurnoutSnapshot.fromJson(Map<String, dynamic>.from(value)));
        } catch (_) {
          // Ignore malformed entries.
        }
      }
    }
    entries.sort((a, b) => a.date.compareTo(b.date));
    state = entries;
  }

  Future<void> syncSnapshot(BurnoutSnapshot snapshot) async {
    final normalized = _burnoutDay(snapshot.date);
    final existingIndex = state.indexWhere((entry) => _burnoutDay(entry.date) == normalized);
    final next = [...state];

    if (existingIndex >= 0) {
      final existing = next[existingIndex];
      if ((existing.score - snapshot.score).abs() < 0.1 &&
          (existing.deficitHours - snapshot.deficitHours).abs() < 0.1 &&
          (existing.inconsistencyScore - snapshot.inconsistencyScore).abs() < 0.1) {
        return;
      }
      next[existingIndex] = snapshot;
    } else {
      next.add(snapshot);
    }

    next.sort((a, b) => a.date.compareTo(b.date));
    while (next.length > 14) {
      next.removeAt(0);
    }

    final box = await Hive.openBox(_boxName);
    await box.clear();
    for (final entry in next) {
      await box.put(_burnoutDayKey(entry.date), entry.toJson());
    }

    state = next;
  }

  List<BurnoutSnapshot> get last14Days => state;
}

final burnoutHistoryProvider = StateNotifierProvider<BurnoutHistoryNotifier, List<BurnoutSnapshot>>(
  (ref) => BurnoutHistoryNotifier(),
);

// ── Analytics Provider ───────────────────────────────────────────────────────

final analyticsProvider = AsyncNotifierProvider<AnalyticsNotifier, AnalyticsData>(() {
  return AnalyticsNotifier();
});

class AnalyticsNotifier extends AsyncNotifier<AnalyticsData> {
  // Per-semester persistent cache.
  // Key   = semesterId
  // Value = record of the hash that produced the data + the data itself.
  // Cache hit requires BOTH semesterId AND hash to match, so new data
  // (e.g. moods 2→3) correctly invalidates the entry and triggers recompute.
  final Map<String, ({int hash, AnalyticsData data})> _cache = {};

  // Hash of the last dataset that entered the compute path — guards against
  // triple-fire rebuilds within the same semester before the cache entry exists.
  int? _lastHash;

  @override
  Future<AnalyticsData> build() async {
    ref.listen<AsyncValue<String?>>(activeSemesterProvider, (previous, next) {
      if (previous?.value == next.value) return;
      _lastHash = null;
      final previousSemester = previous?.value;
      if (previousSemester != null) _cache.remove(previousSemester);
      ref.invalidateSelf();
    });

    final user = ref.watch(currentUserProvider);
    if (user == null) return AnalyticsData.empty();

    // 1. Await active semester — the keystone dependency.
    final semesterId = await ref.watch(activeSemesterProvider.future);
    if (semesterId == null) {
      debugPrint('[AnalyticsProvider] No active semester found — returning empty.');
      _lastHash = null;
      return AnalyticsData.empty();
    }
    debugPrint('[AnalyticsProvider] Found active semester: $semesterId. Starting data fetch...');

    // 2. Wait until all semester-scoped dependencies are ready.
    // This prevents partial analytics runs during staggered provider hydration.
    final sessionsAsync = ref.watch(studySessionsProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final moodsAsync = ref.watch(moodLogsProvider);
    final deadlinesAsync = ref.watch(deadlinesProvider);
    final coursesAsync = ref.watch(courseProvider);
    if (sessionsAsync.isLoading ||
        tasksAsync.isLoading ||
        moodsAsync.isLoading ||
        deadlinesAsync.isLoading ||
        coursesAsync.isLoading) {
      return state.value ?? AnalyticsData.empty();
    }

    // 3. Read provider values after readiness gate.
    final sessions = sessionsAsync.value ?? <StudySession>[];
    final tasks = tasksAsync.value ?? <Task>[];
    final moods = moodsAsync.value ?? <MoodLog>[];
    final deadlines = deadlinesAsync.value ?? <Deadline>[];

    // 4. Compute stable hash for this data snapshot.
    // Include lengths of all datasets that affect the final report.
    final currentHash = Object.hash(
      semesterId,
      sessions.length,
      tasks.length,
      moods.length,
      deadlines.length,
    );

    // 5. Cache check — requires BOTH semesterId AND hash to match.
    final cached = _cache[semesterId];
    if (cached != null && cached.hash == currentHash) {
      debugPrint('[AnalyticsProvider] Cache hit — Semester: $semesterId (hash: $currentHash).');
      return cached.data;
    }

    // 6. Intra-build deduplication — only reached when cache is absent/stale.
    //    Prevents triple-fire while sessions/tasks/moods resolve sequentially
    //    on the very first load before the cache entry has been written.
    if (_lastHash == currentHash) {
      debugPrint('[AnalyticsProvider] Skipping duplicate build (hash: $currentHash).');
      return state.value ?? AnalyticsData.empty();
    }

    // 7. Hard guard for true empty snapshot with dedup support.
    if (sessions.isEmpty && tasks.isEmpty && moods.isEmpty && deadlines.isEmpty) {
      debugPrint('[AnalyticsProvider] All data empty for Semester: $semesterId — returning empty.');
      final empty = AnalyticsData.empty();
      _lastHash = currentHash;
      _cache[semesterId] = (hash: currentHash, data: empty);
      return empty;
    }

    // 8. Real computation.
    debugPrint('[AnalyticsProvider] Computing for Semester: $semesterId | Sessions: ${sessions.length} | Tasks: ${tasks.length} | Moods: ${moods.length} | Deadlines: ${deadlines.length}');

    final repository = ref.read(analyticsRepositoryProvider);
    final data = await repository.computeFromPreloaded(
      userId: user.id,
      semesterId: semesterId,
      sessions: sessions,
      tasks: tasks,
      moodLogs: moods,
      deadlines: deadlines,
    );

    _lastHash = currentHash;
    _cache[semesterId] = (hash: currentHash, data: data);

    debugPrint('[AnalyticsProvider] Computed for Semester: $semesterId | Sessions: ${sessions.length} | Tasks: ${tasks.length} | Moods: ${moods.length} | Deadlines: ${deadlines.length}');
    return data;
  }

  /// Invalidates and forces a fresh computation for the current semester,
  /// bypassing both the hash guard and the persistent cache.
  Future<void> refresh() async {
    _lastHash = null;
    final semesterId = ref.read(activeSemesterProvider).value;
    if (semesterId != null) _cache.remove(semesterId);
    ref.invalidateSelf();
    await future;
  }

  /// Silently updates state without triggering a full rebuild.
  Future<void> refreshSilently() async {
    final user = ref.read(currentUserProvider);
    final semesterId = ref.read(activeSemesterProvider).value;
    if (user == null || semesterId == null) return;

    try {
      final sessions = ref.read(studySessionsProvider).value ?? <StudySession>[];
      final tasks = ref.read(tasksProvider).value ?? <Task>[];
      final moods = ref.read(moodLogsProvider).value ?? <MoodLog>[];
      final deadlines = ref.read(deadlinesProvider).value ?? <Deadline>[];

      final data = await ref.read(analyticsRepositoryProvider).computeFromPreloaded(
        userId: user.id,
        semesterId: semesterId,
        sessions: sessions,
        tasks: tasks,
        moodLogs: moods,
        deadlines: deadlines,
      );
      final hash = Object.hash(
        semesterId,
        sessions.length,
        tasks.length,
        moods.length,
        deadlines.length,
      );
      _lastHash = hash;
      _cache[semesterId] = (hash: hash, data: data);
      state = AsyncValue.data(data);
    } catch (_) {
      // Keep previous state on silent error.
    }
  }
}



class StudyAnalytics {
  final List<StudySession> sessions;
  final int weeklyGoalMinutes;
  final String breakPattern;
  final String preferredStudyTime;
  final List<BurnoutSnapshot> burnoutHistory;
  final double avgDailyStress;
  final double avgSessionStress;
  final bool hasMoodTrendDown;
  final double burnoutScoreValue;
  // Removed final consistency field to use getter instead

  StudyAnalytics(
    this.sessions,
    this.weeklyGoalMinutes, {
    this.breakPattern = 'mixed',
    this.preferredStudyTime = 'morning',
    this.burnoutHistory = const [],
    this.avgDailyStress = 0.0,
    this.avgSessionStress = 0.0,
    this.hasMoodTrendDown = false,
    this.burnoutScoreValue = 0.0,
  });

  double get consistency => (activeDaysThisWeek / 7.0).clamp(0.0, 1.0);
  double get historicalConsistency {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 14));
    final activeDays = sessions
        .where((s) => s.createdAt.isAfter(start))
        .map((s) => _burnoutDayKey(s.createdAt))
        .toSet()
        .length;
    return (activeDays / 14.0).clamp(0.0, 1.0);
  }
  double get weeklyConsistency => (totalThisWeekHours / (weeklyGoalMinutes / 60.0)).clamp(0.0, 1.0);

  double get totalThisWeekHours => weekMinutes / 60.0;

  int get weekMinutes {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return sessions
        .where((s) => !s.createdAt.isBefore(weekStart))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int get todayMinutes {
    final now = DateTime.now();
    return sessions
        .where((s) =>
            s.createdAt.year == now.year &&
            s.createdAt.month == now.month &&
            s.createdAt.day == now.day)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  List<StudySession> get recentSessions {
    return sessions.toList();
  }

  int get shortSessions => sessions.where((s) => s.durationMinutes < 15).length;

  int get earlyStops => sessions.where((s) => !s.completed).length;

  double get avgDuration => sessions.isEmpty
      ? 0.0
      : (sessions.fold(0, (sum, s) => sum + s.durationMinutes) /
          sessions.length);

  // ── Pomodoro analytics ──
  List<StudySession> get pomodoroSessions =>
      sessions.where((s) => s.isPomodoro).toList();

  /// Ratio of fully completed Pomodoro sessions to all Pomodoro sessions (0.0–1.0)
  double get pomodoroCompletionRate {
    final ps = pomodoroSessions;
    if (ps.isEmpty) return 0.0;
    final completed = ps.where((s) => s.completed).length;
    return completed / ps.length;
  }

  /// Average cycles per Pomodoro session
  double get averageCyclesPerSession {
    final ps = pomodoroSessions;
    if (ps.isEmpty) return 0.0;
    final totalCycles = ps.fold<int>(0, (sum, s) => sum + (s.cyclesCompleted ?? 0));
    return totalCycles / ps.length;
  }

  /// Average focus minutes per Pomodoro session
  double get avgFocusMinutesPerSession {
    final ps = pomodoroSessions;
    if (ps.isEmpty) return 0.0;
    final totalFocus = ps.fold<int>(0, (sum, s) => sum + (s.totalFocusMinutes ?? s.durationMinutes));
    return totalFocus / ps.length;
  }

  /// 3-tier behavioral insight about Pomodoro usage
  String getPomodoroInsight(AppLocalizations l10n) {
    if (pomodoroSessions.isEmpty) return '';
    final rate = pomodoroCompletionRate;
    if (rate >= 0.8) return l10n.pomodoroInsightConsistent;
    if (rate >= 0.4) return l10n.pomodoroInsightPartial;
    return l10n.pomodoroInsightNeedsWork;
  }

  int get sessionsThisWeek {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return sessions.where((s) => !s.createdAt.isBefore(weekStart)).length;
  }

  int get activeDaysThisWeek {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return sessions
        .where((s) => !s.createdAt.isBefore(weekStart))
        .map((s) => s.createdAt.day)
        .toSet()
        .length;
  }

  double get currentWeekAvg {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekSessions = sessions.where((s) => s.createdAt.isAfter(weekStart)).toList();
    if (weekSessions.isEmpty) return 0;
    return weekSessions.fold(0, (sum, s) => sum + s.durationMinutes) / weekSessions.length;
  }

  double get previousWeekAvg {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevWeekSessions = sessions.where((s) => s.createdAt.isAfter(prevWeekStart) && s.createdAt.isBefore(weekStart)).toList();
    if (prevWeekSessions.isEmpty) return 0;
    return prevWeekSessions.fold(0.0, (sum, s) => sum + s.durationMinutes) / prevWeekSessions.length;
  }

  Map<int, int> get weeklyMinutes {
    final Map<int, int> data = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    
    for (final s in sessions) {
      if (!s.createdAt.isBefore(weekStart)) {
        final day = s.createdAt.weekday; 
        data[day] = (data[day] ?? 0) + s.durationMinutes;
      }
    }
    return data;
  }

  bool get hasData => sessions.isNotEmpty;

  int get focusScore {
    if (!hasData) return 50;
    
    // Formula:
    // durationScore (max 40) = (avgMinutes / 60) * 40
    // consistencyScore (max 30) = (sessionsThisWeek / 7) * 30
    // completionScore (max 30) = (completedCount / totalCount) * 30
    
    final durationScore = (avgDuration / 60) * 40;
    final consistencyScore = (sessionsThisWeek / 7) * 30;
    
    final completedCount = sessions.where((s) => s.completed).length;
    final completionScore = (completedCount / sessions.length) * 30;

    final score = durationScore + consistencyScore + completionScore;
    return score.clamp(0, 100).round();
  }

  String get trend {
    if (currentWeekAvg > previousWeekAvg) return "improving";
    if (currentWeekAvg < previousWeekAvg) return "declining";
    return "stable";
  }

  int _suggestedDurationForStudyTime(String studyTime) {
    if (breakPattern == 'pomodoro') return 25;
    if (breakPattern == 'deep_work') {
      final base = focusScore < 50 ? 45 : 55;
      return base.clamp(40, 60);
    }

    int base;
    if (focusScore < 40) {
      base = 20;
    } else if (focusScore < 70) {
      base = 30;
    } else {
      base = 45;
    }

    final timeAdjustment = switch (studyTime) {
      'morning' => 5,
      'night' => -5,
      _ => 0,
    };
    return (base + timeAdjustment).clamp(20, 60);
  }

  int get suggestedDuration {
    final profile = AdaptiveEngine.build(
      sessions,
      consistency: consistency,
    );
    return DecisionRules.getFinalRecommendedMinutes(
      consistency: consistency,
      stress: avgSessionStress,
      profile: profile,
      burnoutRisk: burnoutScore,
    );
  }

  int suggestedDurationForMode(AdaptationMode mode) {
    final slot = mode == AdaptationMode.followBehavior && hasReliableBehaviorSignal
        ? (dominantStudyTime ?? preferredStudyTime)
        : preferredStudyTime;
    return _suggestedDurationForStudyTime(slot);
  }

  int recommendedDurationForMode(AdaptationMode mode) {
    final base = suggestedDurationForMode(mode);
    switch (burnoutLevel) {
      case BurnoutLevel.stable:
        return base;
      case BurnoutLevel.warning:
        return base.clamp(30, 45);
      case BurnoutLevel.highRisk:
        return base.clamp(25, 35);
      case BurnoutLevel.burnoutRisk:
        return base.clamp(20, 30);
    }
  }

  int get burnoutSuggestedDurationMinutes {
    return recommendedDurationForMode(AdaptationMode.keepPreference);
  }

  List<StudySession> get _recentBehaviorSessions {
    final sorted = [...sessions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(14).toList();
  }

  String _segmentFromHour(int hour) {
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'night';
  }

  DateTime _startOfWeek(DateTime now) {
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  List<StudySession> get thisWeekSessions {
    final start = _startOfWeek(DateTime.now());
    return sessions.where((s) => s.createdAt.isAfter(start)).toList();
  }

  List<StudySession> get lastWeekSessions {
    final startOfThis = _startOfWeek(DateTime.now());
    final startOfLast = startOfThis.subtract(const Duration(days: 7));
    return sessions
        .where((s) => s.createdAt.isAfter(startOfLast) && s.createdAt.isBefore(startOfThis))
        .toList();
  }

  Map<String, int> _buildBucketsFor(List<StudySession> source) {
    final buckets = <String, int>{
      'morning': 0,
      'afternoon': 0,
      'night': 0,
    };
    for (final session in source) {
      final segment = _segmentFromHour(session.createdAt.hour);
      buckets[segment] = (buckets[segment] ?? 0) + 1;
    }
    return buckets;
  }

  Map<String, int> get studyTimeBuckets {
    return _buildBucketsFor(_recentBehaviorSessions);
  }

  Map<String, int> get thisWeekStudyTimeBuckets => _buildBucketsFor(thisWeekSessions);

  Map<String, int> get lastWeekStudyTimeBuckets => _buildBucketsFor(lastWeekSessions);

  int sessionsForSlot(String slot, {bool previousWeek = false}) {
    final source = previousWeek ? lastWeekStudyTimeBuckets : thisWeekStudyTimeBuckets;
    return source[slot] ?? 0;
  }

  int slotTrendDelta(String slot) {
    return sessionsForSlot(slot) - sessionsForSlot(slot, previousWeek: true);
  }

  int get sessionsThisWeekCount => thisWeekSessions.length;

  int get trackedSessionCount => _recentBehaviorSessions.length;

  String? get dominantStudyTime {
    if (trackedSessionCount == 0) return null;
    final entries = studyTimeBuckets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty || entries.first.value == 0) return null;
    return entries.first.key;
  }

  double get dominantStudyShare {
    final dominant = dominantStudyTime;
    if (dominant == null || trackedSessionCount == 0) return 0.0;
    return (studyTimeBuckets[dominant] ?? 0) / trackedSessionCount;
  }

  double get behaviorConfidence {
    if (trackedSessionCount == 0) return 0.0;
    final sampleWeight = (trackedSessionCount / 8.0).clamp(0.0, 1.0);
    return (dominantStudyShare * 100.0 * sampleWeight).clamp(0.0, 100.0);
  }

  double get preferenceConfidence {
    if (trackedSessionCount == 0) return 100.0;
    final matched = studyTimeBuckets[preferredStudyTime] ?? 0;
    return ((matched / trackedSessionCount) * 100.0).clamp(0.0, 100.0);
  }

  bool get hasReliableBehaviorSignal =>
      trackedSessionCount >= 3 && behaviorConfidence >= 70.0;

  bool get shouldSuggestBehaviorShift {
    final dominant = dominantStudyTime;
    if (dominant == null) return false;
    return hasReliableBehaviorSignal && dominant != preferredStudyTime;
  }

  String? get adaptiveHintStudyTime =>
      shouldSuggestBehaviorShift ? dominantStudyTime : null;

  int get dominantStudyTimeCount {
    final dominant = dominantStudyTime;
    if (dominant == null) return 0;
    return thisWeekStudyTimeBuckets[dominant] ?? 0;
  }

  double get weeklyDeficitHours {
    final deficit = (weeklyGoalMinutes - (weeklyTotals['thisWeek'] ?? 0)) / 60.0;
    return deficit < 0 ? 0 : deficit;
  }

  List<BurnoutSnapshot> get _sortedBurnoutHistory {
    final sorted = [...burnoutHistory];
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  List<BurnoutSnapshot> get _recentBurnoutSnapshots {
    final cutoff = _burnoutDay(DateTime.now()).subtract(const Duration(days: 14));
    return _sortedBurnoutHistory.where((entry) => entry.date.isAfter(cutoff)).toList();
  }

  List<BurnoutSnapshot> _burnoutWindow({required bool previous}) {
    final today = _burnoutDay(DateTime.now());
    final windowStart = previous
        ? today.subtract(const Duration(days: 14))
        : today.subtract(const Duration(days: 7));
    final windowEnd = previous
        ? today.subtract(const Duration(days: 7))
        : today.add(const Duration(days: 1));
    return _recentBurnoutSnapshots
        .where((entry) => entry.date.isAfter(windowStart) && entry.date.isBefore(windowEnd))
        .toList();
  }

  double _averageBurnoutScore(List<BurnoutSnapshot> snapshots) {
    if (snapshots.isEmpty) return burnoutScore;
    return snapshots.fold<double>(0.0, (sum, entry) => sum + entry.score) / snapshots.length;
  }

  double _averageDeficitHours(List<BurnoutSnapshot> snapshots) {
    if (snapshots.isEmpty) return weeklyDeficitHours;
    return snapshots.fold<double>(0.0, (sum, entry) => sum + entry.deficitHours) / snapshots.length;
  }

  double _averageConsistencyScore(List<BurnoutSnapshot> snapshots) {
    if (snapshots.isEmpty) return 100.0 - timeInconsistencyScore;
    return snapshots.fold<double>(0.0, (sum, entry) => sum + (100.0 - entry.inconsistencyScore)) / snapshots.length;
  }

  double get burnoutTrendDelta {
    return _averageBurnoutScore(_burnoutWindow(previous: false)) -
        _averageBurnoutScore(_burnoutWindow(previous: true));
  }

  String get burnoutTrendLabel {
    final delta = burnoutTrendDelta;
    if (delta > 5) return 'worsening';
    if (delta < -5) return 'improving';
    return 'stable';
  }

  bool get hasBurnoutTrendHistory => _recentBurnoutSnapshots.length >= 3;

  String burnoutTrendFallbackMessage(AppLocalizations l10n) {
    if (hasBurnoutTrendHistory) return l10n.burnoutTrendNoRecovery;
    return l10n.burnoutTrendNoHistory;
  }

  String get burnoutTrendDirection {
    final delta = burnoutTrendDelta;
    if (delta > 5) return '↑';
    if (delta < -5) return '↓';
    return '→';
  }

  double get deficitTrendDelta {
    return _averageDeficitHours(_burnoutWindow(previous: false)) -
        _averageDeficitHours(_burnoutWindow(previous: true));
  }

  String get deficitTrendLabel {
    final delta = deficitTrendDelta;
    if (delta > 0.25) return 'worsening';
    if (delta < -0.25) return 'improving';
    return 'stable';
  }

  String get deficitTrendDirection {
    final delta = deficitTrendDelta;
    if (delta > 0.25) return '↑';
    if (delta < -0.25) return '↓';
    return '→';
  }

  double get consistencyTrendDelta {
    return _averageConsistencyScore(_burnoutWindow(previous: false)) -
        _averageConsistencyScore(_burnoutWindow(previous: true));
  }

  String get consistencyTrendLabel {
    final score = 100 - timeInconsistencyScore;
    if (score < 40) return 'unstable';
    if (score < 70) return 'moderate';
    return 'stable';
  }

  String get consistencyTrendDirection {
    final delta = consistencyTrendDelta;
    if (delta > 5) return '↑';
    if (delta < -5) return '↓';
    return '→';
  }

  bool get recoveryDetected {
    return deficitTrendDelta < -0.25 && consistencyTrendDelta > 5;
  }

  String recoveryMessage(AppLocalizations l10n) {
    if (!recoveryDetected) return '';
    return l10n.recoveryMessage;
  }

  double get timeInconsistencyScore {
    if (trackedSessionCount == 0) return 0.0;
    return (100.0 - (dominantStudyShare * 100.0)).clamp(0.0, 100.0);
  }

  bool get irregularStudyPattern {
    return sessionsThisWeekCount >= 3 && timeInconsistencyScore >= 55.0;
  }

  bool get isStable => hasData && trend == "stable";
  
  String getFocusLabel(int minutes, AppLocalizations l10n) {
    if (minutes < 15) return l10n.lightFocus;
    if (minutes < 30) return l10n.goodFocus;
    if (minutes < 50) return l10n.deepFocus;
    return l10n.excellentDeepWork;
  }

  int calculateImpact(StudySession s) {
    final durationScore = (s.durationMinutes / 60) * 40;
    final completionScore = s.completed ? 30 : 0;
    return (durationScore + completionScore).round();
  }

  Map<String, int> get weeklyTotals {
    final now = DateTime.now();
    final startOfThisWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

    int thisWeek = 0;
    int lastWeek = 0;

    for (final s in sessions) {
      if (!s.createdAt.isBefore(startOfThisWeek)) {
        thisWeek += s.durationMinutes;
      } else if (s.createdAt.isAfter(startOfLastWeek) && s.createdAt.isBefore(startOfThisWeek)) {
        lastWeek += s.durationMinutes;
      }
    }

    return {
      'thisWeek': thisWeek,
      'lastWeek': lastWeek,
    };
  }

  double get weeklyChange {
    final totals = weeklyTotals;
    final int thisTotal = totals['thisWeek']!;
    final int lastTotal = totals['lastWeek']!;
    if (lastTotal == 0) return thisTotal > 0 ? -1.0 : 0.0;
    return ((thisTotal - lastTotal) / lastTotal) * 100;
  }

  double get weeklyGoalHours => weeklyGoalMinutes / 60.0;

  double get currentWeekHours => (weeklyTotals['thisWeek'] ?? 0) / 60.0;

  String getWeeklyStatus(AppLocalizations l10n) {
    final minutes = weeklyTotals['thisWeek']!;
    final activeDays = weeklyMinutes.values.where((m) => m > 0).length;
    
    if (minutes == 0) return l10n.noStudyActivityYet;
    if (activeDays == 1) return l10n.studiedOnlyOneDay;
    if (minutes < 60) return l10n.gettingStartedExtend;
    if (minutes < 180) {
      if (sessions.length >= 10) return l10n.studyConsistent;
      return l10n.buildingConsistency;
    }
    return l10n.strongConsistentPattern;
  }

  double get avgMoodThisWeek {
    final current = thisWeekSessions;
    final moods = current.where((s) => s.mood != null).map((s) => s.mood!).toList();
    if (moods.isEmpty) return 0.0;
    return moods.reduce((a, b) => a + b) / moods.length;
  }

  double get avgMoodLastWeek {
    final last = lastWeekSessions;
    final moods = last.where((s) => s.mood != null).map((s) => s.mood!).toList();
    if (moods.isEmpty) return 0.0;
    return moods.reduce((a, b) => a + b) / moods.length;
  }

  double get moodChangePercent {
    final current = avgMoodThisWeek;
    final last = avgMoodLastWeek;
    if (last == 0 || current == 0) return 0.0;
    return ((current - last) / last) * 100;
  }

  bool get isMoodStudyCorrelationDetected {
    final studyChange = weeklyChange; // percent
    final moodChange = moodChangePercent; // percent
    // Correlation detected if both dropped by more than 5%
    return studyChange < -5 && moodChange < -5;
  }

  String getPeakDay(AppLocalizations l10n) {
    final data = weeklyMinutes;
    if (data.values.every((v) => v == 0)) return l10n.noActivity;
    
    int maxMin = -1;
    int peakDay = 1;
    
    data.forEach((day, min) {
      if (min > maxMin) {
        maxMin = min;
        peakDay = day;
      }
    });

    final days = ['', l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday, l10n.friday, l10n.saturday, l10n.sunday];
    return "${days[peakDay]} (${formatDuration(maxMin, l10n)})";
  }

  int get currentStreak {
    if (sessions.isEmpty) return 0;

    final validSessions = sessions
        .where((s) => s.durationMinutes >= 10)
        .toList();

    if (validSessions.isEmpty) return 0;

    final days = validSessions
        .map((s) {
          final d = s.createdAt.toLocal();
          return DateTime(d.year, d.month, d.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime current = DateTime(today.year, today.month, today.day);

    if (!days.contains(current)) {
      current = current.subtract(const Duration(days: 1));
    }

    for (final day in days) {
      if (day == current) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        if (day.isAfter(current)) continue; 
        break;
      }
    }

    return streak;
  }

  String getStreakMessage(AppLocalizations l10n) {
    final streak = currentStreak;
    if (streak == 0) return l10n.startStreakToday;
    if (streak == 1) return l10n.streakDay1;
    if (streak < 4) return l10n.buildingConsistency;
    if (streak < 7) return l10n.strongHabitForming;
    return l10n.excellentDiscipline;
  }

  bool get studiedToday {
    final today = DateTime.now();
    return sessions.any((s) {
      final d = s.createdAt.toLocal();
      return d.year == today.year &&
             d.month == today.month &&
             d.day == today.day &&
             s.durationMinutes >= 10;
    });
  }

  bool get streakWarning {
    return currentStreak > 0 && !studiedToday;
  }

  double get weeklyGoalProgress => sessions.isNotEmpty 
      ? (weeklyTotals['thisWeek']! / weeklyGoalMinutes) 
      : 0.0;

  double get weeklyDeficitRatio {
    if (weeklyGoalHours <= 0) return 0.0;
    return (weeklyDeficitHours / weeklyGoalHours).clamp(0.0, 1.0);
  }

  bool get excessiveStudy {
    if (weeklyGoalHours <= 0) return false;
    return currentWeekHours > weeklyGoalHours * 1.15;
  }

  double get overloadRatio {
    if (weeklyGoalHours <= 0) return 0.0;
    final excess = currentWeekHours - weeklyGoalHours;
    if (excess <= 0) return 0.0;
    return (excess / weeklyGoalHours).clamp(0.0, 1.0);
  }

  String getBurnoutShortExplanation(AppLocalizations l10n) {
    if (sessions.length < 3) {
      return l10n.analyticsNotEnoughData;
    }

    if (burnoutLevel == BurnoutLevel.stable) {
      return l10n.burnoutShortExplanation;
    }
    
    // Trend forming message fix
    if (burnoutLevel != BurnoutLevel.stable && sessions.length < 7) {
        return l10n.burnoutTrendForming;
    }

    final sThisWeek = thisWeekSessions;
    final stresses = sThisWeek.where((s) => s.stress != null).map((s) => s.stress!).toList();
    final avgStressNow = stresses.isNotEmpty ? stresses.reduce((a, b) => a + b) / stresses.length : 0.0;

    if (avgStressNow >= 5 && timeInconsistencyScore >= 50) {
      return l10n.burnoutRisingStressInconsistentPattern;
    }

    switch (burnoutLevel) {
      case BurnoutLevel.warning:
        return l10n.burnoutRiskIncreasing;
      case BurnoutLevel.highRisk:
        return l10n.highRisk;
      case BurnoutLevel.burnoutRisk:
        return l10n.burnoutLevelBurnoutRisk;
      default:
        return l10n.notEnoughData;
    }
  }

  double _safeAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Map<String, dynamic> get moodDurationImpactDetails {
    final highMoodSessions = sessions
        .where((s) => s.mood != null && s.mood! >= 4)
        .map((s) => s.durationMinutes.toDouble())
        .toList();
    final lowMoodSessions = sessions
        .where((s) => s.mood != null && s.mood! <= 2.5)
        .map((s) => s.durationMinutes.toDouble())
        .toList();
    
    if (highMoodSessions.length < 2 || lowMoodSessions.length < 2) {
      return {'hasEnoughData': false, 'impact': 0};
    }
    
    final highAvg = _safeAverage(highMoodSessions);
    final lowAvg = _safeAverage(lowMoodSessions);
    
    return {
      'hasEnoughData': true,
      'impact': (highAvg - lowAvg).round(),
    };
  }

  double get burnoutScore {
    return burnoutScoreValue.clamp(0.0, 100.0);
  }

  BurnoutLevel get burnoutLevel {
    final score = burnoutScore;
    final stressDays = sessions.where((s) => (s.stress ?? 0) >= 7).map((s) => _burnoutDayKey(s.createdAt)).toSet().length;
    final hasHighStressSignals = avgSessionStress >= 7 && stressDays >= 3;

    if (score >= 75 && hasHighStressSignals) return BurnoutLevel.burnoutRisk;
    if (score >= 55 && hasHighStressSignals) return BurnoutLevel.highRisk;
    if (score >= 30) return BurnoutLevel.warning;
    return BurnoutLevel.stable;
  }

  List<String> getBurnoutReasons(AppLocalizations l10n) {
    final reasons = <String>[];
    
    // Stress Override: If stress is high, prioritize it and suppress deficit messages
    if (avgSessionStress >= 7) {
      reasons.add(l10n.burnoutReasonStress);
      if (hasMoodTrendDown) reasons.add(l10n.burnoutReasonMood);
      if (consistency < 0.6) reasons.add(l10n.burnoutReasonConsistency);
      return reasons;
    }

    if (weeklyDeficitHours > 10) reasons.add(l10n.burnoutReasonDeficit);
    if (avgSessionStress >= 5) reasons.add(l10n.burnoutReasonStress);
    if (consistency < 0.6) reasons.add(l10n.burnoutReasonConsistency);
    if (hasMoodTrendDown) reasons.add(l10n.burnoutReasonMood);
    return reasons;
  }

  List<String> getBurnoutRecommendations(AppLocalizations l10n) {
    // Stress Override: If stress is high, provide recovery-focused advice regardless of level
    if (avgSessionStress >= 7) {
      return [
        l10n.decisionHighStressOverrideBody,
        l10n.burnoutRecommendationHigh1, // Use some recovery focused ones
      ];
    }

    switch (burnoutLevel) {
      case BurnoutLevel.stable:
        return [
          l10n.burnoutRecStable1,
          l10n.burnoutRecStable2,
        ];
      case BurnoutLevel.warning:
        return [
          l10n.burnoutRecWarning1,
          l10n.burnoutRecWarning2,
        ];
      case BurnoutLevel.highRisk:
        return [
          l10n.burnoutRecHighRisk1,
          l10n.burnoutRecHighRisk2,
          l10n.burnoutRecHighRisk3,
        ];
      case BurnoutLevel.burnoutRisk:
        return [
          l10n.burnoutRecRisk1,
          l10n.burnoutRecRisk2,
          l10n.burnoutRecRisk3,
        ];
    }
  }

  int get burnoutBreakIntervalMinutes {
    switch (burnoutLevel) {
      case BurnoutLevel.stable:
        return breakPattern == 'pomodoro' ? 25 : 40;
      case BurnoutLevel.warning:
        return breakPattern == 'pomodoro' ? 20 : 30;
      case BurnoutLevel.highRisk:
        return 20;
      case BurnoutLevel.burnoutRisk:
        return 15;
    }
  }

  String formatDuration(int minutes, AppLocalizations l10n) {
    if (minutes >= 60) {
      return '${(minutes / 60).toStringAsFixed(1)}${l10n.hoursAbbreviation}';
    }
    return '$minutes${l10n.minutesAbbreviation}';
  }

  String getInsight(StudySession s, AppLocalizations l10n) {
    if (s.durationMinutes >= 45 && sessionsThisWeek >= 3) {
      return l10n.insightCycle;
    }
    if (s.durationMinutes < 25) {
      return l10n.insightStart;
    }
    return l10n.insightMomentum;
  }

  // --- INTELLIGENCE UPGRADES ---

  double sessionQualityScore(StudySession s) {
    // formula: (focusDuration * 0.6) + (mood * 10 * 0.2) - (stress * 5 * 0.2)
    final moodValue = s.mood ?? 3.0; // neutral default
    final stressValue = s.stress ?? 5.0; // neutral default
    return (s.durationMinutes * 0.6) + (moodValue * 10 * 0.2) - (stressValue * 5 * 0.2);
  }

  double get averageQualityScore {
    if (sessions.isEmpty) return 0.0;
    return sessions.map(sessionQualityScore).reduce((a, b) => a + b) / sessions.length;
  }

  double get successRate {
    if (sessions.isEmpty) return 1.0;
    final completed = sessions.where((s) => s.completed).length;
    return completed / sessions.length;
  }

  double get baselineStress {
    final last30 = sessions.take(30).where((s) => s.stress != null).map((s) => s.stress!).toList();
    if (last30.isEmpty) return 5.0;
    return last30.reduce((a, b) => a + b) / last30.length;
  }

  double get baselineMood {
    final last30 = sessions.take(30).where((s) => s.mood != null).map((s) => s.mood!).toList();
    if (last30.isEmpty) return 3.0;
    return last30.reduce((a, b) => a + b) / last30.length;
  }

  Map<String, dynamic> get studyProfile {
    // 1. Optimal Duration
    final qualityByDuration = <int, List<double>>{};
    for (var s in sessions) {
      final bin = (s.durationMinutes / 10).floor() * 10;
      qualityByDuration.putIfAbsent(bin, () => []).add(sessionQualityScore(s));
    }
    
    int optimalMin = 30;
    int optimalMax = 45;
    double maxQuality = -1.0;
    
    qualityByDuration.forEach((bin, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > maxQuality) {
        maxQuality = avg;
        optimalMin = bin;
        optimalMax = bin + 10;
      }
    });

    // Constrain profile range to adaptive system envelope (10-45 min).
    if (optimalMin > 45) {
      optimalMin = 35;
      optimalMax = 45;
    }
    if (optimalMin < 10) {
      optimalMin = 10;
      optimalMax = 20;
    }

    // 2. Stress Threshold
    double stressThreshold = 7.0;
    final qualityByStress = <int, List<double>>{};
    for (var s in sessions.where((s) => s.stress != null)) {
      final level = s.stress!.floor();
      qualityByStress.putIfAbsent(level, () => []).add(sessionQualityScore(s));
    }
    
    for (int i = 1; i <= 10; i++) {
        final scores = qualityByStress[i];
        if (scores != null && scores.isNotEmpty) {
            final avg = scores.reduce((a, b) => a + b) / scores.length;
            if (avg < 20) { // arbitrary quality drop threshold
                stressThreshold = i.toDouble();
                break;
            }
        }
    }

    // 3. Peak Window
    final qualityByHour = <int, List<double>>{};
    for (var s in sessions) {
      final hour = s.createdAt.toLocal().hour;
      qualityByHour.putIfAbsent(hour, () => []).add(sessionQualityScore(s));
    }
    
    int peakHour = 10;
    double maxHourQuality = -1.0;
    qualityByHour.forEach((hour, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > maxHourQuality) {
        maxHourQuality = avg;
        peakHour = hour;
      }
    });

    String window = 'Evening';
    if (peakHour < 12) window = 'Morning';
    else if (peakHour < 18) window = 'Afternoon';

    return {
      'optimalMin': optimalMin,
      'optimalMax': optimalMax,
      'stressThreshold': stressThreshold,
      'peakWindow': window,
      'peakHour': peakHour,
    };
  }
}

final studyAnalyticsProvider = Provider<StudyAnalytics>((ref) {
  final sessionsAsync = ref.watch(studySessionsProvider);
  final profileAsync = ref.watch(studentProfileProvider);
  final burnoutHistory = ref.watch(burnoutHistoryProvider);
  final analyticsData = ref.watch(analyticsProvider).valueOrNull;
  final profile = profileAsync.valueOrNull;
  final goalMinutes = ref.watch(weeklyStudyGoalHoursProvider) * 60;

  final analytics = sessionsAsync.maybeWhen(
    data: (sessions) => StudyAnalytics(
      sessions,
      goalMinutes,
      breakPattern: profile?.breakPattern ?? 'mixed',
      preferredStudyTime: profile?.preferredStudyTime ?? 'morning',
      burnoutHistory: burnoutHistory,
      avgDailyStress: analyticsData?.avgDailyStress ?? 0.0,
      avgSessionStress: analyticsData?.avgSessionStress ?? 0.0,
      hasMoodTrendDown: (analyticsData?.dailyMoodTrend ?? 'stable') == 'down',
      burnoutScoreValue: analyticsData?.burnoutScore ?? 0.0,
    ),
    orElse: () => StudyAnalytics(
      [],
      goalMinutes,
      breakPattern: profile?.breakPattern ?? 'mixed',
      preferredStudyTime: profile?.preferredStudyTime ?? 'morning',
      burnoutHistory: burnoutHistory,
      avgDailyStress: analyticsData?.avgDailyStress ?? 0.0,
      avgSessionStress: analyticsData?.avgSessionStress ?? 0.0,
      hasMoodTrendDown: (analyticsData?.dailyMoodTrend ?? 'stable') == 'down',
      burnoutScoreValue: analyticsData?.burnoutScore ?? 0.0,
    ),
  );

  ref.read(burnoutHistoryProvider.notifier).syncSnapshot(
    BurnoutSnapshot(
      date: DateTime.now(),
      score: analytics.burnoutScore,
      deficitHours: analytics.weeklyDeficitHours,
      inconsistencyScore: (1.0 - analytics.consistency) * 100.0,
    ),
  );

  return analytics;
});
