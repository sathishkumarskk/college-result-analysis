import '../models/academic_year.dart';
import '../models/student_result.dart';
import '../models/subject_result.dart';

enum _ExamSessionType { oddSemesterMain, evenSemesterMain, unknown }

class ResultParserService {
  // Demo text that mirrors the label-based parser format used below.
  static const String demoRawText = '''
Student Name : Aarthi N
Register Number : 2024CSE001
Department : Computer Science and Engineering
CS101 - Problem Solving and Python - 91 - O
CS102 - Data Structures - 84 - A+
CS103 - Database Systems - 78 - A

Student Name : Bala K
Register Number : 2024CSE002
Department : Computer Science and Engineering
CS101 - Problem Solving and Python - 68 - B+
CS102 - Data Structures - RA - RA
CS103 - Database Systems - 74 - A

Student Name : Divya R
Register Number : 2024ECE001
Department : Electronics and Communication Engineering
EC101 - Digital Electronics - 88 - A+
EC102 - Signals and Systems - 81 - A
EC103 - Analog Circuits - 77 - B+

Student Name : Hari P
Register Number : 2024EEE001
Department : Electrical and Electronics Engineering
EE101 - Network Theory - 64 - B
EE102 - Machines - 59 - C
EE103 - Power Systems - RA - RA
''';

  // Reference text that reflects the common Anna University PDF extraction layout.
  static const String annaUniversityReferenceText = '''
Register Number : 212221040001
Name : PRIYA R
Branch : COMPUTER SCIENCE AND ENGINEERING
Semester Subject Code Grade Result
01 HS3152 A+ PASS
01 MA3151 A PASS
01 CY3151 U RA
''';

  bool hasAnnaUniversityResultIndicators(String rawText) {
    final normalized = _normalize(rawText);
    if (normalized.isEmpty) {
      return false;
    }

    final hasRegisterDetails = RegExp(
      r'(?:Register\s*(?:Number|No\.?)|Reg(?:ister)?\s*No|Reg\.\s*Number|\b\d{12}\b)',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasDepartmentDetails = RegExp(
      r'(?:Branch|Department|Dept|Stud\.\s*Name|Name)',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasAssessmentDetails = RegExp(
      r'(?:Subject\s+Code|Grad(?:e)?|PASS|RA|UA|\bU\b|\bA\+\b|\bB\+\b|\bS\b|Semester\s*No\.?)',
      caseSensitive: false,
    ).hasMatch(normalized);

    return hasRegisterDetails && hasDepartmentDetails && hasAssessmentDetails;
  }

  bool looksLikeSupportedAnnaUniversityResult(String rawText) {
    final normalized = _normalize(rawText);
    if (normalized.isEmpty) {
      return false;
    }

    final hasInstitutionHeader = RegExp(
      r'(?:ANNA\s+UNIVERSITY|CONTROLLER\s+OF\s+EXAMINATIONS|Provisional\s+Results)',
      caseSensitive: false,
    ).hasMatch(normalized);

    return hasAnnaUniversityResultIndicators(normalized) ||
        (hasInstitutionHeader &&
            RegExp(
              r'(?:Subject\s+Code|Semester\s*No\.?|Register\s*(?:Number|No\.?))',
              caseSensitive: false,
            ).hasMatch(normalized));
  }

  List<StudentResult> parseFromRawText(String rawText) {
    final normalized = _normalize(rawText);
    if (normalized.isEmpty) {
      return const [];
    }

    final examYear = _extractExamYear(normalized);
    final examSessionType = _extractExamSessionType(normalized);

    final annaUniversityTabularStudents = _parseAnnaUniversityTabularResults(
      normalized,
    );
    if (annaUniversityTabularStudents.isNotEmpty) {
      return _enrichParsedStudents(
        annaUniversityTabularStudents,
        examYear: examYear,
        examSessionType: examSessionType,
      );
    }

    final annaUniversityStudents = _parseAnnaUniversityBlocks(normalized);
    if (annaUniversityStudents.isNotEmpty) {
      return _enrichParsedStudents(
        annaUniversityStudents,
        examYear: examYear,
        examSessionType: examSessionType,
      );
    }

    final labeledStudents = _parseLabeledBlocks(normalized);
    if (labeledStudents.isNotEmpty) {
      return _enrichParsedStudents(
        labeledStudents,
        examYear: examYear,
        examSessionType: examSessionType,
      );
    }

    final parsedStudents = _parseBlankLineBlocks(normalized);

    return _enrichParsedStudents(
      parsedStudents,
      examYear: examYear,
      examSessionType: examSessionType,
    );
  }

  List<StudentResult> parseDemoData() {
    return parseFromRawText(demoRawText);
  }

  List<StudentResult> _enrichParsedStudents(
    List<StudentResult> students, {
    required int? examYear,
    required _ExamSessionType examSessionType,
  }) {
    if (students.isEmpty) {
      return const [];
    }

    final observedBatchCodesBySemester = <int, int>{};

    for (final student in students) {
      final semesterNumber = student.semesterNumber;
      final batchCode = _extractBatchCode(student.registerNumber);
      if (semesterNumber == null || batchCode == null) {
        continue;
      }

      final trackedBatchCode = observedBatchCodesBySemester[semesterNumber];
      if (trackedBatchCode == null || batchCode > trackedBatchCode) {
        observedBatchCodesBySemester[semesterNumber] = batchCode;
      }
    }

    final currentAcademicStartYear = _currentAcademicStartYear(
      examYear: examYear,
      examSessionType: examSessionType,
    );
    final currentBatchCodesBySemester = <int, int>{};
    for (final entry in observedBatchCodesBySemester.entries) {
      final inferredBatchCode = _inferCurrentBatchCode(
        semesterNumber: entry.key,
        currentAcademicStartYear: currentAcademicStartYear,
        examSessionType: examSessionType,
      );
      currentBatchCodesBySemester[entry.key] = inferredBatchCode == null
          ? entry.value
          : inferredBatchCode >= entry.value
          ? inferredBatchCode
          : entry.value;
    }

    final enrichedStudents = students.map((student) {
      final semesterNumber = student.semesterNumber;
      final batchCode = _extractBatchCode(student.registerNumber);
      final currentBatchCode = semesterNumber == null
          ? null
          : currentBatchCodesBySemester[semesterNumber];

      return student.copyWith(
        academicYearOverride: _inferAcademicYear(
          batchCode: batchCode,
          semesterNumber: semesterNumber,
          currentAcademicStartYear: currentAcademicStartYear,
        ),
        examAttemptType: _inferExamAttemptType(
          semesterNumber: semesterNumber,
          batchCode: batchCode,
          currentBatchCode: currentBatchCode,
          examSessionType: examSessionType,
        ),
      );
    }).toList();

    return _deduplicateStudents(enrichedStudents);
  }

  AcademicYear? _inferAcademicYear({
    required int? batchCode,
    required int? semesterNumber,
    required int? currentAcademicStartYear,
  }) {
    if (batchCode != null && currentAcademicStartYear != null) {
      final inferredCourseYear =
          (currentAcademicStartYear % 100) - batchCode + 1;
      return academicYearFromCourseYear(inferredCourseYear);
    }

    return semesterNumber == null
        ? null
        : academicYearFromSemester(semesterNumber);
  }

  ExamAttemptType _inferExamAttemptType({
    required int? semesterNumber,
    required int? batchCode,
    required int? currentBatchCode,
    required _ExamSessionType examSessionType,
  }) {
    if (semesterNumber != null &&
        examSessionType != _ExamSessionType.unknown &&
        !_isRegularSemesterForSession(semesterNumber, examSessionType)) {
      return ExamAttemptType.arrearExam;
    }

    if (batchCode == null || currentBatchCode == null) {
      return ExamAttemptType.unknown;
    }

    if (batchCode < currentBatchCode) {
      return ExamAttemptType.arrearExam;
    }

    if (batchCode == currentBatchCode) {
      return ExamAttemptType.currentExam;
    }

    return ExamAttemptType.unknown;
  }

  int? _inferCurrentBatchCode({
    required int semesterNumber,
    required int? currentAcademicStartYear,
    required _ExamSessionType examSessionType,
  }) {
    if (!_isRegularSemesterForSession(semesterNumber, examSessionType)) {
      return null;
    }

    final courseYear = courseYearFromSemester(semesterNumber);
    if (courseYear == null || currentAcademicStartYear == null) {
      return null;
    }

    final batchCode = (currentAcademicStartYear % 100) - (courseYear - 1);
    return batchCode < 0 ? null : batchCode;
  }

  int? _currentAcademicStartYear({
    required int? examYear,
    required _ExamSessionType examSessionType,
  }) {
    if (examYear == null) {
      return null;
    }

    return switch (examSessionType) {
      _ExamSessionType.oddSemesterMain => examYear,
      _ExamSessionType.evenSemesterMain => examYear - 1,
      _ExamSessionType.unknown => examYear,
    };
  }

  bool _isRegularSemesterForSession(
    int semesterNumber,
    _ExamSessionType examSessionType,
  ) {
    return switch (examSessionType) {
      _ExamSessionType.oddSemesterMain => semesterNumber.isOdd,
      _ExamSessionType.evenSemesterMain => semesterNumber.isEven,
      _ExamSessionType.unknown => true,
    };
  }

  int? _extractBatchCode(String registerNumber) {
    final normalized = registerNumber.replaceAll(RegExp(r'\s+'), '');

    if (RegExp(r'^\d{12}$').hasMatch(normalized)) {
      return int.tryParse(normalized.substring(4, 6));
    }

    final yearPrefixMatch = RegExp(r'^(20\d{2})').firstMatch(normalized);
    if (yearPrefixMatch != null) {
      return int.tryParse(yearPrefixMatch.group(1)!.substring(2));
    }

    return null;
  }

  int? _extractExamYear(String text) {
    final match = RegExp(
      r'Examination\s*,\s*(20\d{2})',
      caseSensitive: false,
    ).firstMatch(text);

    return int.tryParse(match?.group(1) ?? '');
  }

  _ExamSessionType _extractExamSessionType(String text) {
    if (RegExp(
      r'Nov\.?\s*/\s*Dec\.?\s+Examination',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _ExamSessionType.oddSemesterMain;
    }

    if (RegExp(
      r'Apr\.?\s*/\s*May\.?\s+Examination',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _ExamSessionType.evenSemesterMain;
    }

    return _ExamSessionType.unknown;
  }

  List<StudentResult> _deduplicateStudents(List<StudentResult> students) {
    final uniqueStudents = <String, StudentResult>{};

    for (final student in students) {
      final key = '${student.registerNumber}|${student.semesterNumber ?? -1}';
      final existingStudent = uniqueStudents[key];
      if (existingStudent == null ||
          _studentQualityScore(student) >
              _studentQualityScore(existingStudent)) {
        uniqueStudents[key] = student;
      }
    }

    return uniqueStudents.values.toList();
  }

  int _studentQualityScore(StudentResult student) {
    final subjectScore = student.subjects.length * 10;
    final titleScore = student.subjects
        .where((subject) => subject.title.trim().isNotEmpty)
        .length;
    final detailScore = student.subjects
        .where(
          (subject) =>
              (subject.grade?.trim().isNotEmpty ?? false) ||
              (subject.result?.trim().isNotEmpty ?? false) ||
              (subject.mark?.trim().isNotEmpty ?? false),
        )
        .length;
    final nameScore =
        student.studentName.trim().isNotEmpty &&
            student.studentName.trim() != student.registerNumber
        ? 5
        : 0;

    return subjectScore + titleScore + detailScore + nameScore;
  }

  String _normalize(String rawText) {
    final withSmartBreaks = rawText
        .replaceAll('\r', '\n')
        .replaceAll(
          RegExp(
            r'\s+(?=(?:Register\s*(?:Number|No\.?)|Reg(?:ister)?\s*No|Student\s*Name|Name(?:\s+of\s+the\s+Candidate)?|Department|Dept|Branch(?:\s+of\s+Study)?|Branch\s*Name|Branch|Semester|S\.?No\.?\s+Subject\s+Code|Subject\s+Code)\s*:?)',
            caseSensitive: false,
          ),
          '\n',
        )
        .replaceAllMapped(
          RegExp(
            r'\b(PASS|RA|FAIL|FAILED|ABSENT|AB)\s+(?=(?:(?:\d{1,2}|[A-Z])\.?\s+)?[A-Z]{2,}\d{3,}[A-Z0-9-]*\b)',
            caseSensitive: false,
          ),
          (match) => '${match.group(1)}\n',
        )
        .replaceAllMapped(
          RegExp(
            r'\b(PASS|RA|FAIL|FAILED|ABSENT|AB)\s+(?=(?:Register\s*(?:Number|No\.?)|Reg(?:ister)?\s*No)\b)',
            caseSensitive: false,
          ),
          (match) => '${match.group(1)}\n',
        );

    return withSmartBreaks
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  List<StudentResult> _parseAnnaUniversityTabularResults(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final students = <StudentResult>[];
    var currentDepartment = 'Unknown Department';
    int? currentSemesterNumber;
    var currentSubjectCodes = <String>[];
    final subjectCodePieces = <String>[];
    var collectingSubjectCodes = false;
    String? currentRegisterNumber;
    String? currentStudentName;
    final currentGrades = <String>[];

    void finalizeCurrentStudent() {
      if (currentRegisterNumber == null ||
          currentStudentName == null ||
          currentGrades.isEmpty) {
        currentRegisterNumber = null;
        currentStudentName = null;
        currentGrades.clear();
        return;
      }

      students.add(
        StudentResult(
          studentName: currentStudentName!,
          registerNumber: currentRegisterNumber!,
          department: currentDepartment,
          subjects: _buildTabularSubjects(currentSubjectCodes, currentGrades),
          semesterNumber: currentSemesterNumber,
        ),
      );

      currentRegisterNumber = null;
      currentStudentName = null;
      currentGrades.clear();
    }

    for (final line in lines) {
      if (_isFooterLine(line) || line.startsWith('W - Withdrawal')) {
        finalizeCurrentStudent();
        collectingSubjectCodes = false;
        continue;
      }

      final semesterNumber = _extractSemesterNumber(line);
      if (semesterNumber != null) {
        finalizeCurrentStudent();
        currentSemesterNumber = semesterNumber;
      }

      final branchMatch = RegExp(
        r'^Branch\s*:\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (branchMatch != null) {
        finalizeCurrentStudent();
        currentDepartment = branchMatch.group(1)!.trim();
        continue;
      }

      if (line.contains('Subject Code')) {
        finalizeCurrentStudent();
        subjectCodePieces.clear();
        collectingSubjectCodes = true;
        continue;
      }

      if (line.startsWith('Reg. Number') || line.startsWith('Reg Number')) {
        currentSubjectCodes = _buildSubjectCodesFromHeaderPieces(
          subjectCodePieces,
        );
        collectingSubjectCodes = false;
        continue;
      }

      if (collectingSubjectCodes) {
        subjectCodePieces.addAll(
          RegExp(r'[A-Z0-9]+').allMatches(line).map((match) => match.group(0)!),
        );
        continue;
      }

      if (_looksLikeRegisterNumber(line)) {
        finalizeCurrentStudent();
        currentRegisterNumber = line;
        continue;
      }

      if (_isTabularNoiseLine(line)) {
        continue;
      }

      if (currentRegisterNumber != null && currentStudentName == null) {
        currentStudentName = line;
        continue;
      }

      if (currentRegisterNumber != null &&
          currentStudentName != null &&
          currentGrades.isEmpty &&
          !_containsGradeToken(line)) {
        currentStudentName = '$currentStudentName $line';
        continue;
      }

      if (currentRegisterNumber != null) {
        final gradeTokens = _extractTabularGradeTokens(line);
        if (gradeTokens.isNotEmpty) {
          currentGrades.addAll(gradeTokens);
        }
      }
    }

    finalizeCurrentStudent();
    return students;
  }

  List<SubjectResult> _buildTabularSubjects(
    List<String> subjectCodes,
    List<String> grades,
  ) {
    final subjects = <SubjectResult>[];

    for (var index = 0; index < grades.length; index++) {
      final grade = grades[index];
      final subjectCode = index < subjectCodes.length
          ? subjectCodes[index]
          : 'SUBJ${index + 1}';

      subjects.add(
        SubjectResult(
          code: subjectCode,
          title: '',
          grade: grade,
          result: _isFailedTabularGrade(grade) ? 'RA' : 'PASS',
        ),
      );
    }

    return subjects;
  }

  List<String> _buildSubjectCodesFromHeaderPieces(List<String> pieces) {
    final codes = <String>[];
    var index = 0;

    while (index < pieces.length) {
      final current = pieces[index].toUpperCase();

      if (_looksLikeCompleteTabularSubjectCode(current)) {
        codes.add(current);
        index++;
        continue;
      }

      if (index + 1 < pieces.length) {
        final combined = '$current${pieces[index + 1].toUpperCase()}';
        if (_looksLikeSubjectCode(combined)) {
          codes.add(combined);
          index += 2;
          continue;
        }
      }

      if (_looksLikeSubjectCode(current)) {
        codes.add(current);
      }
      index++;
    }

    return codes;
  }

  bool _looksLikeCompleteTabularSubjectCode(String value) {
    return RegExp(
      r'^(?:[A-Z]{2,}\d{4}|[A-Z]{2,}\d{2}[A-Z]\d{2})$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  bool _looksLikeRegisterNumber(String value) {
    return RegExp(r'^\d{12}$').hasMatch(value.trim());
  }

  bool _isTabularNoiseLine(String line) {
    return RegExp(
      r'^(?:ANNA\s+UNIVERSITY|OFFICE\s+OF\s+THE\s+CONTROLLER|Provisional\s+Results|Inst\.Code/Name|Semester\s+No|DATE\s+OF\s+PUBLICATION|Page\s+\d+/\d+|Stud\.\s*Name|Grad|e|>|Anna\s+University\s*-\s*COE|\d{2}-\d{2}-\d{4})',
      caseSensitive: false,
    ).hasMatch(line);
  }

  List<String> _extractTabularGradeTokens(String line) {
    return line
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where(_looksLikeTabularGradeToken)
        .map((token) => token.toUpperCase())
        .toList();
  }

  bool _containsGradeToken(String line) {
    return _extractTabularGradeTokens(line).isNotEmpty;
  }

  bool _looksLikeTabularGradeToken(String token) {
    return const {
      'O',
      'A+',
      'A',
      'B+',
      'B',
      'C',
      'D',
      'E',
      'S',
      'U',
      'UA',
      'AB',
      'RA',
      'W',
      'I',
      'WH',
    }.contains(token.toUpperCase());
  }

  bool _isFailedTabularGrade(String token) {
    return const {
      'U',
      'UA',
      'AB',
      'RA',
      'F',
      'WH',
    }.contains(token.toUpperCase());
  }

  List<StudentResult> _parseAnnaUniversityBlocks(String text) {
    final blocks = _splitStudentBlocks(text);

    return blocks
        .map(_parseAnnaUniversityBlock)
        .whereType<StudentResult>()
        .toList();
  }

  List<String> _splitStudentBlocks(String text) {
    final registerMatches = RegExp(
      r'(^|\n)\s*(?:Register\s*(?:Number|No\.?)|Reg(?:ister)?\s*No)\s*:?',
      caseSensitive: false,
      multiLine: true,
    ).allMatches(text).toList();

    if (registerMatches.length <= 1) {
      return [text];
    }

    final blocks = <String>[];
    for (var index = 0; index < registerMatches.length; index++) {
      final start = registerMatches[index].start;
      final end = index + 1 < registerMatches.length
          ? registerMatches[index + 1].start
          : text.length;
      final block = text.substring(start, end).trim();
      if (block.isNotEmpty) {
        blocks.add(block);
      }
    }

    return blocks;
  }

  StudentResult? _parseAnnaUniversityBlock(String block) {
    final registerNumber = _extractField(block, [
      RegExp(
        r'^\s*(?:Register\s*(?:Number|No\.?)|Reg(?:ister)?\s*No)\s*:?\s*([A-Z0-9]+)\s*$',
        caseSensitive: false,
        multiLine: true,
      ),
      RegExp(
        r'(?:Register\s*(?:Number|No\.?)|Reg(?:ister)?\s*No)\s*:?\s*([A-Z0-9]+)',
        caseSensitive: false,
      ),
    ]);

    final studentName = _extractField(block, [
      RegExp(
        r'^\s*(?:Student\s*Name|Name(?:\s+of\s+the\s+Candidate)?)\s*:?\s*(.+)$',
        caseSensitive: false,
        multiLine: true,
      ),
      RegExp(
        r'(?:Student\s*Name|Name(?:\s+of\s+the\s+Candidate)?)\s*:?\s*(.+?)(?=\s+(?:Register\s*(?:Number|No\.?)|Reg(?:ister)?\s*No|Degree|Programme|Branch(?:\s+of\s+Study)?|Branch\s*Name|Department|Dept|Semester|Subject\s+Code)\b|$)',
        caseSensitive: false,
        dotAll: true,
      ),
    ]);

    final department =
        _extractField(block, [
          RegExp(
            r'^\s*(?:Department|Dept|Branch(?:\s+of\s+Study)?|Branch\s*Name|Branch|Programme\s*/\s*Branch)\s*:?\s*(.+)$',
            caseSensitive: false,
            multiLine: true,
          ),
          RegExp(
            r'(?:Department|Dept|Branch(?:\s+of\s+Study)?|Branch\s*Name|Branch|Programme\s*/\s*Branch)\s*:?\s*(.+?)(?=\s+(?:Semester|Register\s*(?:Number|No\.?)|Reg(?:ister)?\s*No|Student\s*Name|Name(?:\s+of\s+the\s+Candidate)?|Subject\s+Code|Grade|Result)\b|$)',
            caseSensitive: false,
            dotAll: true,
          ),
        ]) ??
        'Unknown Department';
    final semesterNumber = _extractSemesterNumber(block);

    final subjects = _extractAnnaUniversitySubjectRows(
      block,
    ).map(_parseAnnaUniversitySubjectRow).whereType<SubjectResult>().toList();

    if (registerNumber == null || subjects.isEmpty) {
      return null;
    }

    return StudentResult(
      studentName: (studentName == null || studentName.isEmpty)
          ? registerNumber
          : studentName,
      registerNumber: registerNumber,
      department: department,
      subjects: subjects,
      semesterNumber: semesterNumber,
    );
  }

  List<StudentResult> _parseLabeledBlocks(String text) {
    // Update this regex if your institution's PDF uses a different header order.
    final blockPattern = RegExp(
      r'(?:Student\s*Name|Name)\s*:\s*(.+?)\n'
      r'(?:Register\s*Number|Register\s*No|Reg(?:ister)?\s*No)\s*:\s*(.+?)\n'
      r'(?:Department|Dept)\s*:\s*(.+?)\n'
      r'(.*?)(?=\n\s*(?:Student\s*Name|Name)\s*:|\Z)',
      caseSensitive: false,
      dotAll: true,
      multiLine: true,
    );

    return blockPattern
        .allMatches(text)
        .map(
          (match) => _buildStudentResult(
            name: match.group(1)?.trim(),
            registerNumber: match.group(2)?.trim(),
            department: match.group(3)?.trim(),
            subjectsBlock: match.group(4) ?? '',
          ),
        )
        .whereType<StudentResult>()
        .toList();
  }

  List<StudentResult> _parseBlankLineBlocks(String text) {
    final blocks = text.split(RegExp(r'\n\s*\n'));
    final students = <StudentResult>[];

    for (final block in blocks) {
      final student = _buildStudentResult(
        name: _extractSingleLineValue(
          block,
          r'(?:Student\s*Name|Name)\s*:\s*(.+)',
        ),
        registerNumber: _extractSingleLineValue(
          block,
          r'(?:Register\s*Number|Register\s*No|Reg(?:ister)?\s*No)\s*:\s*(.+)',
        ),
        department: _extractSingleLineValue(
          block,
          r'(?:Department|Dept)\s*:\s*(.+)',
        ),
        subjectsBlock: block,
      );

      if (student != null) {
        students.add(student);
      }
    }

    return students;
  }

  StudentResult? _buildStudentResult({
    required String? name,
    required String? registerNumber,
    required String? department,
    required String subjectsBlock,
  }) {
    if ([
      name,
      registerNumber,
      department,
    ].any((value) => value == null || value.trim().isEmpty)) {
      return null;
    }

    final subjects = subjectsBlock
        .split('\n')
        .map((line) => _parseSubjectLine(line.trim()))
        .whereType<SubjectResult>()
        .toList();

    if (subjects.isEmpty) {
      return null;
    }

    return StudentResult(
      studentName: name!.trim(),
      registerNumber: registerNumber!.trim(),
      department: department!.trim(),
      subjects: subjects,
      semesterNumber: _extractSemesterNumber(subjectsBlock),
    );
  }

  String? _extractSingleLineValue(String block, String pattern) {
    final match = RegExp(
      pattern,
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(block);
    final value = match?.group(1)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? _extractField(String block, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(block);
      final value = match?.group(1);
      if (value == null) {
        continue;
      }

      final cleaned = _sanitizeFieldValue(value);
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    return null;
  }

  String _sanitizeFieldValue(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[|:]+$'), '')
        .trim();
  }

  int? _extractSemesterNumber(String text) {
    final match = RegExp(
      r'(?:Semester\s*No\.?|Semester)\s*:\s*(\d{1,2})',
      caseSensitive: false,
    ).firstMatch(text);

    return int.tryParse(match?.group(1) ?? '');
  }

  List<String> _extractAnnaUniversitySubjectRows(String block) {
    final lines = block
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final rows = <String>[];
    String? currentRow;

    for (final line in lines) {
      if (_isSubjectHeaderLine(line) || _isStudentHeaderLine(line)) {
        continue;
      }

      if (_isFooterLine(line)) {
        if (currentRow != null) {
          rows.add(currentRow);
          currentRow = null;
        }
        continue;
      }

      if (_looksLikeAnnaUniversitySubjectRowStart(line)) {
        if (currentRow != null) {
          rows.add(currentRow);
        }
        currentRow = line;
        continue;
      }

      if (currentRow != null) {
        currentRow = '$currentRow $line';
      }
    }

    if (currentRow != null) {
      rows.add(currentRow);
    }

    return rows;
  }

  bool _isSubjectHeaderLine(String line) {
    return RegExp(
      r'(?:S\.?\s*No\.?\s+)?Subject\s+Code',
      caseSensitive: false,
    ).hasMatch(line);
  }

  bool _isStudentHeaderLine(String line) {
    return RegExp(
      r'^(?:ANNA\s+UNIVERSITY|Register\s*(?:Number|No\.?)|Reg(?:ister)?\s*No|Student\s*Name|Name(?:\s+of\s+the\s+Candidate)?|Degree|Programme|Department|Dept|Branch(?:\s+of\s+Study)?|Branch\s*Name|Branch|Semester)\b',
      caseSensitive: false,
    ).hasMatch(line);
  }

  bool _isFooterLine(String line) {
    return RegExp(
      r'^(?:CGPA|GPA|Cumulative|Credits?\s+(?:Registered|Earned|Exempted)|Class(?:ification)?|Month\s*&?\s*Year\s+of\s+Passing|Published\s+On|Result\s+Published|Controller\s+of\s+Examinations|Disclaimer|This\s+is\s+a\s+system\s+generated|Page\s+\d+)',
      caseSensitive: false,
    ).hasMatch(line);
  }

  bool _looksLikeAnnaUniversitySubjectRowStart(String line) {
    return RegExp(
      r'^(?:(?:\d{1,2}|[A-Z])\.?\s+)?[A-Z]{2,}\d{3,}[A-Z0-9-]*\b',
      caseSensitive: false,
    ).hasMatch(line);
  }

  SubjectResult? _parseAnnaUniversitySubjectRow(String row) {
    final tokens = row
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();

    if (tokens.length < 2) {
      return null;
    }

    var codeIndex = 0;
    if (!_looksLikeSubjectCode(tokens[codeIndex])) {
      if (tokens.length > 1 && _looksLikeSubjectCode(tokens[1])) {
        codeIndex = 1;
      } else if (tokens.length > 2 && _looksLikeSubjectCode(tokens[2])) {
        codeIndex = 2;
      } else {
        return null;
      }
    }

    final code = tokens[codeIndex].toUpperCase();
    final trailingTokens = [...tokens.sublist(codeIndex + 1)];

    String? result;
    if (trailingTokens.isNotEmpty &&
        _looksLikeResultToken(trailingTokens.last)) {
      result = _normalizeToken(trailingTokens.removeLast());
    }

    String? grade;
    if (trailingTokens.isNotEmpty &&
        _looksLikeGradeToken(trailingTokens.last)) {
      grade = _normalizeToken(trailingTokens.removeLast());
    }

    String? mark;
    if (trailingTokens.isNotEmpty &&
        _looksLikeNumericValue(trailingTokens.last)) {
      final trailingNumber = trailingTokens.last;
      if (_looksLikeCreditToken(trailingNumber) && trailingTokens.length > 1) {
        trailingTokens.removeLast();
      } else {
        mark = trailingTokens.removeLast();
      }
    }

    if (trailingTokens.isNotEmpty &&
        _looksLikeCreditToken(trailingTokens.last) &&
        trailingTokens.length > 1) {
      trailingTokens.removeLast();
    }

    final title = trailingTokens.join(' ').trim();

    if (title.isEmpty && mark == null && grade == null && result == null) {
      return null;
    }

    return SubjectResult(
      code: code,
      title: title,
      mark: mark,
      grade: grade,
      result: result,
    );
  }

  SubjectResult? _parseSubjectLine(String line) {
    if (line.isEmpty || line.contains(':')) {
      return null;
    }

    final compactMatch = RegExp(
      r'^([A-Z]{2,}\d{2,}[A-Z0-9-]*)\s*(?:-|:|\|)\s*(.*?)\s*(?:-|:|\|)\s*([A-Z0-9+.]+)(?:\s*(?:-|:|\|)\s*([A-Z0-9+.]+))?$',
      caseSensitive: false,
    ).firstMatch(line);

    if (compactMatch != null) {
      final token3 = compactMatch.group(3)!.trim();
      final token4 = compactMatch.group(4)?.trim();

      return SubjectResult(
        code: compactMatch.group(1)!.trim(),
        title: compactMatch.group(2)!.trim(),
        mark: token4 == null
            ? (_looksNumericMark(token3) ? token3 : null)
            : token3,
        grade: token4 ?? (_looksNumericMark(token3) ? null : token3),
        result: null,
      );
    }

    final parts = line
        .split(RegExp(r'\s{2,}|\t+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length < 3 || !_looksLikeSubjectCode(parts.first)) {
      return null;
    }

    if (parts.length == 3) {
      final trailingValue = parts[2];
      return SubjectResult(
        code: parts[0],
        title: parts[1],
        mark: _looksNumericMark(trailingValue) ? trailingValue : null,
        grade: _looksNumericMark(trailingValue) ? null : trailingValue,
        result: null,
      );
    }

    return SubjectResult(
      code: parts[0],
      title: parts.sublist(1, parts.length - 2).join(' '),
      mark: parts[parts.length - 2],
      grade: parts.last,
      result: null,
    );
  }

  bool _looksNumericMark(String value) {
    return RegExp(r'^\d{1,3}$').hasMatch(value.trim());
  }

  bool _looksLikeNumericValue(String value) {
    return RegExp(r'^\d+(?:\.\d+)?$').hasMatch(value.trim());
  }

  bool _looksLikeCreditToken(String value) {
    if (!_looksLikeNumericValue(value)) {
      return false;
    }

    final numericValue = double.tryParse(value);
    return numericValue != null && numericValue <= 10;
  }

  bool _looksLikeGradeToken(String value) {
    return const {
      'O',
      'A+',
      'A',
      'B+',
      'B',
      'C',
      'D',
      'E',
      'P',
      'F',
      'S',
      'U',
      'UA',
      'AB',
      'W',
      'I',
      'WH',
    }.contains(_normalizeToken(value));
  }

  bool _looksLikeResultToken(String value) {
    return const {
      'PASS',
      'RA',
      'FAIL',
      'FAILED',
      'AB',
      'ABSENT',
      'W',
      'I',
      'WH',
      'U/F',
      'WITHHELD',
    }.contains(_normalizeToken(value));
  }

  String _normalizeToken(String value) {
    return value.replaceAll(RegExp(r'[^A-Z+/]'), '').toUpperCase();
  }

  bool _looksLikeSubjectCode(String value) {
    return RegExp(
      r'^[A-Z]{2,}\d{2,}[A-Z0-9-]*$',
      caseSensitive: false,
    ).hasMatch(value.trim());
  }
}
