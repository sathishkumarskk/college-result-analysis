class SubjectResult {
  const SubjectResult({
    required this.code,
    required this.title,
    this.mark,
    this.grade,
    this.result,
  });

  final String code;
  final String title;
  final String? mark;
  final String? grade;
  final String? result;

  static const Set<String> _failedTokens = {
    'AB',
    'ABSENT',
    'F',
    'FAIL',
    'FAILED',
    'RA',
    'UA',
    'U',
  };

  static const Set<String> _nonAttendanceTokens = {
    'AB',
    'ABSENT',
    'UA',
    'W',
    'WH',
    'WH1',
    'I',
  };

  bool get isFailed {
    for (final value in _normalizedValues) {
      if (_failedTokens.contains(value) ||
          value.startsWith('RA') ||
          value.contains('FAIL')) {
        return true;
      }
    }

    return false;
  }

  bool get isNonAttendance {
    for (final value in _normalizedValues) {
      if (_nonAttendanceTokens.contains(value) || value.startsWith('WH')) {
        return true;
      }
    }

    return false;
  }

  bool get didAttendExam => _normalizedValues.isNotEmpty && !isNonAttendance;

  bool get isPassed => didAttendExam && !isFailed;

  bool get isFailedAfterAttending => didAttendExam && isFailed;

  List<String> get _normalizedValues {
    final values = <String>[];

    for (final rawValue in [mark, grade, result]) {
      final value = rawValue?.trim().toUpperCase();
      if (value == null || value.isEmpty) {
        continue;
      }

      values.add(value);
    }

    return values;
  }

  String get displayTitle => title.trim().isNotEmpty
      ? title.trim()
      : 'Subject title not available in PDF';

  String get displayMark =>
      mark?.trim().isNotEmpty == true ? mark!.trim() : '--';

  String get displayGrade =>
      grade?.trim().isNotEmpty == true ? grade!.trim() : '--';

  String get displayResult =>
      result?.trim().isNotEmpty == true ? result!.trim() : '--';
}
