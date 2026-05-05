import '../../models/ai_message.dart';

/// When structured [insight] / [recommendation] exist on [AiMessage.data],
/// the plain-text appendix should not duplicate them in the main bubble.
/// Strips only if [data] has both as non-empty strings; otherwise the full
/// [displayedText] is shown (no cut).
String aiAssistantMainBubbleText(AiMessage message) {
  final cut = _appendixCutIndex(message);
  if (cut == null) return message.displayedText;
  if (message.displayedText.length <= cut) return message.displayedText;
  return message.displayedText.substring(0, cut);
}

/// Body length when streaming completes (full text minus appendix).
String aiAssistantFinishedMainBody(AiMessage message) {
  final cut = _appendixCutIndex(message);
  if (cut == null) return message.text;
  return cut <= message.text.length ? message.text.substring(0, cut) : message.text;
}

int? _appendixCutIndex(AiMessage message) {
  final raw = message.data;
  if (raw is! Map) return null;
  final ins = raw['insight'];
  final rec = raw['recommendation'];
  if (ins is! String || rec is! String) return null;
  if (ins.trim().isEmpty || rec.trim().isEmpty) return null;
  final i = message.text.indexOf('\n\nInsight:\n');
  if (i < 0) return null;
  return i;
}
