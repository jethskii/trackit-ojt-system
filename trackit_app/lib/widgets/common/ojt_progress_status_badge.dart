import 'package:flutter/material.dart';
import '../../models/ojt_progress.dart';
import '../../utils/app_colors.dart';

/// Single source of truth for how each [OjtProgressStatus] value looks --
/// shared between the student's own OJT Hours Progress card and the
/// Teacher module's Students list/detail views, so "Behind" (for
/// example) means the same color and label everywhere it appears.
(String, IconData, Color, Color) ojtProgressStatusStyle(OjtProgressStatus status) {
  switch (status) {
    case OjtProgressStatus.aheadOfSchedule:
      return (
        'Ahead of Schedule',
        Icons.trending_up,
        AppColors.successGreenBg,
        AppColors.successGreenText,
      );
    case OjtProgressStatus.onTrack:
      return (
        'On Track',
        Icons.check_circle_outline,
        AppColors.statBlueBg,
        AppColors.statBlueIcon,
      );
    case OjtProgressStatus.behind:
      return (
        'Behind',
        Icons.trending_down,
        AppColors.statOrangeBg,
        AppColors.statOrangeIcon,
      );
    case OjtProgressStatus.needsAttention:
      return (
        'Needs Attention',
        Icons.warning_amber_rounded,
        AppColors.statRedBg,
        AppColors.statRedIcon,
      );
    case OjtProgressStatus.completed:
      return (
        'Completed',
        Icons.check_circle,
        AppColors.successGreenBg,
        AppColors.successGreenText,
      );
  }
}

class OjtProgressStatusBadge extends StatelessWidget {
  final OjtProgressStatus status;

  const OjtProgressStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, text) = ojtProgressStatusStyle(status);

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
