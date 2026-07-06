import 'dart:collection';

import '../models/academic_year.dart';
import '../models/department_group.dart';
import '../models/exam_view_mode.dart';
import '../models/result_summary.dart';
import '../models/subject_analysis_overview.dart';
import '../models/student_result.dart';
import '../models/student_status_filter.dart';
import '../models/student_year_filter.dart';
import '../models/subject_analysis_entry.dart';
import '../models/subject_result.dart';

class ResultAnalyzerService {
  List<StudentResult> studentsForExamView(
    List<StudentResult> students, {
    required ExamViewMode examViewMode,
  }) {
    final matchingStudents = students.where((student) {
      return switch (examViewMode) {
        ExamViewMode.currentExam => student.isCurrentExamStudent,
        ExamViewMode.arrearExam => student.isArrearExamStudent,
      };
    }).toList();

    if (matchingStudents.isNotEmpty) {
      return matchingStudents;
    }

    final hasKnownExamBuckets = students.any(
      (student) => student.isCurrentExamStudent || student.isArrearExamStudent,
    );

    return hasKnownExamBuckets || examViewMode == ExamViewMode.arrearExam
        ? const []
        : students;
  }

  List<StudentResult> filterStudents(
    List<StudentResult> students, {
    String query = '',
    StudentStatusFilter filter = StudentStatusFilter.all,
    StudentYearFilter yearFilter = StudentYearFilter.all,
    required ExamViewMode examViewMode,
  }) {
    final examViewStudents = studentsForExamView(
      students,
      examViewMode: examViewMode,
    );

    return examViewStudents.where((student) {
      final matchesQuery = student.matches(query);
      final matchesFilter = switch (filter) {
        StudentStatusFilter.all => true,
        StudentStatusFilter.allClear => student.status == ResultStatus.allClear,
        StudentStatusFilter.arrear => student.status == ResultStatus.arrear,
      };
      final targetAcademicYear = yearFilter.academicYear;
      final matchesYear = targetAcademicYear == null
          ? true
          : student.academicYear == targetAcademicYear;

      return matchesQuery && matchesFilter && matchesYear;
    }).toList();
  }

  List<DepartmentGroup> groupStudentsByDepartment(
    List<StudentResult> students,
  ) {
    final groupedStudents = SplayTreeMap<String, List<StudentResult>>();

    for (final student in students) {
      groupedStudents.putIfAbsent(student.department, () => []).add(student);
    }

    return groupedStudents.entries.map((entry) {
      final sortedStudents = [...entry.value]
        ..sort((a, b) => a.studentName.compareTo(b.studentName));

      return DepartmentGroup(
        departmentName: entry.key,
        passStudents: sortedStudents
            .where((student) => student.status == ResultStatus.allClear)
            .toList(),
        arrearStudents: sortedStudents
            .where((student) => student.status == ResultStatus.arrear)
            .toList(),
      );
    }).toList();
  }

  ResultSummary buildSummary(List<StudentResult> students) {
    return ResultSummary(
      totalDepartments: students
          .map((student) => student.department)
          .toSet()
          .length,
      totalStudents: students.length,
      totalSubjects: students
          .expand(
            (student) => student.subjects.map(
              (subject) =>
                  _subjectSummaryKey(student, subject.code, subject.title),
            ),
          )
          .toSet()
          .length,
      passCount: students
          .where((student) => student.status == ResultStatus.allClear)
          .length,
      arrearCount: students
          .where((student) => student.status == ResultStatus.arrear)
          .length,
    );
  }

  List<SubjectAnalysisEntry> buildSubjectAnalysis(
    List<StudentResult> students, {
    required AcademicYear academicYear,
  }) {
    final subjectGroups = SplayTreeMap<String, _SubjectAnalysisAccumulator>();

    for (final student in _studentsForAcademicYear(
      students,
      academicYear: academicYear,
    )) {
      for (final subject in student.subjects) {
        final key = _subjectSummaryKey(student, subject.code, subject.title);
        final accumulator = subjectGroups.putIfAbsent(
          key,
          () => _SubjectAnalysisAccumulator(
            subjectCode: subject.code.trim().toUpperCase(),
            subjectTitle: subject.title.trim(),
            semesterNumber: student.semesterNumber,
          ),
        );
        accumulator.register(subject);
      }
    }

    return subjectGroups.values
        .map((accumulator) => accumulator.build())
        .toList();
  }

  SubjectAnalysisOverview buildSubjectAnalysisOverview(
    List<StudentResult> students, {
    required AcademicYear academicYear,
  }) {
    final selectedYearStudents = _studentsForAcademicYear(
      students,
      academicYear: academicYear,
    );

    return SubjectAnalysisOverview(
      totalStudents: selectedYearStudents.length,
      passStudents: selectedYearStudents
          .where((student) => student.status == ResultStatus.allClear)
          .length,
    );
  }

  List<StudentResult> _studentsForAcademicYear(
    List<StudentResult> students, {
    required AcademicYear academicYear,
  }) {
    return students
        .where((student) => student.academicYear == academicYear)
        .toList();
  }

  String _subjectSummaryKey(StudentResult student, String code, String title) {
    final normalizedCode = code.trim().toUpperCase();
    final normalizedTitle = title.trim().toUpperCase();
    final semesterPart = student.semesterNumber?.toString() ?? 'unknown';

    return '$semesterPart|$normalizedCode|$normalizedTitle';
  }

  Map<String, int> getDepartmentSummary(List<StudentResult> students) {
    final summary = <String, int>{};
    for (final student in students) {
      summary[student.department] = (summary[student.department] ?? 0) + 1;
    }
    return summary;
  }

  Map<String, Map<String, int>> getDetailedDepartmentSummary(List<StudentResult> students) {
    final summary = <String, Map<String, int>>{};
    for (final student in students) {
      final dept = student.department;
      if (!summary.containsKey(dept)) {
        summary[dept] = {'All Clear': 0, 'Arrear': 0};
      }
      if (student.status == ResultStatus.allClear) {
        summary[dept]!['All Clear'] = summary[dept]!['All Clear']! + 1;
      } else {
        summary[dept]!['Arrear'] = summary[dept]!['Arrear']! + 1;
      }
    }
    return summary;
  }
}

class _SubjectAnalysisAccumulator {
  _SubjectAnalysisAccumulator({
    required this.subjectCode,
    required this.subjectTitle,
    required this.semesterNumber,
  });

  final String subjectCode;
  String subjectTitle;
  final int? semesterNumber;
  int studentCount = 0;
  int attendedCount = 0;
  int passCount = 0;
  int failCount = 0;

  void register(SubjectResult subject) {
    studentCount++;

    if (subjectTitle.trim().isEmpty && subject.title.trim().isNotEmpty) {
      subjectTitle = subject.title.trim();
    }

    if (subject.didAttendExam) {
      attendedCount++;
    }

    if (subject.isPassed) {
      passCount++;
    }

    if (subject.isFailedAfterAttending) {
      failCount++;
    }
  }

  SubjectAnalysisEntry build() {
    return SubjectAnalysisEntry(
      subjectCode: subjectCode,
      subjectTitle: subjectTitle,
      semesterNumber: semesterNumber,
      studentCount: studentCount,
      attendedCount: attendedCount,
      passCount: passCount,
      failCount: failCount,
    );
  }
}
