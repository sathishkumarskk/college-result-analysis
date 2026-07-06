class ResultSummary {
  const ResultSummary({
    required this.totalDepartments,
    required this.totalStudents,
    required this.totalSubjects,
    required this.passCount,
    required this.arrearCount,
  });

  final int totalDepartments;
  final int totalStudents;
  final int totalSubjects;
  final int passCount;
  final int arrearCount;
}
