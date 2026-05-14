import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Triggers the native in-app review prompt at positive moments.
///
/// Apple silently rate-limits to ~3 prompts per year; this service adds a
/// 90-day local cooldown so we never pointlessly call the API while the OS
/// is suppressing it. All counters are SharedPreferences-backed.
class ReviewService {
  static const _keyLaunchCount = 'review_launch_count';
  static const _keySessionCount = 'review_session_count';
  static const _keyTaskCount = 'review_task_count';
  static const _keyLastShownMs = 'review_last_shown_ms';

  // Thresholds before asking
  static const _launchThreshold = 7;
  static const _sessionThreshold = 3;
  static const _taskThreshold = 5;

  // 90 days between prompts
  static const _cooldownDays = 90;

  // ── Public call sites ──────────────────────────────────────────────────

  static Future<void> onAppLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyLaunchCount) ?? 0) + 1;
    await prefs.setInt(_keyLaunchCount, count);
    if (count == _launchThreshold) {
      await _maybeRequest(prefs);
    }
  }

  /// Call after a study session is successfully persisted.
  static Future<void> onSessionCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keySessionCount) ?? 0) + 1;
    await prefs.setInt(_keySessionCount, count);
    if (count == _sessionThreshold) {
      await _maybeRequest(prefs);
    }
  }

  /// Call after a task is marked as completed.
  static Future<void> onTaskCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyTaskCount) ?? 0) + 1;
    await prefs.setInt(_keyTaskCount, count);
    if (count == _taskThreshold) {
      await _maybeRequest(prefs);
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────

  static Future<void> _maybeRequest(SharedPreferences prefs) async {
    if (!_cooldownPassed(prefs)) return;

    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;

      await prefs.setInt(
        _keyLastShownMs,
        DateTime.now().millisecondsSinceEpoch,
      );
      await review.requestReview();
    } catch (e) {
      debugPrint('[ReviewService] requestReview failed: $e');
    }
  }

  static bool _cooldownPassed(SharedPreferences prefs) {
    final lastMs = prefs.getInt(_keyLastShownMs);
    if (lastMs == null) return true;
    final daysSince = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastMs))
        .inDays;
    return daysSince >= _cooldownDays;
  }
}
