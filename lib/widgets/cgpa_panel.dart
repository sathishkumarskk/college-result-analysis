import 'package:flutter/material.dart';

import '../models/cgpa_summary.dart';

class CgpaAnalysisPanel extends StatelessWidget {
  const CgpaAnalysisPanel({
    super.key,
    required this.enabled,
    required this.averageCgpa,
    required this.studentSummaries,
  });

  final bool enabled;
  final double averageCgpa;
  final List<CgpaSummary> studentSummaries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topStudents = [...studentSummaries]
      ..sort((a, b) => b.overallCgpa.compareTo(a.overallCgpa));

    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.08),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CGPA Analysis',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              enabled
                  ? 'Review semester GPA performance and overall CGPA across parsed student records.'
                  : 'Upload a PDF to reveal CGPA performance and summary data.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SummaryTile(
                  label: 'Avg CGPA',
                  value: averageCgpa > 0 ? averageCgpa.toStringAsFixed(2) : '--',
                  icon: Icons.auto_graph_rounded,
                  backgroundColor: const Color(0xFFEAF4FF),
                ),
                _SummaryTile(
                  label: 'Students Count',
                  value: enabled ? '${studentSummaries.length}' : '--',
                  icon: Icons.group_rounded,
                  backgroundColor: const Color(0xFFF3F7FF),
                ),
                _SummaryTile(
                  label: 'Top Classification',
                  value: enabled && studentSummaries.isNotEmpty
                      ? studentSummaries
                          .map((summary) => summary.classification)
                          .toSet()
                          .first
                      : '--',
                  icon: Icons.workspace_premium_rounded,
                  backgroundColor: const Color(0xFFF9F4FF),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (enabled && topStudents.isNotEmpty) ...[
              Text(
                'Top CGPA Students',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: topStudents.take(4).map((summary) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.studentName,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary.registerNumber,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              summary.overallCgpa.toStringAsFixed(2),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary.classification,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
