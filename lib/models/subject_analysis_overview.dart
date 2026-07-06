class SubjectAnalysisOverview {
  const SubjectAnalysisOverview({
    required this.totalStudents,
    required this.passStudents,
  });

  final int totalStudents;
  final int passStudents;

  double get passPercentage =>
      totalStudents == 0 ? 0 : (passStudents / totalStudents) * 100;

  String get passPercentageLabel => '${passPercentage.toStringAsFixed(1)}%';

  String get passRatioLabel => '$passStudents/$totalStudents';
}
