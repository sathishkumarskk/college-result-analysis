import 'package:flutter/material.dart';

import '../models/department_group.dart';
import '../models/exam_view_mode.dart';
import '../models/student_result.dart';
import 'student_result_card.dart';

/// Controls how student cards are arranged inside each status column.
/// - vertical: current layout, vertical column with normal page scrolling
/// - horizontal: cards inside a horizontally scrollable Row
enum StudentListLayout { vertical, horizontal }

class DepartmentSection extends StatelessWidget {
  const DepartmentSection({
    super.key,
    required this.group,
    required this.examViewMode,
    this.layout = StudentListLayout.vertical,
  });

  final DepartmentGroup group;
  final ExamViewMode examViewMode;
  final StudentListLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passChipColor = examViewMode == ExamViewMode.currentExam
        ? const Color(0xFFDFF4E6)
        : const Color(0xFFE5F1FA);
    final passColumnColor = examViewMode == ExamViewMode.currentExam
        ? const Color(0xFFF1FAF4)
        : const Color(0xFFEEF6FB);

    final passPercentage = group.totalStudents == 0
        ? 0.0
        : (group.passStudents.length / group.totalStudents);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.departmentName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            // Pass rate progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pass Rate: ${(passPercentage * 100).toStringAsFixed(1)}%  (${group.passStudents.length} passed / ${group.totalStudents} students)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 20,
                    child: LinearProgressIndicator(
                      value: passPercentage,
                      backgroundColor: const Color(
                        0xFFEF5350,
                      ), // Clean Material red
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF43A047),
                      ), // Material green
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _CountChip(
                  label: '${group.totalStudents} Entries',
                  color: theme.colorScheme.secondaryContainer,
                ),
                _CountChip(
                  label:
                      '${group.passStudents.length} ${examViewMode.passLabel}',
                  color: passChipColor,
                ),
                _CountChip(
                  label: '${group.arrearStudents.length} Arrear',
                  color: const Color(0xFFFFE2D9),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWide = constraints.maxWidth >= 800;
                final significantImbalance =
                    group.passStudents.length < 3 &&
                    group.arrearStudents.length > 5;
                final useTwoColumns = screenWide && !significantImbalance;

                final passColumn = _StatusColumn(
                  title: examViewMode.passSectionTitle,
                  students: group.passStudents,
                  backgroundColor: passColumnColor,
                  layout: layout,
                );
                final arrearColumn = _StatusColumn(
                  title: 'Arrear Students',
                  students: group.arrearStudents,
                  backgroundColor: const Color(0xFFFFF5F2),
                  layout: layout,
                );

                if (useTwoColumns) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: passColumn),
                      const SizedBox(width: 16),
                      Expanded(child: arrearColumn),
                    ],
                  );
                }

                // Single column layout: show pass students first, then arrear students with divider
                return Column(
                  children: [
                    passColumn,
                    if (group.passStudents.isNotEmpty &&
                        group.arrearStudents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],
                    if (group.arrearStudents.isNotEmpty) arrearColumn,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn({
    required this.title,
    required this.students,
    required this.backgroundColor,
    required this.layout,
  });

  final String title;
  final List<StudentResult> students;
  final Color backgroundColor;
  final StudentListLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (students.isEmpty)
            Text(
              'No students in this section.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Builder(
              builder: (context) {
                if (layout == StudentListLayout.vertical) {
                  // Existing vertical list layout (unchanged)
                  return Column(
                    children: students
                        .map(
                          (student) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StudentResultCard(student: student),
                          ),
                        )
                        .toList(),
                  );
                }

                // Horizontal layout: horizontally scrollable list of cards
                return LayoutBuilder(
                  builder: (context, c) {
                    final maxWidth = c.maxWidth;
                    // Pick a card width that looks good on desktop and web
                    // while keeping the existing StudentResultCard design intact.
                    final double cardWidth = maxWidth >= 1200
                        ? 420
                        : maxWidth >= 900
                        ? 360
                        : 320;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: students
                            .map(
                              (student) => Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: cardWidth,
                                  child: StudentResultCard(student: student),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
