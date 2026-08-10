import 'package:collage_result/services/result_parser_service.dart';

void main() {
  final parser = ResultParserService();
  const rawText = '''
Register Number : 212221040005
Name : CURRENT PASS STUDENT
Branch : COMPUTER SCIENCE AND ENGINEERING
Semester Subject Code Grade Result
01 CS25C01 A+ PASS
01 CS25C02 A PASS
01 CS25C03 U RA
01 CS25C04 A PASS
01 CS25C05 U RA
''';

  final students = parser.parseFromRawText(rawText);
  print('students=${students.length}');
  for (final student in students) {
    print('student ${student.registerNumber} ${student.studentName} ${student.status} ${student.subjects.length}');
    for (final subject in student.subjects) {
      print('  ${subject.code} ${subject.grade} ${subject.result} title=${subject.title}');
    }
  }
}
