import 'package:flutter/material.dart';

import '../models/exam_view_mode.dart';
import '../models/pdf_extraction_result.dart';
import '../models/result_summary.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({
    super.key,
    required this.summary,
    required this.examViewMode,
    required this.sourceName,
    required this.extractionStrategy,
  });

  final ResultSummary summary;
  final ExamViewMode examViewMode;
  final String? sourceName;
  final PdfExtractionStrategy? extractionStrategy;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Entries',
        value: summary.totalStudents,
        icon: Icons.groups_rounded,
      ),
      _MetricData(
        label: 'Departments',
        value: summary.totalDepartments,
        icon: Icons.apartment_rounded,
      ),
      _MetricData(
        label: examViewMode.passLabel,
        value: summary.passCount,
        icon: Icons.verified_rounded,
      ),
      _MetricData(
        label: 'Arrear',
        value: summary.arrearCount,
        icon: Icons.warning_amber_rounded,
      ),
      _MetricData(
        label: 'Subjects',
        value: summary.totalSubjects,
        icon: Icons.menu_book_rounded,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 960
                ? 3
                : constraints.maxWidth >= 520
                ? 2
                : 1;
            final totalSpacing = 12.0 * (columns - 1);
            final metricWidth = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - totalSpacing) / columns;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Snapshot',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sourceName == null
                      ? 'Upload a PDF to populate the dashboard.'
                      : 'Live counts for the selected exam view and current filters.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics
                      .map(
                        (metric) => SizedBox(
                          width: metricWidth,
                          child: _MetricCard(metric: metric),
                        ),
                      )
                      .toList(),
                ),
                if (sourceName != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Source',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sourceName!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (extractionStrategy != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Extraction Mode',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            extractionStrategy ==
                                PdfExtractionStrategy.ocrFallback
                            ? const Color(0xFFFFEBD7)
                            : const Color(0xFFE7F3EE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        extractionStrategy!.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine colors based on metric label
    Color backgroundColor;
    Color borderColor;
    Color iconColor;

    if (metric.label.toLowerCase().contains('pass')) {
      backgroundColor = const Color(0xFFE8F5E9); // Light green
      borderColor = const Color(0xFFA5D6A7); // Green-200
      iconColor = const Color(0xFF2E7D32); // Green
    } else if (metric.label.toLowerCase() == 'arrear') {
      backgroundColor = const Color(0xFFFFF3E0); // Light orange
      borderColor = const Color(0xFFFFB74D); // Orange-200
      iconColor = const Color(0xFFE65100); // Orange
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      borderColor = theme.colorScheme.outlineVariant;
      iconColor = theme.colorScheme.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: iconColor),
          const SizedBox(height: 10),
          Text(
            '${metric.value}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
