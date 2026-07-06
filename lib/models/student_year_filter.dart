import 'academic_year.dart';

enum StudentYearFilter {
  all,
  firstYear,
  secondYear,
  thirdYear,
  fourthYear,
  unknown,
}

extension StudentYearFilterX on StudentYearFilter {
  String get label {
    switch (this) {
      case StudentYearFilter.all:
        return 'All Years';
      case StudentYearFilter.firstYear:
        return 'First Year';
      case StudentYearFilter.secondYear:
        return 'Second Year';
      case StudentYearFilter.thirdYear:
        return 'Third Year';
      case StudentYearFilter.fourthYear:
        return 'Fourth Year';
      case StudentYearFilter.unknown:
        return 'Year Unknown';
    }
  }

  AcademicYear? get academicYear {
    switch (this) {
      case StudentYearFilter.all:
        return null;
      case StudentYearFilter.firstYear:
        return AcademicYear.firstYear;
      case StudentYearFilter.secondYear:
        return AcademicYear.secondYear;
      case StudentYearFilter.thirdYear:
        return AcademicYear.thirdYear;
      case StudentYearFilter.fourthYear:
        return AcademicYear.fourthYear;
      case StudentYearFilter.unknown:
        return AcademicYear.unknown;
    }
  }
}
