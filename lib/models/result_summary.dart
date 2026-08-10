class ResultSummary {
  const ResultSummary({
    required this.totalDepartments,
    required this.totalStudents,
    required this.totalSubjects,
    required this.passCount,
    required this.arrearCount,
    required this.failureDepthCounts,
  });

  final int totalDepartments;
  final int totalStudents;
  final int totalSubjects;
  final int passCount;
  final int arrearCount;
  final Map<int, int> failureDepthCounts;

  int get oneArrearCount => failureDepthCounts[1] ?? 0;
  int get twoArrearCount => failureDepthCounts[2] ?? 0;
  int get threeArrearCount => failureDepthCounts[3] ?? 0;
  int get fourPlusArrearCount => failureDepthCounts.entries
      .where((entry) => entry.key >= 4)
      .fold<int>(0, (acc, entry) => acc + entry.value);
}
