import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/activity_report.dart';
import '../../../utils/app_colors.dart';
import '../../common/status_badge.dart';

class ActivityReportCard extends StatelessWidget {
  final ActivityReport report;
  final VoidCallback onTap;

  const ActivityReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  StatusKind get _statusKind {
    switch (report.status) {
      case ActivityReportStatus.draft:
        return StatusKind.draft;
      case ActivityReportStatus.submitted:
        return StatusKind.submitted;
      case ActivityReportStatus.reviewed:
        return StatusKind.reviewed;
      case ActivityReportStatus.approved:
        return StatusKind.approved;
      case ActivityReportStatus.needsRevision:
        return StatusKind.needsRevision;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusBadge(kind: _statusKind),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('MMM d, yyyy').format(report.date)}  •  ${report.company}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatHours(report.hoursRendered)} hrs rendered',
                style: const TextStyle(
                  color: AppColors.primaryMaroon,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatHours(double hours) {
    return hours == hours.roundToDouble()
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
  }
}
