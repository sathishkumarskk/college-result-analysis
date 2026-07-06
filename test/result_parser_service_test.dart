import 'package:collage_result/models/student_result.dart';
import 'package:collage_result/services/result_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResultParserService', () {
    final parser = ResultParserService();

    test('detects Anna University result text markers', () {
      const rawText = '''
ANNA UNIVERSITY :: CHENNAI - 600025.
OFFICE OF THE CONTROLLER OF EXAMINATIONS
Provisional Results of Nov. / Dec. Examination,2025.
Branch : Computer Science and Engineering
Reg. Number
312525148001
Stud. Name
ABDULVASHIEF S
Subject Code
CS25C01
Grade
A+
PASS
''';

      expect(parser.hasAnnaUniversityResultIndicators(rawText), isTrue);
      expect(parser.looksLikeSupportedAnnaUniversityResult(rawText), isTrue);
    });

    test('rejects unrelated pdf text as unsupported result format', () {
      const rawText = '''
INVOICE
Customer Name : Prawin
Item Description : Laptop service charge
Amount : 2500
Date : 30-03-2026
''';

      expect(parser.hasAnnaUniversityResultIndicators(rawText), isFalse);
      expect(parser.looksLikeSupportedAnnaUniversityResult(rawText), isFalse);
      expect(parser.parseFromRawText(rawText), isEmpty);
    });

    test('parses Anna University grade/result rows', () {
      const rawText = '''
ANNA UNIVERSITY
Register Number : 212221040001
Name : PRIYA R
Branch : COMPUTER SCIENCE AND ENGINEERING
Semester Subject Code Grade Result
01 HS3152 A+ PASS
01 MA3151 A PASS
01 CY3151 U RA
''';

      final students = parser.parseFromRawText(rawText);

      expect(students, hasLength(1));
      expect(students.first.studentName, 'PRIYA R');
      expect(students.first.registerNumber, '212221040001');
      expect(students.first.department, 'COMPUTER SCIENCE AND ENGINEERING');
      expect(students.first.status, ResultStatus.arrear);
      expect(students.first.subjects, hasLength(3));
      expect(students.first.subjects.first.code, 'HS3152');
      expect(students.first.subjects.first.grade, 'A+');
      expect(students.first.subjects.first.result, 'PASS');
    });

    test(
      'parses Anna University rows with subject names and wrapped lines',
      () {
        const rawText = '''
Register Number : 212221040002
Name : ARUN KUMAR S
Branch of Study : INFORMATION TECHNOLOGY
S.No Subject Code Subject Name Credits Grade Result
1 CS3452 THEORY OF
COMPUTATION 4 A+ PASS
2 CS3491 ARTIFICIAL INTELLIGENCE 3 O PASS
3 MA3354 DISCRETE MATHEMATICS 4 U RA
''';

        final students = parser.parseFromRawText(rawText);

        expect(students, hasLength(1));
        expect(students.first.status, ResultStatus.arrear);
        expect(students.first.subjects, hasLength(3));
        expect(
          students.first.subjects.first.displayTitle,
          'THEORY OF COMPUTATION',
        );
        expect(
          students.first.subjects[1].displayTitle,
          'ARTIFICIAL INTELLIGENCE',
        );
        expect(students.first.subjects.last.result, 'RA');
      },
    );

    test('still parses bundled dummy data', () {
      final students = parser.parseDemoData();

      expect(students, hasLength(4));
      expect(
        students.where((student) => student.status == ResultStatus.arrear),
        hasLength(2),
      );
    });

    test('parses flattened extracted text with smart line breaks', () {
      const rawText = '''
Register Number : 212221040003 Name : KEERTHANA S Branch : ELECTRONICS AND COMMUNICATION ENGINEERING Semester Subject Code Grade Result 01 EC3151 B+ PASS 02 MA3151 A PASS 03 CY3151 U RA Register Number : 212221040004 Name : VIGNESH M Branch : ELECTRONICS AND COMMUNICATION ENGINEERING Semester Subject Code Grade Result 01 EC3151 A PASS 02 MA3151 B+ PASS 03 CY3151 A PASS
''';

      final students = parser.parseFromRawText(rawText);

      expect(students, hasLength(2));
      expect(students.first.registerNumber, '212221040003');
      expect(students.first.status, ResultStatus.arrear);
      expect(students.last.registerNumber, '212221040004');
      expect(students.last.status, ResultStatus.allClear);
    });

    test('parses Anna University tabular branch results', () {
      const rawText = '''
ANNA UNIVERSITY :: CHENNAI - 600025.
OFFICE OF THE CONTROLLER OF EXAMINATIONS
Provisional Results of Nov. / Dec. Examination,2025.
Page 1/1
Inst.Code/Name : 3125 - T.J. INSTITUTE OF TECHNOLOGY Semester No. : 01 DATE OF PUBLICATION : 13-03-2026
Branch : 148-B.E. Computer Science and Engineering (Artificial Intelligence and Machine Learning)
Subject Code - >
CS25
C01
CS25
C03
CY25
C01
MA31
51
UC25
A01
Reg. Number
Stud. Name
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
312525148001
ABDULVASHIEF S
U
U
U
B
S
312525148002
AKASRI I
B+
B+
A
A+
S
W - Withdrawal
''';

      final students = parser.parseFromRawText(rawText);

      expect(students, hasLength(2));
      expect(
        students.first.department,
        contains('Computer Science and Engineering'),
      );
      expect(students.first.status, ResultStatus.arrear);
      expect(students.last.status, ResultStatus.allClear);
      expect(students.first.subjects.first.code, 'CS25C01');
      expect(students.last.subjects[1].grade, 'B+');
      expect(students.first.semesterNumber, 1);
      expect(students.first.academicYearLabel, 'First Year');
    });

    test('separates current pass and arrear pass for the same semester', () {
      const rawText = '''
ANNA UNIVERSITY :: CHENNAI - 600025.
OFFICE OF THE CONTROLLER OF EXAMINATIONS
Provisional Results of Nov. / Dec. Examination,2025.
Page 1/1
Inst.Code/Name : 3125 - T.J. INSTITUTE OF TECHNOLOGY Semester No. : 01 DATE OF PUBLICATION : 13-03-2026
Branch : 148-B.E. Computer Science and Engineering (Artificial Intelligence and Machine Learning)
Subject Code - >
CS25
C01
MA31
51
Reg. Number
Stud. Name
Grad
e
Grad
e
312525148001
CURRENT STUDENT
A+
A
312524148001
ARREAR PASS STUDENT
B+
A+
W - Withdrawal
''';

      final students = parser.parseFromRawText(rawText);

      expect(students, hasLength(2));

      final currentStudent = students.firstWhere(
        (student) => student.registerNumber == '312525148001',
      );
      final arrearPassStudent = students.firstWhere(
        (student) => student.registerNumber == '312524148001',
      );

      expect(currentStudent.status, ResultStatus.allClear);
      expect(currentStudent.examAttemptType, ExamAttemptType.currentExam);
      expect(currentStudent.academicYearLabel, 'First Year');
      expect(currentStudent.statusLabel, 'Current Pass');

      expect(arrearPassStudent.status, ResultStatus.allClear);
      expect(arrearPassStudent.examAttemptType, ExamAttemptType.arrearExam);
      expect(arrearPassStudent.academicYearLabel, 'Second Year');
      expect(arrearPassStudent.statusLabel, 'Arrear Exam Pass');
    });

    test('classifies arrear-only rows using the exam year in the PDF', () {
      const rawText = '''
ANNA UNIVERSITY :: CHENNAI - 600025.
OFFICE OF THE CONTROLLER OF EXAMINATIONS
Provisional Results of Nov. / Dec. Examination,2025.
Page 1/1
Inst.Code/Name : 3125 - T.J. INSTITUTE OF TECHNOLOGY Semester No. : 01 DATE OF PUBLICATION : 13-03-2026
Branch : 148-B.E. Computer Science and Engineering
Subject Code - >
CS25
C01
MA31
51
Reg. Number
Stud. Name
Grad
e
Grad
e
312524148051
OLDER BATCH PASS
A
B+
312523148052
OLDER BATCH ARREAR
U
A
W - Withdrawal
''';

      final students = parser.parseFromRawText(rawText);

      final passStudent = students.firstWhere(
        (student) => student.registerNumber == '312524148051',
      );
      final arrearStudent = students.firstWhere(
        (student) => student.registerNumber == '312523148052',
      );

      expect(passStudent.examAttemptType, ExamAttemptType.arrearExam);
      expect(passStudent.statusLabel, 'Arrear Exam Pass');
      expect(passStudent.academicYearLabel, 'Second Year');

      expect(arrearStudent.examAttemptType, ExamAttemptType.arrearExam);
      expect(arrearStudent.status, ResultStatus.arrear);
      expect(arrearStudent.academicYearLabel, 'Third Year');
    });

    test('treats even semesters in Nov Dec results as arrear exam rows', () {
      const rawText = '''
ANNA UNIVERSITY :: CHENNAI - 600025.
OFFICE OF THE CONTROLLER OF EXAMINATIONS
Provisional Results of Nov. / Dec. Examination,2025.
Page 1/1
Inst.Code/Name : 3125 - T.J. INSTITUTE OF TECHNOLOGY Semester No. : 04 DATE OF PUBLICATION : 13-03-2026
Branch : 148-B.E. Computer Science and Engineering
Subject Code - >
AD3391
AL3391
AL3451
CS3452
GE3451
Reg. Number
Stud. Name
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
312523148001
ABISHA S
U
UA
UA
UA
UA
312524148010
VARSHA R
A
B+
A
A
B
W - Withdrawal
''';

      final students = parser.parseFromRawText(rawText);

      final abisha = students.firstWhere(
        (student) => student.registerNumber == '312523148001',
      );
      final varsha = students.firstWhere(
        (student) => student.registerNumber == '312524148010',
      );

      expect(abisha.examAttemptType, ExamAttemptType.arrearExam);
      expect(abisha.academicYearLabel, 'Third Year');
      expect(abisha.status, ResultStatus.arrear);

      expect(varsha.examAttemptType, ExamAttemptType.arrearExam);
      expect(varsha.academicYearLabel, 'Second Year');
      expect(varsha.statusLabel, 'Arrear Exam Pass');
    });

    test('parses the pasted Anna University first-page table layout', () {
      const rawText = '''
ANNA UNIVERSITY :: CHENNAI - 600025.
OFFICE OF THE CONTROLLER OF EXAMINATIONS
Provisional Results of Nov. / Dec. Examination,2025.
Page 1/5

Inst.Code/Name : 3125 - T.J. INSTITUTE OF TECHNOLOGY Semester No. : 01 DATE OF PUBLICATION :13-03-2026
Branch : 148-B.E. Computer Science and Engineering (Artificial Intelligence and Machine Learning)

Subject Code - >
CS25
C01
CS25
C03
CY25
C01
CY31
51
EN25
C01
GE31
51
MA25
C01
MA31
51
ME25
C04
PH25
C01
PH31
51
UC25
A01
UC25
A02
UC25
H01
Reg. Number
Stud. Name
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e
Grad
e

312523148001
ABISHA S
UA
UA
UA
UA

312524148001
ANNUSHRI C
UA

312524148002
BIRUNDHA V
UA

312525148001
ABDULVASHIEF S
U
U
U
B
U
A+
U
S
S
U
312525148002
AKASRI I
B+
B+
B+
A+
U
S
A
S
S
A+
312525148003
ASHOK S
U
U
U
B
U
A+
U
S
S
B
312525148004
LINGESH R
U
U
U
A
U
S
U
S
S
B+
312525148005
MANISHA K
U
B+
B+
A
U
S
B+
S
S
A
312525148006
SELVADURAI M

312525148007
SOWRAV SHARMA A
U
U
B+
A+
B
S
A
S
S
U
312525148008
VARSHINI M
A
B+
A
A
B
S
A
S
S
B
312525148009
VIGNESH T
A
A
A
A
A
S
A
S
S
U

W - Withdrawal I - Inadequate Attendance
Anna University - COE
14-03-2026
''';

      final students = parser.parseFromRawText(rawText);

      expect(students.length, greaterThanOrEqualTo(9));
      expect(
        students.first.department,
        contains('Computer Science and Engineering'),
      );
      expect(students.first.subjects.first.code, 'CS25C01');
      expect(
        students
            .firstWhere((student) => student.registerNumber == '312525148002')
            .status,
        ResultStatus.arrear,
      );
      expect(
        students
            .firstWhere((student) => student.registerNumber == '312525148008')
            .status,
        ResultStatus.allClear,
      );
      expect(
        students
            .firstWhere((student) => student.registerNumber == '312525148009')
            .academicYearLabel,
        'First Year',
      );
    });
  });
}
