import 'package:collage_result/models/academic_year.dart';
import 'package:collage_result/models/exam_view_mode.dart';
import 'package:collage_result/models/student_result.dart';
import 'package:collage_result/models/student_status_filter.dart';
import 'package:collage_result/models/student_year_filter.dart';
import 'package:collage_result/models/subject_result.dart';
import 'package:collage_result/services/result_analyzer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResultAnalyzerService', () {
    final analyzer = ResultAnalyzerService();
    const students = [
      StudentResult(
        studentName: 'Anitha',
        registerNumber: '312525148001',
        department: 'AI & ML',
        semesterNumber: 1,
        subjects: [
          SubjectResult(
            code: 'CS25C01',
            title: '',
            grade: 'A+',
            result: 'PASS',
          ),
        ],
      ),
      StudentResult(
        studentName: 'Bharath',
        registerNumber: '312525148002',
        department: 'AI & ML',
        semesterNumber: 3,
        subjects: [
          SubjectResult(code: 'CS23C01', title: '', grade: 'U', result: 'RA'),
        ],
      ),
      StudentResult(
        studentName: 'Chandru',
        registerNumber: '312525148003',
        department: 'AI & ML',
        semesterNumber: 7,
        subjects: [
          SubjectResult(code: 'CS21C01', title: '', grade: 'A', result: 'PASS'),
        ],
      ),
    ];

    test('filters students by academic year', () {
      final firstYear = analyzer.filterStudents(
        students,
        examViewMode: ExamViewMode.currentExam,
        yearFilter: StudentYearFilter.firstYear,
      );
      final thirdYear = analyzer.filterStudents(
        students,
        examViewMode: ExamViewMode.currentExam,
        yearFilter: StudentYearFilter.fourthYear,
      );

      expect(firstYear, hasLength(1));
      expect(firstYear.first.studentName, 'Anitha');
      expect(thirdYear, hasLength(1));
      expect(thirdYear.first.studentName, 'Chandru');
    });

    test('combines year and status filters', () {
      final results = analyzer.filterStudents(
        students,
        examViewMode: ExamViewMode.currentExam,
        filter: StudentStatusFilter.arrear,
        yearFilter: StudentYearFilter.secondYear,
      );

      expect(results, hasLength(1));
      expect(results.first.studentName, 'Bharath');
      expect(results.first.status, ResultStatus.arrear);
    });

    test('splits current exam and arrear exam students accurately', () {
      const groupedStudents = [
        StudentResult(
          studentName: 'Current Pass Student',
          registerNumber: '312525148010',
          department: 'AI & ML',
          semesterNumber: 1,
          academicYearOverride: AcademicYear.firstYear,
          examAttemptType: ExamAttemptType.currentExam,
          subjects: [
            SubjectResult(
              code: 'CS25C01',
              title: '',
              grade: 'A+',
              result: 'PASS',
            ),
          ],
        ),
        StudentResult(
          studentName: 'Arrear Pass Student',
          registerNumber: '312524148010',
          department: 'AI & ML',
          semesterNumber: 1,
          academicYearOverride: AcademicYear.secondYear,
          examAttemptType: ExamAttemptType.arrearExam,
          subjects: [
            SubjectResult(
              code: 'CS25C01',
              title: '',
              grade: 'A',
              result: 'PASS',
            ),
          ],
        ),
        StudentResult(
          studentName: 'Arrear Student',
          registerNumber: '312524148011',
          department: 'AI & ML',
          semesterNumber: 1,
          academicYearOverride: AcademicYear.secondYear,
          examAttemptType: ExamAttemptType.arrearExam,
          subjects: [
            SubjectResult(code: 'CS25C01', title: '', grade: 'U', result: 'RA'),
          ],
        ),
      ];

      final currentExamStudents = analyzer.studentsForExamView(
        groupedStudents,
        examViewMode: ExamViewMode.currentExam,
      );
      final arrearExamStudents = analyzer.studentsForExamView(
        groupedStudents,
        examViewMode: ExamViewMode.arrearExam,
      );
      final currentExamGroup = analyzer
          .groupStudentsByDepartment(currentExamStudents)
          .single;
      final arrearExamGroup = analyzer
          .groupStudentsByDepartment(arrearExamStudents)
          .single;
      final currentExamSummary = analyzer.buildSummary(currentExamStudents);
      final arrearExamSummary = analyzer.buildSummary(arrearExamStudents);

      expect(currentExamStudents, hasLength(1));
      expect(arrearExamStudents, hasLength(2));
      expect(currentExamGroup.passStudents, hasLength(1));
      expect(currentExamGroup.arrearStudents, isEmpty);
      expect(arrearExamGroup.passStudents, hasLength(1));
      expect(arrearExamGroup.arrearStudents, hasLength(1));
      expect(currentExamSummary.passCount, 1);
      expect(currentExamSummary.arrearCount, 0);
      expect(arrearExamSummary.passCount, 1);
      expect(arrearExamSummary.arrearCount, 1);
    });

    test('counts unique subjects in summary instead of per-student rows', () {
      const repeatedSubjectStudents = [
        StudentResult(
          studentName: 'Student One',
          registerNumber: '312524148001',
          department: 'AI & ML',
          semesterNumber: 3,
          academicYearOverride: AcademicYear.secondYear,
          examAttemptType: ExamAttemptType.currentExam,
          subjects: [
            SubjectResult(
              code: 'CS3361',
              title: 'DATA SCIENCE',
              grade: 'A',
              result: 'PASS',
            ),
            SubjectResult(
              code: 'CS3381',
              title: 'AI LAB',
              grade: 'A+',
              result: 'PASS',
            ),
          ],
        ),
        StudentResult(
          studentName: 'Student Two',
          registerNumber: '312524148002',
          department: 'AI & ML',
          semesterNumber: 3,
          academicYearOverride: AcademicYear.secondYear,
          examAttemptType: ExamAttemptType.currentExam,
          subjects: [
            SubjectResult(
              code: 'CS3361',
              title: 'DATA SCIENCE',
              grade: 'B+',
              result: 'PASS',
            ),
            SubjectResult(
              code: 'CS3381',
              title: 'AI LAB',
              grade: 'A',
              result: 'PASS',
            ),
          ],
        ),
      ];

      final summary = analyzer.buildSummary(repeatedSubjectStudents);

      expect(summary.totalStudents, 2);
      expect(summary.totalSubjects, 2);
    });

    test('builds year-wise subject analysis rows', () {
      const subjectAnalysisStudents = [
        StudentResult(
          studentName: 'Student One',
          registerNumber: '312524148001',
          department: 'AI & ML',
          semesterNumber: 3,
          academicYearOverride: AcademicYear.secondYear,
          examAttemptType: ExamAttemptType.currentExam,
          subjects: [
            SubjectResult(
              code: 'CS3361',
              title: 'DATA SCIENCE',
              grade: 'A',
              result: 'PASS',
            ),
            SubjectResult(
              code: 'CS3381',
              title: 'AI LAB',
              grade: 'U',
              result: 'RA',
            ),
          ],
        ),
        StudentResult(
          studentName: 'Student Two',
          registerNumber: '312524148002',
          department: 'AI & ML',
          semesterNumber: 3,
          academicYearOverride: AcademicYear.secondYear,
          examAttemptType: ExamAttemptType.currentExam,
          subjects: [
            SubjectResult(
              code: 'CS3361',
              title: 'DATA SCIENCE',
              grade: 'AB',
              result: 'AB',
            ),
            SubjectResult(
              code: 'CS3381',
              title: 'AI LAB',
              grade: 'B+',
              result: 'PASS',
            ),
          ],
        ),
      ];

      final analysis = analyzer.buildSubjectAnalysis(
        subjectAnalysisStudents,
        academicYear: AcademicYear.secondYear,
      );
      final dataScience = analysis.firstWhere(
        (entry) => entry.subjectCode == 'CS3361',
      );
      final aiLab = analysis.firstWhere(
        (entry) => entry.subjectCode == 'CS3381',
      );

      expect(analysis, hasLength(2));
      expect(dataScience.studentCount, 2);
      expect(dataScience.attendedCount, 1);
      expect(dataScience.passCount, 1);
      expect(dataScience.failCount, 0);
      expect(dataScience.passPercentage, 100);

      expect(aiLab.studentCount, 2);
      expect(aiLab.attendedCount, 2);
      expect(aiLab.passCount, 1);
      expect(aiLab.failCount, 1);
      expect(aiLab.passPercentage, 50);
    });

    test('builds year-wise overall pass summary for subject analysis', () {
      const subjectAnalysisStudents = [
        StudentResult(
          studentName: 'Student One',
          registerNumber: '312524148001',
          department: 'AI & ML',
          semesterNumber: 3,
          academicYearOverride: AcademicYear.secondYear,
          examAttemptType: ExamAttemptType.currentExam,
          subjects: [
            SubjectResult(
              code: 'CS3361',
              title: 'DATA SCIENCE',
              grade: 'A',
              result: 'PASS',
            ),
          ],
        ),
        StudentResult(
          studentName: 'Student Two',
          registerNumber: '312524148002',
          department: 'AI & ML',
          semesterNumber: 3,
          academicYearOverride: AcademicYear.secondYear,
          examAttemptType: ExamAttemptType.currentExam,
          subjects: [
            SubjectResult(
              code: 'CS3361',
              title: 'DATA SCIENCE',
              grade: 'U',
              result: 'RA',
            ),
          ],
        ),
        StudentResult(
          studentName: 'Student Three',
          registerNumber: '312523148003',
          department: 'AI & ML',
          semesterNumber: 5,
          academicYearOverride: AcademicYear.thirdYear,
          examAttemptType: ExamAttemptType.currentExam,
          subjects: [
            SubjectResult(
              code: 'CS3561',
              title: 'ML',
              grade: 'A+',
              result: 'PASS',
            ),
          ],
        ),
      ];

      final overview = analyzer.buildSubjectAnalysisOverview(
        subjectAnalysisStudents,
        academicYear: AcademicYear.secondYear,
      );

      expect(overview.totalStudents, 2);
      expect(overview.passStudents, 1);
      expect(overview.passPercentage, 50);
      expect(overview.passRatioLabel, '1/2');
      expect(overview.passPercentageLabel, '50.0%');
    });
  });
}
