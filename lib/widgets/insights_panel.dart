import 'package:flutter/material.dart';

import '../models/academic_year.dart';
import '../models/exam_view_mode.dart';
import '../models/subject_analysis_entry.dart';
import '../models/subject_analysis_overview.dart';

class InsightsPanel extends StatelessWidget {
  const InsightsPanel({
    super.key,
    required this.enabled,
    required this.examViewMode,
    required this.selectedYear,
    required this.analysisEntries,
    required this.analysisOverview,
  });

  final bool enabled;
  final ExamViewMode examViewMode;
  final AcademicYear selectedYear;
  final List<SubjectAnalysisEntry> analysisEntries;
  final SubjectAnalysisOverview analysisOverview;

  String? get _mostDifficultSubject {
    if (analysisEntries.isEmpty) return null;
    final sorted = analysisEntries.toList()
      ..sort((a, b) => a.passPercentage.compareTo(b.passPercentage));
    return sorted.first.passPercentage < 50 ? sorted.first.subjectCode : null;
  }

  String? get _highestPassRateSubject {
    if (analysisEntries.isEmpty) return null;
    final sorted = analysisEntries.toList()
      ..sort((a, b) => b.passPercentage.compareTo(a.passPercentage));
    return sorted.first.passPercentage > 80 ? sorted.first.subjectCode : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!enabled || analysisEntries.isEmpty) {
      return Card(
        elevation: 2,
        shadowColor: theme.shadowColor.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Insights',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload a PDF to unlock intelligent insights and recommendations.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final insights = [
      if (_mostDifficultSubject != null)
        _InsightCard(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red,
          title: 'Most Challenging Subject',
          value: _mostDifficultSubject!,
          subtitle: 'Consider additional support or review',
        ),
      _InsightCard(
        icon: Icons.trending_up_rounded,
        iconColor: const Color(0xFF4CAF50),
        title: 'Overall Pass Rate',
        value: '${analysisOverview.passPercentage.toStringAsFixed(1)}%',
        subtitle: '${analysisOverview.passStudents} out of ${analysisOverview.totalStudents} students',
      ),
      if (_highestPassRateSubject != null)
        _InsightCard(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFFFC107),
          title: 'Highest Performing Subject',
          value: _highestPassRateSubject!,
          subtitle: 'Excellent results in this area',
        ),
    ];

    return Card(
      elevation: 3,
      shadowColor: theme.shadowColor.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Insights',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Key insights from ${selectedYear.label} ${examViewMode.label.toLowerCase()} analysis.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: insights,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}