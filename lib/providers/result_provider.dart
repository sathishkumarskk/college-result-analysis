import 'package:flutter/foundation.dart';

import '../models/student_result.dart';
import '../models/academic_year.dart';
import '../models/exam_view_mode.dart';
import '../models/student_status_filter.dart';
import '../models/student_year_filter.dart';
import '../services/result_analyzer_service.dart';

class ResultProvider with ChangeNotifier {
  final ResultAnalyzerService _analyzerService = ResultAnalyzerService();

  List<StudentResult> _students = [];
  ExamViewMode _examViewMode = ExamViewMode.currentExam;
  AcademicYear _analysisYear = AcademicYear.firstYear;
  StudentStatusFilter _statusFilter = StudentStatusFilter.all;
  StudentYearFilter _yearFilter = StudentYearFilter.all;
  String _searchQuery = '';

  // Getters
  List<StudentResult> get students => _students;
  ExamViewMode get examViewMode => _examViewMode;
  AcademicYear get analysisYear => _analysisYear;
  StudentStatusFilter get statusFilter => _statusFilter;
  StudentYearFilter get yearFilter => _yearFilter;
  String get searchQuery => _searchQuery;

  List<StudentResult> get filteredStudents => _analyzerService.filterStudents(
        _students,
        query: _searchQuery,
        examViewMode: _examViewMode,
        filter: _statusFilter,
        yearFilter: _yearFilter,
      );

  // Setters
  void setStudents(List<StudentResult> students) {
    _students = students;
    notifyListeners();
  }

  void setExamViewMode(ExamViewMode mode) {
    _examViewMode = mode;
    notifyListeners();
  }

  void setAnalysisYear(AcademicYear year) {
    _analysisYear = year;
    notifyListeners();
  }

  void setStatusFilter(StudentStatusFilter filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setYearFilter(StudentYearFilter filter) {
    _yearFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Analysis methods
  Map<String, int> getDepartmentSummary() {
    return _analyzerService.getDepartmentSummary(filteredStudents);
  }

  Map<String, Map<String, int>> getDetailedDepartmentSummary() {
    return _analyzerService.getDetailedDepartmentSummary(filteredStudents);
  }

  void clearData() {
    _students = [];
    _searchQuery = '';
    _statusFilter = StudentStatusFilter.all;
    _yearFilter = StudentYearFilter.all;
    notifyListeners();
  }
}