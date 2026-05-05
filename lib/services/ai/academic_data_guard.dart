bool hasAcademicData({
  required List<dynamic> tasks,
  required List<dynamic> sessions,
}) {
  return tasks.isNotEmpty || sessions.isNotEmpty;
}

bool hasEnoughSignal({
  required List<dynamic> tasks,
  required List<dynamic> sessions,
}) {
  return tasks.length >= 2 || sessions.length >= 2;
}
