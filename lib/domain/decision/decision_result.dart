enum DecisionType { warning, recommendation, insight }

class DecisionItem {
  final String titleKey;
  final String descriptionKey;
  final Map<String, dynamic>? params;
  final DecisionType type;
  final int priority;

  const DecisionItem({
    required this.titleKey,
    required this.descriptionKey,
    this.params,
    required this.type,
    required this.priority,
  });
}

class DecisionResult {
  final List<DecisionItem> items;
  final int? suggestedSessionMinutes;
  final double confidence;
  final double avgMood;
  final double avgStress;
  final String? emotionalStatusKey;
  final List<String> signals; // e.g. ['signal_stress_high', 'consistency_low']

  const DecisionResult({
    this.items = const <DecisionItem>[],
    this.suggestedSessionMinutes,
    this.confidence = 0.0,
    this.avgMood = 0.0,
    this.avgStress = 0.0,
    this.emotionalStatusKey,
    this.signals = const [],
  });

  const DecisionResult.empty()
      : items = const <DecisionItem>[],
        suggestedSessionMinutes = null,
        confidence = 0.0,
        avgMood = 0.0,
        avgStress = 0.0,
        emotionalStatusKey = null,
        signals = const [];

  bool get hasContent => items.isNotEmpty;

  bool get hasDeadlinePressure =>
      items.any((item) => item.titleKey == 'decision_deadline_pressure');

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
