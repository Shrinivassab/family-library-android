class ReadingPlan {
  final String rawText;
  final DateTime generatedAt;

  ReadingPlan({
    required this.rawText,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}
