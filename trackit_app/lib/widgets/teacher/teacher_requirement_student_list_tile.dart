import 'package:flutter/material.dart';
import '../../models/teacher_requirement_student_summary.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';

class TeacherRequirementStudentListTile extends StatelessWidget {
  final TeacherRequirementStudentSummary student;
  final VoidCallback onTap;

  const TeacherRequirementStudentListTile({
    super.key,
    required this.student,
    required this.onTap,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = student.progress >= 1
        ? AppColors.successGreenText
        : student.needsReviewCount > 0
            ? AppColors.statBlueIcon
            : AppColors.primaryMaroon;

    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.background,
                backgroundImage: student.avatarUrl != null
                    ? NetworkImage(ApiClient.resolveUrl(student.avatarUrl!))
                    : null,
                child: student.avatarUrl == null
                    ? Text(
                        _initials(student.name),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryMaroon,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (student.needsReviewCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statBlueBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${student.needsReviewCount} to review',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.statBlueIcon,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student.course} - ${student.section}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${student.completedCount} / ${student.totalDocuments} documents',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: student.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
