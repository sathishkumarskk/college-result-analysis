import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;

import '../models/academic_year.dart';
import '../models/student_result.dart';
import 'file_saver.dart';

class ExcelExportService {
  String suggestedFileName({String? sourceName}) {
    final sourceStem = sourceName == null || sourceName.trim().isEmpty
        ? 'college_results'
        : '${p.basenameWithoutExtension(sourceName)}_analysis';
    final normalizedStem = sourceStem
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    return '${normalizedStem.isEmpty ? 'college_results' : normalizedStem}_$timestamp.xlsx';
  }

  Future<String> exportToExcel(
    List<StudentResult> students, {
    String? destinationPath,
    String? sourceName,
  }) async {
    print('Exporting ${students.length} students to Excel');
    final excel = Excel.createExcel();
    final sheet = excel['Results'];

    // Add headers
    sheet.appendRow([
      TextCellValue('Register Number'),
      TextCellValue('Student Name'),
      TextCellValue('Department'),
      TextCellValue('Year'),
      TextCellValue('Semester'),
      TextCellValue('Status'),
      TextCellValue('Subject Code'),
      TextCellValue('Subject Name'),
      TextCellValue('Grade'),
      TextCellValue('Result'),
    ]);

    // Add data
    for (final student in students) {
      print('Adding student: ${student.registerNumber}, ${student.studentName}, subjects: ${student.subjects.length}');
      for (final subject in student.subjects) {
        sheet.appendRow([
          TextCellValue(student.registerNumber),
          TextCellValue(student.studentName),
          TextCellValue(student.department),
          TextCellValue(student.academicYear.label),
          TextCellValue(student.semesterNumber?.toString() ?? ''),
          TextCellValue(student.status == ResultStatus.allClear ? 'All Clear' : 'Arrear'),
          TextCellValue(subject.code),
          TextCellValue(subject.title),
          TextCellValue(subject.grade ?? ''),
          TextCellValue(subject.result ?? ''),
        ]);
      }
    }

    final bytes = excel.encode();
    print('Excel bytes length: ${bytes?.length ?? 0}');
    if (bytes == null) {
      throw StateError('Unable to generate the Excel workbook.');
    }

    final fileName = suggestedFileName(sourceName: sourceName);
    return saveFileBytes(
      Uint8List.fromList(bytes),
      fileName: fileName,
      destinationPath: destinationPath,
    );
  }
}
