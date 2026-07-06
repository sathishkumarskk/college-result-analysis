enum StudentStatusFilter { all, allClear, arrear }

extension StudentStatusFilterX on StudentStatusFilter {
  String get label {
    switch (this) {
      case StudentStatusFilter.all:
        return 'All Students';
      case StudentStatusFilter.allClear:
        return 'Pass';
      case StudentStatusFilter.arrear:
        return 'Arrear';
    }
  }
}
