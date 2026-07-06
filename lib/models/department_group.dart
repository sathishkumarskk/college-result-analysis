import 'student_result.dart';

class DepartmentGroup {
  const DepartmentGroup({
    required this.departmentName,
    required this.passStudents,
    required this.arrearStudents,
  });

  final String departmentName;
  final List<StudentResult> passStudents;
  final List<StudentResult> arrearStudents;

  int get totalStudents => passStudents.length + arrearStudents.length;
}
