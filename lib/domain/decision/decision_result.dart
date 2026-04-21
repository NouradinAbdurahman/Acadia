enum DecisionType { warning, recommendation, insight }

class DecisionItem {
  final String messageKey;
  final DecisionType type;
  final int priority;

  const DecisionItem({
    required this.messageKey,
    required this.type,
    required this.priority,
  });
}

class DecisionResult {
  final List<DecisionItem> items;
  final int? suggestedSessionMinutes;
  final double confidence;

  const DecisionResult({
    this.items = const <DecisionItem>[],
    this.suggestedSessionMinutes,
    this.confidence = 0.0,
  });

  const DecisionResult.empty()
      : items = const <DecisionItem>[],
        suggestedSessionMinutes = null,
        confidence = 0.0;

  bool get hasContent => items.isNotEmpty;

  bool get hasDeadlinePressure =>
      items.any((item) => item.messageKey == 'decision_deadline_pressure');

  List<DecisionItem> get sortedItems {
    final sorted = [...items]..sort((a, b) {
      final p = a.priority.compareTo(b.priority);
      if (p != 0) return p;
      return a.type.index.compareTo(b.type.index);
    });
    return sorted;
  }

  DecisionItem? get primaryDecision {
    if (sortedItems.isEmpty) return null;
    return sortedItems.first;
  }

  List<DecisionItem> get secondaryDecisions {
    if (sortedItems.length <= 1) return const <DecisionItem>[];
    return sortedItems.skip(1).take(2).toList();
  }
}
