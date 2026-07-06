import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/academic_year.dart';
import '../models/exam_view_mode.dart';
import '../models/pdf_extraction_result.dart';
import '../models/student_result.dart';
import '../models/student_status_filter.dart';
import '../models/student_year_filter.dart';
import '../services/pdf_extraction_service.dart';
import '../services/result_analyzer_service.dart';
import '../services/result_parser_service.dart';
import '../services/excel_export_service.dart';
import '../widgets/department_section.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/summary_cards.dart';
import '../widgets/subject_analysis_panel.dart';
import '../widgets/upload_panel.dart';

class ResultAnalyzerScreen extends StatefulWidget {
  const ResultAnalyzerScreen({super.key});

  @override
  State<ResultAnalyzerScreen> createState() => _ResultAnalyzerScreenState();
}

class _ResultAnalyzerScreenState extends State<ResultAnalyzerScreen> {
  static const double _analysisPanelMaxWidth = 1320;

  final PdfExtractionService _pdfExtractionService = PdfExtractionService();
  final ResultParserService _resultParserService = ResultParserService();
  final ResultAnalyzerService _resultAnalyzerService = ResultAnalyzerService();
  final ExcelExportService _excelExportService = ExcelExportService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<StudentResult> _students = const [];
  String _searchQuery = '';
  ExamViewMode _examViewMode = ExamViewMode.currentExam;
  AcademicYear _analysisYear = AcademicYear.firstYear;
  StudentStatusFilter _statusFilter = StudentStatusFilter.all;
  StudentYearFilter _yearFilter = StudentYearFilter.all;
  String? _selectedSourceName;
  String _rawTextPreview = '';
  PdfExtractionStrategy? _extractionStrategy;
  String _analysisStatusMessage = '';
  String? _errorMessage;
  bool _isLoading = false;

  List<StudentResult> get _studentsInSelectedExamView => _resultAnalyzerService
      .studentsForExamView(_students, examViewMode: _examViewMode);

  List<StudentResult> get _filteredStudents =>
      _resultAnalyzerService.filterStudents(
        _students,
        query: _searchQuery,
        examViewMode: _examViewMode,
        filter: _statusFilter,
        yearFilter: _yearFilter,
      );

  ExamViewMode _defaultExamViewMode(List<StudentResult> students) {
    final currentExamStudents = _resultAnalyzerService.studentsForExamView(
      students,
      examViewMode: ExamViewMode.currentExam,
    );
    if (currentExamStudents.isNotEmpty) {
      return ExamViewMode.currentExam;
    }
    return ExamViewMode.arrearExam;
  }

  AcademicYear _defaultAnalysisYear(
    List<StudentResult> students, {
    required ExamViewMode examViewMode,
  }) {
    const supportedYears = [
      AcademicYear.firstYear,
      AcademicYear.secondYear,
      AcademicYear.thirdYear,
      AcademicYear.fourthYear,
    ];
    final examViewStudents = _resultAnalyzerService.studentsForExamView(
      students,
      examViewMode: examViewMode,
    );
    for (final year in supportedYears) {
      if (examViewStudents.any((student) => student.academicYear == year)) {
        return year;
      }
    }
    return AcademicYear.firstYear;
  }

  bool _hasAnalysisDataForYear(
    List<StudentResult> students, {
    required ExamViewMode examViewMode,
    required AcademicYear year,
  }) {
    return _resultAnalyzerService
        .studentsForExamView(students, examViewMode: examViewMode)
        .any((student) => student.academicYear == year);
  }

  bool get _isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  bool get _usesDesktopSaveDialog =>
      !kIsWeb &&
      const {
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      }.contains(defaultTargetPlatform);

  Future<Uint8List> _readPickedFileBytes(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return bytes;
    }
    return file.xFile.readAsBytes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyzePdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _analysisStatusMessage = 'Waiting for PDF selection...';
    });

    try {
      final pickedFile = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select an Anna University result PDF',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: kIsWeb,
        lockParentWindow: _isWindowsDesktop,
      );

      if (pickedFile == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _analysisStatusMessage = '';
        });
        return;
      }

      final file = pickedFile.files.single;
      final bytes = await _readPickedFileBytes(file);

      if (bytes.isEmpty) {
        throw StateError('The selected PDF could not be read.');
      }

      if (!mounted) return;

      setState(() {
        _selectedSourceName = file.name;
        _students = const [];
        _searchController.clear();
        _searchQuery = '';
        _examViewMode = ExamViewMode.currentExam;
        _analysisYear = AcademicYear.firstYear;
        _statusFilter = StudentStatusFilter.all;
        _yearFilter = StudentYearFilter.all;
        _rawTextPreview = '';
        _extractionStrategy = null;
        _analysisStatusMessage = 'Validating the selected PDF...';
      });

      final extension = file.extension?.toLowerCase();
      if (extension != 'pdf' ||
          !_pdfExtractionService.looksLikePdfBytes(bytes)) {
        throw const FormatException(
          'Wrong file type. Please upload the correct Anna University result PDF again.',
        );
      }

      setState(() {
        _analysisStatusMessage = 'Reading embedded text from the PDF...';
      });

      final digitalExtraction = await _pdfExtractionService.extractText(bytes);
      final trimmedDigitalText = digitalExtraction.text.trim();
      if (trimmedDigitalText.isNotEmpty &&
          !_resultParserService.looksLikeSupportedAnnaUniversityResult(
            trimmedDigitalText,
          )) {
        throw const FormatException(
          'Wrong PDF format. Please upload the correct Anna University result PDF again.',
        );
      }
      var chosenExtraction = digitalExtraction;
      var students = _resultParserService.parseFromRawText(
        digitalExtraction.text,
      );

      final trimmedRawText = chosenExtraction.text.trim();

      if (!mounted) return;

      setState(() {
        _selectedSourceName = file.name;
        _rawTextPreview = trimmedRawText;
        _extractionStrategy = chosenExtraction.strategy;
        _students = students;
        _examViewMode = _defaultExamViewMode(students);
        _analysisYear = _defaultAnalysisYear(
          students,
          examViewMode: _defaultExamViewMode(students),
        );
        _isLoading = false;
        _analysisStatusMessage = '';
        _errorMessage = _buildUploadErrorMessage(
          extractedText: trimmedRawText,
          students: students,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _students = const [];
        _rawTextPreview = '';
        _extractionStrategy = null;
        _analysisStatusMessage = '';
        _errorMessage = error is FormatException
            ? error.message
            : 'Unable to parse this file. Please upload the correct Anna University result PDF again.';
      });
    }
  }

  String? _buildUploadErrorMessage({
    required String extractedText,
    required List<StudentResult> students,
  }) {
    if (extractedText.isEmpty) {
      return 'No readable text was extracted from this PDF. Please upload the correct Anna University result PDF again.';
    }
    if (students.isNotEmpty) return null;
    if (!_resultParserService.looksLikeSupportedAnnaUniversityResult(
      extractedText,
    )) {
      return 'Wrong PDF format. Please upload the correct Anna University result PDF again.';
    }
    return 'This PDF could not be organized into result categories. Please upload the correct Anna University result PDF again.';
  }

  Future<void> _exportToExcel() async {
    if (_students.isEmpty) return;

    try {
      String? destinationPath;

      if (_usesDesktopSaveDialog) {
        destinationPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Excel analysis',
          fileName: _excelExportService.suggestedFileName(
            sourceName: _selectedSourceName,
          ),
          type: FileType.custom,
          allowedExtensions: const ['xlsx'],
          lockParentWindow: _isWindowsDesktop,
        );

        if (destinationPath == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Excel export canceled.')),
            );
          }
          return;
        }
      }

      final filePath = await _excelExportService.exportToExcel(
        _students,
        destinationPath: destinationPath,
        sourceName: _selectedSourceName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Excel download started: $filePath'
                  : 'Excel file exported to: $filePath',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError
                  ? e.message.toString()
                  : 'Failed to export Excel file',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsInSelectedExamView = _studentsInSelectedExamView;
    final filteredStudents = _filteredStudents;
    final analysisEntries = _resultAnalyzerService.buildSubjectAnalysis(
      studentsInSelectedExamView,
      academicYear: _analysisYear,
    );
    final analysisOverview = _resultAnalyzerService
        .buildSubjectAnalysisOverview(
          studentsInSelectedExamView,
          academicYear: _analysisYear,
        );
    final groups = _resultAnalyzerService.groupStudentsByDepartment(
      filteredStudents,
    );
    final summary = _resultAnalyzerService.buildSummary(filteredStudents);
    final currentExamStudentCount = _resultAnalyzerService
        .studentsForExamView(_students, examViewMode: ExamViewMode.currentExam)
        .length;
    final arrearExamStudentCount = _resultAnalyzerService
        .studentsForExamView(_students, examViewMode: ExamViewMode.arrearExam)
        .length;

    final searchFilterBar = SearchFilterBar(
      controller: _searchController,
      selectedExamViewMode: _examViewMode,
      selectedFilter: _statusFilter,
      selectedYearFilter: _yearFilter,
      currentExamStudentCount: currentExamStudentCount,
      arrearExamStudentCount: arrearExamStudentCount,
      enabled: _students.isNotEmpty,
      onQueryChanged: (value) => setState(() => _searchQuery = value),
      onExamViewModeChanged: (value) {
        setState(() {
          _examViewMode = value;
          _analysisYear =
              _hasAnalysisDataForYear(
                _students,
                examViewMode: value,
                year: _analysisYear,
              )
              ? _analysisYear
              : _defaultAnalysisYear(_students, examViewMode: value);
          _statusFilter = StudentStatusFilter.all;
        });
      },
      onFilterChanged: (value) => setState(() => _statusFilter = value),
      onYearFilterChanged: (value) => setState(() => _yearFilter = value),
    );

    final subjectAnalysisPanel = SubjectAnalysisPanel(
      enabled: studentsInSelectedExamView.isNotEmpty,
      examViewMode: _examViewMode,
      selectedYear: _analysisYear,
      analysisEntries: analysisEntries,
      analysisOverview: analysisOverview,
      onYearChanged: (value) => setState(() => _analysisYear = value),
    );

    final uploadPanel = UploadPanel(
      isLoading: _isLoading,
      analysisStatusMessage: _analysisStatusMessage,
      errorMessage: _errorMessage,
      selectedSourceName: _selectedSourceName,
      rawTextPreview: _rawTextPreview,
      onPickPdf: _pickAndAnalyzePdf,
    );

    final summaryCards = SummaryCards(
      summary: summary,
      examViewMode: _examViewMode,
      sourceName: _selectedSourceName,
      extractionStrategy: _extractionStrategy,
    );

    final dashboardControls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchFilterBar,
      ],
    );

    final hasVisibleGroups = groups.isNotEmpty;
    final resultsSection = hasVisibleGroups
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: groups
                .map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DepartmentSection(
                      group: group,
                      examViewMode: _examViewMode,
                    ),
                  ),
                )
                .toList(),
          )
        : _selectedSourceName == null && !_isLoading
        ? const _EmptyState(
            title: 'Upload an Anna University result PDF',
            message:
                'The app extracts the student details, separates current exam and arrear exam students, and then groups the uploaded PDF into pass and arrear lists.',
          )
        : !_isLoading
        ? const _EmptyState(
            title: 'No students match the current filter',
            message:
                'Try clearing the search term or switching the status, year, or exam-view filters back to their full view.',
          )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Analyzer'),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (_students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                onPressed: _exportToExcel,
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Export to Excel',
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF4FF), Color(0xFFD6EAF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 940;
                  final isExtraWide = constraints.maxWidth >= 1240;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _Header(
                        examViewMode: _examViewMode,
                        visibleStudentCount: filteredStudents.length,
                        totalStudentCount: studentsInSelectedExamView.length,
                      ),
                      const SizedBox(height: 20),

                      if (isWide) ...[
                        // ── WIDE LAYOUT ──────────────────────────────
                        // LEFT  = upload panel + filters + export button
                        // RIGHT = summary cards
                        // BELOW = subject analysis + student result cards
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isExtraWide ? 7 : 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  uploadPanel,
                                  const SizedBox(height: 16),
                                  dashboardControls,
                                ],
                              ),
                            ),
                            SizedBox(width: isExtraWide ? 20 : 16),
                            Expanded(
                              flex: isExtraWide ? 6 : 2,
                              child: summaryCards,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _analysisPanelMaxWidth,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: subjectAnalysisPanel,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        resultsSection,
                      ] else ...[
                        // ── NARROW / MOBILE LAYOUT ───────────────────
                        uploadPanel,
                        const SizedBox(height: 16),
                        summaryCards,
                        const SizedBox(height: 16),
                        dashboardControls,
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: subjectAnalysisPanel,
                        ),
                        const SizedBox(height: 16),
                        resultsSection,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.examViewMode,
    required this.visibleStudentCount,
    required this.totalStudentCount,
  });

  final ExamViewMode examViewMode;
  final int visibleStudentCount;
  final int totalStudentCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;

            final infoText = Text(
              totalStudentCount == 0
                  ? 'Upload a real Anna University result PDF to extract, analyze, and group students by department.'
                  : 'Showing $visibleStudentCount of $totalStudentCount entries in the ${examViewMode.label.toLowerCase()} view.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            );

            final badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Web + Mobile Ready',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge,
                  const SizedBox(height: 16),
                  Text(
                    'Student Result Analyzer',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  infoText,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                badge,
                const SizedBox(height: 16),
                Text(
                  'Student Result Analyzer',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                infoText,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
