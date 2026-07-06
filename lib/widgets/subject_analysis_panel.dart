import 'package:flutter/material.dart';

import '../models/academic_year.dart';
import '../models/exam_view_mode.dart';
import '../models/subject_analysis_entry.dart';
import '../models/subject_analysis_overview.dart';

class SubjectAnalysisPanel extends StatelessWidget {
  const SubjectAnalysisPanel({
    super.key,
    required this.enabled,
    required this.examViewMode,
    required this.selectedYear,
    required this.analysisEntries,
    required this.analysisOverview,
    required this.onYearChanged,
  });

  final bool enabled;
  final ExamViewMode examViewMode;
  final AcademicYear selectedYear;
  final List<SubjectAnalysisEntry> analysisEntries;
  final SubjectAnalysisOverview analysisOverview;
  final ValueChanged<AcademicYear> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const supportedYears = [
      AcademicYear.firstYear,
      AcademicYear.secondYear,
      AcademicYear.thirdYear,
      AcademicYear.fourthYear,
    ];

    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subject Analysis',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                enabled
                    ? 'Choose a year to inspect subject-wise results for the selected ${examViewMode.label.toLowerCase()} view. Pass % uses students who attended the exam.'
                    : 'Upload a PDF to unlock subject-wise analysis from first year to fourth year.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: supportedYears.map((year) {
                  return ChoiceChip(
                    label: Text(year.label),
                    selected: selectedYear == year,
                    onSelected: enabled ? (_) => onYearChanged(year) : null,
                    selectedColor: theme.colorScheme.secondaryContainer,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selectedYear == year
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              if (!enabled)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No analysis available yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload a PDF to unlock subject-wise analysis from first year to fourth year.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else if (analysisEntries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_off_rounded,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students found for this year',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No subject rows were found for ${selectedYear.label} in the ${examViewMode.label.toLowerCase()} view. Try selecting a different year or exam view.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _AnalysisChip(
                      label: 'Students',
                      value: '${analysisOverview.totalStudents}',
                    ),
                    _AnalysisChip(
                      label: 'Subjects',
                      value: '${analysisEntries.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          columnSpacing: 18,
                          headingRowHeight: 48,
                          dataRowMinHeight: 66,
                          dataRowMaxHeight: 78,
                          headingRowColor: WidgetStatePropertyAll(
                            theme.colorScheme.surface.withValues(alpha: 0.95),
                          ),
                          columns: [
                            DataColumn(
                              label: Text(
                                'Subject',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Semester',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Students',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Attended',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Pass',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Fail',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Pass %',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          rows: analysisEntries.map((entry) {
                            // Determine color based on pass percentage
                            Color passPercentageColor;
                            if (entry.passPercentage < 50) {
                              passPercentageColor = Colors.red;
                            } else if (entry.passPercentage < 75) {
                              passPercentageColor = Colors.orange;
                            } else {
                              passPercentageColor = const Color(0xFF147D45);
                            }

                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 220,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.subjectCode,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (entry.displayTitle != '—')
                                          Text(
                                            entry.displayTitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(Text(entry.semesterLabel)),
                                DataCell(Text('${entry.studentCount}')),
                                DataCell(Text('${entry.attendedCount}')),
                                DataCell(Text('${entry.passCount}')),
                                DataCell(Text('${entry.failCount}')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: passPercentageColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      entry.passPercentageLabel,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: passPercentageColor,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedYear.label} Overall Result',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'All clear students are counted as students who passed every subject in the selected year and ${examViewMode.label.toLowerCase()} view.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _AnalysisChip(
                            label: 'All Clear Students',
                            value: analysisOverview.passRatioLabel,
                          ),
                          _AnalysisChip(
                            label: 'Overall Pass %',
                            value: analysisOverview.passPercentageLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisChip extends StatelessWidget {
  const _AnalysisChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
