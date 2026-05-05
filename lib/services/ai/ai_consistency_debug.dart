import 'package:flutter/foundation.dart';

import '../../models/ai_message.dart';
import '../../models/analytics_data.dart';
import '../../domain/adaptive/adaptive_profile.dart';
import '../../domain/risk/risk_state.dart';
import 'academic_insight_layer.dart';

/// Debug-only: compares deterministic Dart insight/recommendation with the
/// assistant [message] payload (local resolver or Edge). Does not alter behavior.
void logAiDeterministicConsistency({
  required AiMessage message,
  required AnalyticsData? analytics,
  required RiskState riskState,
  required AdaptiveProfile adaptiveProfile,
  required double burnoutRisk,
}) {
  if (!kDebugMode) return;
  if (analytics == null || !analytics.hasData) return;

  // Keep debug reference identical to resolver source of truth.
  final effectiveRisk = riskState.hasData
      ? riskState.result.totalScore
      : analytics.riskScore;
  final studyDeficit = analytics.studyDeficit;

  final refInput = AcademicInsightInput.fromAnalytics(
    data: analytics,
    riskScoreOverride: effectiveRisk,
    riskTrendDelta: riskState.hasData ? riskState.trendDelta : null,
    adaptiveProfile: adaptiveProfile,
    burnoutRisk: burnoutRisk,
  );
  final refParts = refInput.parts;

  debugPrint(
    '[AI CONSISTENCY] riskScore=${effectiveRisk.toStringAsFixed(1)} '
    'studyDeficit=${studyDeficit.toStringAsFixed(2)}',
  );
  debugPrint('[AI CONSISTENCY] Dart insight: ${refParts.insight}');
  debugPrint('[AI CONSISTENCY] Dart recommendation: ${refParts.recommendation}');

  final extracted = _extractMessageInsightPair(message);
  if (extracted == null) {
    debugPrint(
      '[AI CONSISTENCY] message has no structured insight/recommendation '
      '(skip compare)',
    );
    return;
  }

  debugPrint('[AI CONSISTENCY] Message insight: ${extracted.$1}');
  debugPrint('[AI CONSISTENCY] Message recommendation: ${extracted.$2}');

  final iMatch = _norm(refParts.insight) == _norm(extracted.$1);
  final rMatch = _norm(refParts.recommendation) == _norm(extracted.$2);
  if (!iMatch || !rMatch) {
    debugPrint(
      '[AI CONSISTENCY WARNING] Dart reference vs message mismatch '
      '(insight match=$iMatch, recommendation match=$rMatch)',
    );
  }
}

(String, String)? _extractMessageInsightPair(AiMessage message) {
  final raw = message.data;
  if (raw is Map) {
    final i = raw['insight'];
    final r = raw['recommendation'];
    if (i is String &&
        r is String &&
        i.trim().isNotEmpty &&
        r.trim().isNotEmpty) {
      return (i.trim(), r.trim());
    }
  }
  return _parseAppendixFromText(message.text);
}

(String, String)? _parseAppendixFromText(String text) {
  const ins = '\n\nInsight:\n';
  const rec = '\n\nRecommendation:\n';
  final i0 = text.indexOf(ins);
  if (i0 < 0) return null;
  final r0 = text.indexOf(rec, i0 + ins.length);
  if (r0 < 0) return null;
  final insight = text.substring(i0 + ins.length, r0).trim();
  var rest = text.substring(r0 + rec.length).trim();
  if (insight.isEmpty || rest.isEmpty) return null;
  final next = rest.indexOf('\n\n');
  if (next >= 0) rest = rest.substring(0, next).trim();
  if (rest.isEmpty) return null;
  return (insight, rest);
}

String _norm(String s) {
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}
