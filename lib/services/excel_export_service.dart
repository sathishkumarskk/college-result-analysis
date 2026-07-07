import 'dart:math';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;

import '../models/academic_year.dart';
import '../models/student_result.dart';
import '../services/result_analyzer_service.dart';
import 'file_saver.dart';

class ExcelExportService {
  // -----------------
  // File name helpers
  // -----------------
  String suggestedFileName({String? sourceName}) {
    final sourceStem = sourceName == null || sourceName.trim().isEmpty
        ? 'college_results'
        : '${p.basenameWithoutExtension(sourceName)}_analysis';
    final normalizedStem = _normalizeStem(sourceStem);
    final timestamp = _timestamp();

    return '${normalizedStem.isEmpty ? 'college_results' : normalizedStem}_$timestamp.xlsx';
  }

  String suggestedFileNameAdvanced({
    String? sourceName,
    String examViewLabel = 'Mixed',
    double? passRate,
  }) {
    final stem = sourceName == null || sourceName.trim().isEmpty
        ? 'college_results'
        : p.basenameWithoutExtension(sourceName);
    final parts = <String>[_normalizeStem(stem), _normalizeStem(examViewLabel)];
    if (passRate != null) {
      parts.add('pass_${passRate.toStringAsFixed(1)}pct');
    }
    parts.add(_timestamp());
    return '${parts.where((e) => e.isNotEmpty).join('_')}.xlsx';
  }

  String _normalizeStem(String value) => value
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '')
      .toLowerCase();

  String _timestamp() => DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');

  // -----------------
  // Public API
  // -----------------
  Future<String> exportWorkbook({
    required List<StudentResult> students,
    String? destinationPath,
    String? sourceName,
    required String examViewLabel,
    required AcademicYear analysisYear,
    String? extractionModeLabel,
    int? pageCount,
    bool anonymize = false,
    bool splitByDepartment = false,
  }) async {
    final analyzer = ResultAnalyzerService();

    final excel = Excel.createExcel();

    // Core derived data
    final totalStudents = students.length;
    final passCount = students
        .where((s) => s.status == ResultStatus.allClear)
        .length;
    final passRate = totalStudents == 0
        ? 0.0
        : (passCount / totalStudents) * 100.0;
    final parseCoverage = totalStudents == 0
        ? 0.0
        : (students.where((s) => s.subjects.isNotEmpty).length /
                  totalStudents) *
              100.0;

    final subjectAnalysis = analyzer.buildSubjectAnalysis(
      students,
      academicYear: analysisYear,
    );
    final overviewModel = analyzer.buildSubjectAnalysisOverview(
      students,
      academicYear: analysisYear,
    );

    // Overview sheet (write to default Sheet1 so Excel opens with data visible)
    final overview = excel['Sheet1'];
    overview.appendRow([_txt('Metric'), _txt('Value')]);
    final selectedYearLabel = analysisYear == AcademicYear.unknown
        ? 'All Years'
        : analysisYear.label;
    final overviewRows = [
      ['Exam View', examViewLabel],
      ['Selected Year', selectedYearLabel],
      ['Total Students', '$totalStudents'],
      ['Pass Students', '$passCount'],
      ['Pass Rate', '${passRate.toStringAsFixed(1)}%'],
      ['Parse Coverage', '${parseCoverage.toStringAsFixed(1)}%'],
      if (extractionModeLabel != null) ['Extraction Mode', extractionModeLabel],
      if (pageCount != null) ['PDF Pages', '$pageCount'],
      ['Subjects (selected year)', '${subjectAnalysis.length}'],
      ['All Clear (selected year)', overviewModel.passRatioLabel],
      ['Overall Pass % (selected year)', overviewModel.passPercentageLabel],
      if (sourceName != null) ['Source', sourceName],
    ];
    for (final row in overviewRows) {
      overview.appendRow([_txt(row[0]), _txt(row[1])]);
    }
    _autoFit(overview, columns: 2);

    // Department Summary sheet
    final deptSheet = _ensureSheet(excel, 'Department Summary');
    deptSheet.appendRow([
      _txt('Department'),
      _txt('Entries'),
      _txt('Pass'),
      _txt('Arrear'),
      _txt('Pass %'),
    ]);

    final byDept = <String, Map<String, int>>{};
    for (final s in students) {
      final d = s.department;
      byDept.putIfAbsent(d, () => {'All Clear': 0, 'Arrear': 0});
      if (s.status == ResultStatus.allClear) {
        byDept[d]!['All Clear'] = byDept[d]!['All Clear']! + 1;
      } else {
        byDept[d]!['Arrear'] = byDept[d]!['Arrear']! + 1;
      }
    }
    for (final entry in byDept.entries) {
      final total = entry.value['All Clear']! + entry.value['Arrear']!;
      final pr = total == 0 ? 0.0 : (entry.value['All Clear']! / total) * 100;
      deptSheet.appendRow([
        _txt(entry.key),
        _txt('$total'),
        _txt('${entry.value['All Clear']}'),
        _txt('${entry.value['Arrear']}'),
        _txt('${pr.toStringAsFixed(1)}%'),
      ]);
    }
    _autoFit(deptSheet, columns: 5);

    // Subject Analysis sheet (for selected year)
    final subjSheet = _ensureSheet(excel, 'Subject Analysis');
    subjSheet.appendRow([
      _txt('Subject Code'),
      _txt('Title'),
      _txt('Semester'),
      _txt('Students'),
      _txt('Attended'),
      _txt('Pass'),
      _txt('Fail'),
      _txt('Pass %'),
    ]);

    for (final e in subjectAnalysis) {
      final passPct = e.passPercentage;
      subjSheet.appendRow([
        _txt(e.subjectCode),
        _txt(e.displayTitle),
        _txt(e.semesterLabel),
        _txt('${e.studentCount}'),
        _txt('${e.attendedCount}'),
        _txt('${e.passCount}'),
        _txt('${e.failCount}'),
        _txt('${passPct.toStringAsFixed(1)}%'),
      ]);
    }
    _autoFit(subjSheet, columns: 8);

    // Students (detailed) sheet
    final studentsSheet = _ensureSheet(excel, 'Students');
    studentsSheet.appendRow([
      _txt('Register Number'),
      _txt('Student Name'),
      _txt('Department'),
      _txt('Year'),
      _txt('Semester'),
      _txt('Status'),
      _txt('Subject Code'),
      _txt('Subject Name'),
      _txt('Grade'),
      _txt('Result'),
    ]);

    for (final s in students) {
      final reg = anonymize
          ? _maskRegister(s.registerNumber)
          : s.registerNumber;
      final name = anonymize ? _maskName(s.studentName) : s.studentName;
      final status = s.statusLabel;
      for (final sub in s.subjects) {
        studentsSheet.appendRow([
          _txt(reg),
          _txt(name),
          _txt(s.department),
          _txt(s.academicYearLabel),
          _txt(s.semesterNumber?.toString() ?? ''),
          _txt(s.statusLabel),
          _txt(sub.code),
          _txt(sub.title),
          _txt(sub.grade ?? ''),
          _txt(sub.result ?? ''),
        ]);
      }
    }
    _autoFit(studentsSheet, columns: 10);

    // Styling approximations (no real conditional formatting in excel package)
    // - Color Subject Analysis Pass % cells by threshold
    for (var row = 1; row < subjSheet.maxRows; row++) {
      final cell = subjSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
      );
      final dynamic raw = cell.value;
      final String text = raw is TextCellValue
          ? raw.value.toString()
          : raw?.toString() ?? '';
      final pct = double.tryParse(text.replaceAll('%', '')) ?? 0.0;
      // Note: Conditional styling not applied due to excel 4.x API limitations.
      // Keep computing pct to validate values and avoid analyzer warnings.
      pct.toString();
    }

    // - Color Students Result column cells: PASS/Arrear/RA
    for (var row = 1; row < studentsSheet.maxRows; row++) {
      final cell = studentsSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
      );
      final dynamic raw = cell.value;
      final String text = raw is TextCellValue
          ? raw.value.toString()
          : raw?.toString() ?? '';
      final up = text.toUpperCase();
      if (up.isEmpty) continue;
      // Note: Conditional styling not applied due to excel 4.x API limitations.
    }

    // Errors & Warnings sheet
    final warningSheet = _ensureSheet(excel, 'Errors & Warnings');
    warningSheet.appendRow([
      _txt('Register Number'),
      _txt('Student Name'),
      _txt('Issue'),
      _txt('Subject Code'),
    ]);
    for (final s in students) {
      for (final sub in s.subjects) {
        final issues = <String>[];
        final noTokens =
            (sub.grade == null || sub.grade!.trim().isEmpty) &&
            (sub.result == null || sub.result!.trim().isEmpty) &&
            (sub.mark == null || sub.mark!.trim().isEmpty);
        if (sub.title.trim().isEmpty) {
          issues.add('Missing subject title');
        }
        if (noTokens) {
          issues.add('Missing grade/mark/result');
        }
        if (issues.isNotEmpty) {
          warningSheet.appendRow([
            _txt(
              anonymize ? _maskRegister(s.registerNumber) : s.registerNumber,
            ),
            _txt(anonymize ? _maskName(s.studentName) : s.studentName),
            _txt(issues.join('; ')),
            _txt(sub.code),
          ]);
        }
      }
    }
    _autoFit(warningSheet, columns: 4);

    // Optional: per-department sheets
    if (splitByDepartment) {
      final byDepartment = <String, List<StudentResult>>{};
      for (final s in students) {
        byDepartment.putIfAbsent(s.department, () => []).add(s);
      }
      for (final entry in byDepartment.entries) {
        final sheetName = _safeSheetName(entry.key);
        final dept = _ensureSheet(excel, sheetName);
        dept.appendRow([
          _txt('Register Number'),
          _txt('Student Name'),
          _txt('Status'),
          _txt('Subject Code'),
          _txt('Subject Name'),
          _txt('Grade'),
          _txt('Result'),
        ]);
        for (final s in entry.value) {
          final reg = anonymize
              ? _maskRegister(s.registerNumber)
              : s.registerNumber;
          final name = anonymize ? _maskName(s.studentName) : s.studentName;
          final status = s.statusLabel;
          for (final sub in s.subjects) {
            dept.appendRow([
              _txt(reg),
              _txt(name),
              _txt(s.statusLabel),
              _txt(sub.code),
              _txt(sub.title),
              _txt(sub.grade ?? ''),
              _txt(sub.result ?? ''),
            ]);
          }
        }
        _autoFit(dept, columns: 7);
      }
    }

    // Extra sheets: Pass and Arrear student summaries (one row per student)
    final passSheet = _ensureSheet(excel, 'Pass Students');
    passSheet.appendRow([
      _txt('Register Number'),
      _txt('Student Name'),
      _txt('Department'),
      _txt('Year'),
      _txt('Semester'),
      _txt('Failed Subjects'),
      _txt('Total Subjects'),
    ]);
    for (final s in students.where((s) => s.status == ResultStatus.allClear)) {
      passSheet.appendRow([
        _txt(anonymize ? _maskRegister(s.registerNumber) : s.registerNumber),
        _txt(anonymize ? _maskName(s.studentName) : s.studentName),
        _txt(s.department),
        _txt(s.academicYearLabel),
        _txt(s.semesterNumber?.toString() ?? ''),
        _txt('${s.failedSubjectCount}'),
        _txt('${s.subjects.length}'),
      ]);
    }
    _autoFit(passSheet, columns: 7);

    final arrearSheet = _ensureSheet(excel, 'Arrear Students');
    arrearSheet.appendRow([
      _txt('Register Number'),
      _txt('Student Name'),
      _txt('Department'),
      _txt('Year'),
      _txt('Semester'),
      _txt('Failed Subjects'),
      _txt('Total Subjects'),
      _txt('Failed Subject Codes'),
    ]);
    for (final s in students.where((s) => s.status == ResultStatus.arrear)) {
      final failedCodes = s.subjects
          .where((sub) => sub.isFailedAfterAttending)
          .map((sub) => sub.code.trim())
          .where((code) => code.isNotEmpty)
          .join(', ');
      arrearSheet.appendRow([
        _txt(anonymize ? _maskRegister(s.registerNumber) : s.registerNumber),
        _txt(anonymize ? _maskName(s.studentName) : s.studentName),
        _txt(s.department),
        _txt(s.academicYearLabel),
        _txt(s.semesterNumber?.toString() ?? ''),
        _txt('${s.failedSubjectCount}'),
        _txt('${s.subjects.length}'),
        _txt(failedCodes),
      ]);
    }
    _autoFit(arrearSheet, columns: 8);

    // Save workbook to bytes using excel 4.x API
    final fileName = suggestedFileNameAdvanced(
      sourceName: sourceName,
      examViewLabel: examViewLabel,
      passRate: passRate,
    );

    final bytes = excel.save(fileName: fileName);
    if (bytes == null) {
      throw StateError('Unable to generate the Excel workbook.');
    }

    return saveFileBytes(
      Uint8List.fromList(bytes),
      fileName: fileName,
      destinationPath: destinationPath,
    );
  }

  // Backward-compatible single-sheet export
  Future<String> exportToExcel(
    List<StudentResult> students, {
    String? destinationPath,
    String? sourceName,
  }) async {
    return exportWorkbook(
      students: students,
      destinationPath: destinationPath,
      sourceName: sourceName,
      examViewLabel: 'Mixed',
      analysisYear: AcademicYear.unknown,
      anonymize: false,
      splitByDepartment: false,
    );
  }

  // -----------------
  // Helpers
  // -----------------
  TextCellValue _txt(Object? v) => TextCellValue(v?.toString() ?? '');

  void _autoFit(Sheet sheet, {required int columns}) {
    // excel 4.x does not expose a stable public API to set column widths on Sheet.
    // Leaving this as a no-op to avoid runtime errors. Consider switching to
    // Syncfusion XlsIO for true autofit and advanced formatting.
  }

  String _maskRegister(String input) {
    final trimmed = input.trim();
    if (trimmed.length <= 3) return '***';
    final last3 = trimmed.substring(trimmed.length - 3);
    return '**** **** *$last3';
  }

  String _maskName(String input) {
    final parts = input.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '****';
    String mask(String s) => s.isEmpty ? '' : s[0].toUpperCase() + '***';
    if (parts.length == 1) return mask(parts.first);
    return parts.map(mask).join(' ');
  }

  Sheet _ensureSheet(Excel excel, String name) {
    // Accessing excel[name] creates the sheet if it doesn't exist in excel 4.x
    if (excel.sheets.containsKey(name)) {
      return excel.sheets[name]!;
    }
    return excel[name];
  }

  String _safeSheetName(String name) {
    var cleaned = name.replaceAll(RegExp(r'[\\/*\[\]:?]'), ' ').trim();
    if (cleaned.length > 28) {
      cleaned = cleaned.substring(0, 28);
    }
    return cleaned.isEmpty ? 'Department' : cleaned;
  }
}
