import 'package:flutter/material.dart';

import '../models/exam_view_mode.dart';
import '../models/student_status_filter.dart';
import '../models/student_year_filter.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.selectedExamViewMode,
    required this.selectedFilter,
    required this.selectedYearFilter,
    required this.currentExamStudentCount,
    required this.arrearExamStudentCount,
    required this.enabled,
    required this.onQueryChanged,
    required this.onExamViewModeChanged,
    required this.onFilterChanged,
    required this.onYearFilterChanged,
  });

  final TextEditingController controller;
  final ExamViewMode selectedExamViewMode;
  final StudentStatusFilter selectedFilter;
  final StudentYearFilter selectedYearFilter;
  final int currentExamStudentCount;
  final int arrearExamStudentCount;
  final bool enabled;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<ExamViewMode> onExamViewModeChanged;
  final ValueChanged<StudentStatusFilter> onFilterChanged;
  final ValueChanged<StudentYearFilter> onYearFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 960;
            final searchField = TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onQueryChanged,
              decoration: const InputDecoration(
                hintText:
                    'Search by name, register number, subject, or department',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            );

            final filterField = DropdownButtonFormField<StudentStatusFilter>(
              initialValue: selectedFilter,
              items: StudentStatusFilter.values
                  .map(
                    (filter) => DropdownMenuItem<StudentStatusFilter>(
                      value: filter,
                      child: Text(_statusFilterLabel(filter)),
                    ),
                  )
                  .toList(),
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        onFilterChanged(value);
                      }
                    }
                  : null,
              decoration: const InputDecoration(
                labelText: 'Status Filter',
                prefixIcon: Icon(Icons.filter_alt_rounded),
              ),
            );

            final examViewSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fact_check_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View PDF As',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ExamViewChip(
                      label: 'Current Exam',
                      count: currentExamStudentCount,
                      selected:
                          selectedExamViewMode == ExamViewMode.currentExam,
                      enabled: enabled && currentExamStudentCount > 0,
                      onSelected: () =>
                          onExamViewModeChanged(ExamViewMode.currentExam),
                    ),
                    _ExamViewChip(
                      label: 'Arrear Exam',
                      count: arrearExamStudentCount,
                      selected: selectedExamViewMode == ExamViewMode.arrearExam,
                      enabled: enabled && arrearExamStudentCount > 0,
                      onSelected: () =>
                          onExamViewModeChanged(ExamViewMode.arrearExam),
                    ),
                  ],
                ),
              ],
            );

            final yearSplitSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Split By Year',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: StudentYearFilter.values.map((filter) {
                    return ChoiceChip(
                      label: Text(filter.label),
                      selected: selectedYearFilter == filter,
                      onSelected: enabled
                          ? (_) => onYearFilterChanged(filter)
                          : null,
                      selectedColor: theme.colorScheme.secondaryContainer,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selectedYearFilter == filter
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      avatar: Icon(
                        filter == StudentYearFilter.all
                            ? Icons.dashboard_customize_rounded
                            : Icons.class_rounded,
                        size: 16,
                        color: selectedYearFilter == filter
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }).toList(),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  examViewSection,
                  const SizedBox(height: 16),
                  yearSplitSection,
                  const SizedBox(height: 16),
                  searchField,
                  const SizedBox(height: 12),
                  filterField,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                examViewSection,
                const SizedBox(height: 16),
                yearSplitSection,
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(flex: 3, child: searchField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: filterField),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusFilterLabel(StudentStatusFilter filter) {
    switch (filter) {
      case StudentStatusFilter.all:
        return 'All Students';
      case StudentStatusFilter.allClear:
        return selectedExamViewMode.passLabel;
      case StudentStatusFilter.arrear:
        return 'Arrear';
    }
  }
}

class _ExamViewChip extends StatelessWidget {
  const _ExamViewChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String label;
  final int count;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: enabled ? (_) => onSelected() : null,
      selectedColor: theme.colorScheme.secondaryContainer,
      backgroundColor: Colors.white,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      ),
      avatar: Icon(
        Icons.article_outlined,
        size: 16,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
