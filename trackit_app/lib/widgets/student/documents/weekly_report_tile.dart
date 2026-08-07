import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/weekly_accomplishment_report.dart';
import '../../../utils/app_colors.dart';
import '../../common/status_badge.dart';

class WeeklyReportTile extends StatelessWidget {
  final WeeklyAccomplishmentReport report;
  final VoidCallback onTap;

  const WeeklyReportTile({super.key, required this.report, required this.onTap});

  StatusKind get _statusKind {
    switch (report.status) {
      case WeeklyReportStatus.missing:
        return StatusKind.missing;
      case WeeklyReportStatus.submitted:
        return StatusKind.submitted;
      case WeeklyReportStatus.approved:
        return StatusKind.approved;
      case WeeklyReportStatus.rejected:
        return StatusKind.rejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange =
        '${DateFormat('MMM d').format(report.weekStartDate)} - '
        '${DateFormat('MMM d, yyyy').format(report.weekEndDate)}';

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
                      'Week ${report.weekNumber}',
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
                dateRange,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (report.hasSubmission && report.attachments.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.attach_file,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${report.attachments.length} attachment'
                      '${report.attachments.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              if (report.remarks != null && report.remarks!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Remarks: ${report.remarks}',
                  style: const TextStyle(
                    color: AppColors.statRedIcon,
                    fontSize: 12,
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
