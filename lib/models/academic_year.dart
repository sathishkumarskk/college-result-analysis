enum AcademicYear { firstYear, secondYear, thirdYear, fourthYear, unknown }

extension AcademicYearX on AcademicYear {
  String get label {
    switch (this) {
      case AcademicYear.firstYear:
        return 'First Year';
      case AcademicYear.secondYear:
        return 'Second Year';
      case AcademicYear.thirdYear:
        return 'Third Year';
      case AcademicYear.fourthYear:
        return 'Fourth Year';
      case AcademicYear.unknown:
        return 'Year Unknown';
    }
  }
}

AcademicYear academicYearFromSemester(int? semesterNumber) {
  switch (semesterNumber) {
    case 1:
    case 2:
      return AcademicYear.firstYear;
    case 3:
    case 4:
      return AcademicYear.secondYear;
    case 5:
    case 6:
      return AcademicYear.thirdYear;
    case 7:
    case 8:
      return AcademicYear.fourthYear;
    default:
      return AcademicYear.unknown;
  }
}

int? courseYearFromSemester(int? semesterNumber) {
  switch (semesterNumber) {
    case 1:
    case 2:
      return 1;
    case 3:
    case 4:
      return 2;
    case 5:
    case 6:
      return 3;
    case 7:
    case 8:
      return 4;
    default:
      return null;
  }
}

AcademicYear academicYearFromCourseYear(int? courseYear) {
  switch (courseYear) {
    case 1:
      return AcademicYear.firstYear;
    case 2:
      return AcademicYear.secondYear;
    case 3:
      return AcademicYear.thirdYear;
    case 4:
      return AcademicYear.fourthYear;
    default:
      return AcademicYear.unknown;
  }
}
