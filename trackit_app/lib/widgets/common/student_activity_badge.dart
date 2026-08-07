import 'package:flutter/material.dart';
import '../../models/ojt_progress.dart';
import '../../models/ojt_stage.dart';
import '../../utils/app_colors.dart';
import 'ojt_progress_status_badge.dart';

/// A single badge combining OJT lifecycle stage (Active/Preparing/Not
/// Started/Completed) with pace ([OjtProgressStatus]) into the one label a
/// teacher actually scans a student list for: is this student currently
/// active, and if so, are they falling behind. A pace warning (Behind /
/// Needs Attention) always takes priority over the plain "Active" label
/// since it's the more actionable signal; otherwise it falls back to the
/// student's lifecycle stage.
(String, IconData, Color, Color) studentActivityStyle({
  required OjtStage stage,
  required OjtProgressStatus progressStatus,
}) {
  if (stage == OjtStage.completed) {
    return (
      'Completed',
      Icons.check_circle,
      AppColors.successGreenBg,
      AppColors.successGreenText,
    );
  }
  if (stage == OjtStage.active &&
      (progressStatus == OjtProgressStatus.behind ||
          progressStatus == OjtProgressStatus.needsAttention)) {
    return ojtProgressStatusStyle(progressStatus);
  }
  switch (stage) {
    case OjtStage.active:
      return (
        'Active',
        Icons.directions_run,
        AppColors.successGreenBg,
        AppColors.successGreenText,
      );
    case OjtStage.readyForDeployment:
      return (
        'Preparing',
        Icons.flight_takeoff,
        AppColors.statOrangeBg,
        AppColors.statOrangeIcon,
      );
    case OjtStage.completed:
      return (
        'Completed',
        Icons.check_circle,
        AppColors.successGreenBg,
        AppColors.successGreenText,
      );
    case OjtStage.notStarted:
      return (
        'Inactive',
        Icons.pause_circle_outline,
        AppColors.chipGrayBg,
        AppColors.textSecondary,
      );
  }
}

class StudentActivityBadge extends StatelessWidget {
  final OjtStage stage;
  final OjtProgressStatus progressStatus;

  const StudentActivityBadge({
    super.key,
    required this.stage,
    required this.progressStatus,
  });

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, text) =
        studentActivityStyle(stage: stage, progressStatus: progressStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
          ),
        ],
      ),
    );
  }
}
