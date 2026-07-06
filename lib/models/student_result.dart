import 'academic_year.dart';
import 'subject_result.dart';

enum ResultStatus { allClear, arrear }

enum ExamAttemptType { currentExam, arrearExam, unknown }

extension ResultStatusX on ResultStatus {
  String get label {
    switch (this) {
      case ResultStatus.allClear:
        return 'Pass';
      case ResultStatus.arrear:
        return 'Arrear';
    }
  }
}

class StudentResult {
  const StudentResult({
    required this.studentName,
    required this.registerNumber,
    required this.department,
    required this.subjects,
    this.semesterNumber,
    this.academicYearOverride,
    this.examAttemptType = ExamAttemptType.unknown,
  });

  final String studentName;
  final String registerNumber;
  final String department;
  final List<SubjectResult> subjects;
  final int? semesterNumber;
  final AcademicYear? academicYearOverride;
  final ExamAttemptType examAttemptType;

  ResultStatus get status => subjects.any((subject) => subject.isFailed)
      ? ResultStatus.arrear
      : ResultStatus.allClear;

  AcademicYear get academicYear =>
      academicYearOverride ?? academicYearFromSemester(semesterNumber);

  String get academicYearLabel => academicYear.label;

  String get statusLabel {
    if (status == ResultStatus.arrear) {
      return ResultStatus.arrear.label;
    }

    switch (examAttemptType) {
      case ExamAttemptType.currentExam:
        return 'Current Pass';
      case ExamAttemptType.arrearExam:
        return 'Arrear Exam Pass';
      case ExamAttemptType.unknown:
        return ResultStatus.allClear.label;
    }
  }

  bool get isCurrentExamStudent =>
      examAttemptType == ExamAttemptType.currentExam;

  bool get isArrearExamStudent => examAttemptType == ExamAttemptType.arrearExam;

  String get semesterLabel => semesterNumber == null
      ? 'Semester Unknown'
      : 'Semester ${semesterNumber!.toString().padLeft(2, '0')}';

  int get failedSubjectCount =>
      subjects.where((subject) => subject.isFailed).length;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    final subjectText = subjects
        .map(
          (subject) => [
            subject.code,
            subject.title,
            subject.mark ?? '',
            subject.grade ?? '',
            subject.result ?? '',
          ].join(' '),
        )
        .join(' ')
        .toLowerCase();

    return [
      studentName,
      registerNumber,
      department,
      academicYearLabel,
      semesterLabel,
      statusLabel,
      subjectText,
    ].join(' ').toLowerCase().contains(normalized);
  }

  StudentResult copyWith({
    AcademicYear? academicYearOverride,
    ExamAttemptType? examAttemptType,
  }) {
    return StudentResult(
      studentName: studentName,
      registerNumber: registerNumber,
      department: department,
      subjects: subjects,
      semesterNumber: semesterNumber,
      academicYearOverride: academicYearOverride ?? this.academicYearOverride,
      examAttemptType: examAttemptType ?? this.examAttemptType,
    );
  }
}
