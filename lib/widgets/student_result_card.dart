import 'package:flutter/material.dart';

import '../models/academic_year.dart';
import '../models/student_result.dart';
import '../models/subject_result.dart';

class StudentResultCard extends StatefulWidget {
  const StudentResultCard({super.key, required this.student});

  final StudentResult student;

  @override
  State<StudentResultCard> createState() => _StudentResultCardState();
}

class _StudentResultCardState extends State<StudentResultCard> {
  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final theme = Theme.of(context);
    final isArrear = student.status == ResultStatus.arrear;
    final isArrearExamStudent = student.isArrearExamStudent;
    final statusColor = isArrear
        ? const Color(0xFFB3531A)
        : isArrearExamStudent
        ? const Color(0xFF1F5D8E)
        : const Color(0xFF147D45);
    final statusBackground = isArrear
        ? const Color(0xFFFFE2D9)
        : isArrearExamStudent
        ? const Color(0xFFE5F1FA)
        : const Color(0xFFDFF4E6);

    // Preserve the original subject ordering from the parser instead of hiding
    // failure-only rows behind the default collapsed UI.
    final sortedSubjects = [...student.subjects]
      ..sort((a, b) {
        if (a.isFailed && !b.isFailed) return -1;
        if (!a.isFailed && b.isFailed) return 1;
        return 0;
      });

    final failedCount = student.failedSubjectCount;

    // For pass students, get top 2 highest grade subjects
    List<SubjectResult> topSubjects = [];
    if (!isArrear) {
      final passedSubjects = student.subjects.where((s) => !s.isFailed && s.grade != null).toList()
        ..sort((a, b) {
          // Sort by grade quality: O > A+ > A > B+ > B > C > etc.
          const gradeOrder = ['O', 'A+', 'A', 'B+', 'B', 'C', 'D', 'E', 'F'];
          final aIndex = gradeOrder.indexOf(a.grade!.toUpperCase());
          final bIndex = gradeOrder.indexOf(b.grade!.toUpperCase());
          if (aIndex != -1 && bIndex != -1) {
            return aIndex.compareTo(bIndex);
          }
          return a.grade!.compareTo(b.grade!);
        });
      topSubjects = passedSubjects.take(2).toList();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final studentInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Register No: ${student.registerNumber}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.school_rounded,
                        label: student.academicYearLabel,
                        backgroundColor: const Color(0xFFE7F3EE),
                        textColor: theme.colorScheme.primary,
                      ),
                      if (student.academicYear != AcademicYear.unknown)
                        _MetaChip(
                          icon: Icons.calendar_view_week_rounded,
                          label: student.semesterLabel,
                          backgroundColor: const Color(0xFFF4E5C6),
                          textColor: theme.colorScheme.onSurface,
                        ),
                    ],
                  ),
                ],
              );

              final statusChip = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  student.statusLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    studentInfo,
                    const SizedBox(height: 12),
                    statusChip,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: studentInfo),
                  const SizedBox(width: 12),
                  statusChip,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          if (!isArrear && topSubjects.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topSubjects.map((subject) => Chip(
                label: Text('${subject.code} • ${subject.grade}'),
                backgroundColor: const Color(0xFFDFF4E6),
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF147D45),
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_mosaic_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${student.subjects.length} subjects',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (failedCount > 0)
                Text(
                  '$failedCount failed',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (student.subjects.isEmpty)
            Text(
              'No subject rows matched the current parser for this student.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Column(
              children: sortedSubjects
                  .map(
                    (subject) => _SubjectRow(subject: subject, theme: theme),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.subject, required this.theme});

  final SubjectResult subject;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: subject.isFailed
            ? const Color(0xFFFFF3EE)
            : const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final subjectDetails = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.code,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subject.title.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subject.displayTitle,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          );

          // Determine grade badge color
          Color? gradeBadgeColor;
          Color gradeBadgeTextColor = Colors.white;

          if (subject.grade != null) {
            final gradeStr = subject.grade!.toUpperCase();
            if (['O', 'A+', 'A'].contains(gradeStr)) {
              gradeBadgeColor = const Color(0xFF147D45); // Green
            } else if (['B+', 'B'].contains(gradeStr)) {
              gradeBadgeColor = const Color(0xFF1F5D8E); // Blue
            } else if (['U', 'RA'].contains(gradeStr) || subject.isFailed) {
              gradeBadgeColor = const Color(0xFFB3531A); // Red
            }
          }

          final gradeBadge = gradeBadgeColor != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: gradeBadgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    subject.grade ?? '',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: gradeBadgeTextColor,
                    ),
                  ),
                )
              : const SizedBox.shrink();

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                subjectDetails,
                const SizedBox(height: 10),
                gradeBadge,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: subjectDetails),
              const SizedBox(width: 12),
              gradeBadge,
            ],
          );
        },
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
