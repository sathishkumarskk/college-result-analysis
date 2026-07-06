class SubjectAnalysisEntry {
  const SubjectAnalysisEntry({
    required this.subjectCode,
    required this.subjectTitle,
    required this.semesterNumber,
    required this.studentCount,
    required this.attendedCount,
    required this.passCount,
    required this.failCount,
  });

  final String subjectCode;
  final String subjectTitle;
  final int? semesterNumber;
  final int studentCount;
  final int attendedCount;
  final int passCount;
  final int failCount;

  String get semesterLabel => semesterNumber == null
      ? 'Semester Unknown'
      : 'Semester ${semesterNumber!.toString().padLeft(2, '0')}';

  String get displayTitle =>
      subjectTitle.trim().isEmpty ? '—' : subjectTitle;

  double get passPercentage =>
      attendedCount == 0 ? 0 : (passCount / attendedCount) * 100;

  String get passPercentageLabel => '${passPercentage.toStringAsFixed(1)}%';
}
