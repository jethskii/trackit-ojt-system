import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

enum StatusKind {
  locked,
  inProgress,
  completed,
  missing,
  pending,
  submitted,
  approved,
  rejected,
  draft,
  reviewed,
  needsRevision,
}

class StatusBadge extends StatelessWidget {
  final StatusKind kind;
  final String? labelOverride;

  const StatusBadge({super.key, required this.kind, this.labelOverride});

  _StatusStyle get _style {
    switch (kind) {
      case StatusKind.locked:
        return const _StatusStyle(
          'Locked',
          AppColors.chipGrayBg,
          AppColors.textSecondary,
        );
      case StatusKind.inProgress:
        return const _StatusStyle(
          'In Progress',
          AppColors.successGreenBg,
          AppColors.successGreenText,
        );
      case StatusKind.completed:
        return const _StatusStyle(
          'Completed',
          AppColors.successGreenBg,
          AppColors.successGreenText,
        );
      case StatusKind.missing:
        return const _StatusStyle(
          'Missing',
          AppColors.statRedBg,
          AppColors.statRedIcon,
        );
      case StatusKind.pending:
        return const _StatusStyle(
          'Pending',
          AppColors.statOrangeBg,
          AppColors.statOrangeIcon,
        );
      case StatusKind.submitted:
        return const _StatusStyle(
          'Submitted',
          AppColors.statBlueBg,
          AppColors.statBlueIcon,
        );
      case StatusKind.approved:
        return const _StatusStyle(
          'Approved',
          AppColors.successGreenBg,
          AppColors.successGreenText,
        );
      case StatusKind.rejected:
        return const _StatusStyle(
          'Rejected',
          AppColors.statRedBg,
          AppColors.statRedIcon,
        );
      case StatusKind.draft:
        return const _StatusStyle(
          'Draft',
          AppColors.chipGrayBg,
          AppColors.textSecondary,
        );
      case StatusKind.reviewed:
        return const _StatusStyle(
          'Reviewed',
          AppColors.statPurpleBg,
          AppColors.statPurpleIcon,
        );
      case StatusKind.needsRevision:
        return const _StatusStyle(
          'Needs Revision',
          AppColors.statRedBg,
          AppColors.statRedIcon,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final showCheck = kind == StatusKind.completed || kind == StatusKind.approved;
    final showLock = kind == StatusKind.locked;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCheck)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.check_circle, size: 12, color: style.text),
            ),
          if (showLock)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.lock, size: 12, color: style.text),
            ),
          Text(
            labelOverride ?? style.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: style.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color bg;
  final Color text;

  const _StatusStyle(this.label, this.bg, this.text);
}
