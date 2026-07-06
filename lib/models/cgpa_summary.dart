class SemesterGpa {
  const SemesterGpa({
    required this.semesterNumber,
    required this.gpa,
    required this.creditCount,
  });

  final int? semesterNumber;
  final double gpa;
  final int creditCount;

  String get label => semesterNumber == null
      ? 'Semester Unknown'
      : 'Semester ${semesterNumber!.toString().padLeft(2, '0')}';
}

class CgpaSummary {
  const CgpaSummary({
    required this.registerNumber,
    required this.studentName,
    required this.semesterGpas,
    required this.overallCgpa,
    required this.totalCredits,
    required this.earnedCredits,
    required this.classification,
  });

  final String registerNumber;
  final String studentName;
  final List<SemesterGpa> semesterGpas;
  final double overallCgpa;
  final int totalCredits;
  final int earnedCredits;
  final String classification;
}
