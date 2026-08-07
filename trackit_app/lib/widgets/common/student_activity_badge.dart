import 'package:flutter/material.dart';
import '../../models/ojt_progress.dart';
import '../../models/ojt_stage.dart';
import '../../utils/app_colors.dart';

/// A single badge combining OJT lifecycle stage (Active/Preparing/Not
/// Started/Completed) with pace ([OjtProgressStatus]) into the one label a
/// teacher actually scans a student list for. Deliberately just two
/// colors: green means "on pace and actively logging hours right now",
/// red means anything else that needs the teacher's attention (falling
/// behind, not yet started, still preparing) -- the progress bar below
/// reuses this same color so the two always match.
(String, IconData, Color, Color) studentActivityStyle({
  required OjtStage stage,
  required OjtProgressStatus progressStatus,
}) {
  const green = (AppColors.successGreenBg, AppColors.successGreenText);
  const red = (AppColors.statRedBg, AppColors.statRedIcon);

  if (stage == OjtStage.completed) {
    return ('Completed', Icons.check_circle, green.$1, green.$2);
  }
  if (stage == OjtStage.active) {
    final onPace = progressStatus != OjtProgressStatus.behind &&
        progressStatus != OjtProgressStatus.needsAttention;
    if (onPace) {
      return ('Active', Icons.directions_run, green.$1, green.$2);
    }
    final label = progressStatus == OjtProgressStatus.needsAttention
        ? 'Needs Attention'
        : 'Behind';
    return (label, Icons.trending_down, red.$1, red.$2);
  }
  if (stage == OjtStage.readyForDeployment) {
    return ('Preparing', Icons.flight_takeoff, red.$1, red.$2);
  }
  return ('Inactive', Icons.pause_circle_outline, red.$1, red.$2);
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
