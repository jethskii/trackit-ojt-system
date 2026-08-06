import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance.dart';
import '../../utils/app_colors.dart';

class AttendanceQuickActions extends StatelessWidget {
  final TodayAttendance attendance;
  final DateTime currentTime;
  final VoidCallback onClockAction;
  final VoidCallback onCorrectionRequest;

  const AttendanceQuickActions({
    super.key,
    required this.attendance,
    required this.currentTime,
    required this.onClockAction,
    required this.onCorrectionRequest,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('hh:mm a').format(currentTime);
    final actionLabel = !attendance.hasClockedIn
        ? 'CLOCK IN'
        : (attendance.hasClockedOut ? 'CLOCKED OUT' : 'CLOCK OUT');
    final enabled = !attendance.hasClockedOut;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bolt, size: 18, color: AppColors.primaryMaroon),
            SizedBox(width: 6),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _ClockActionButton(
                  timeLabel: timeLabel,
                  actionLabel: actionLabel,
                  enabled: enabled,
                  onTap: enabled ? onClockAction : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _CorrectionRequestButton(onTap: onCorrectionRequest),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClockActionButton extends StatelessWidget {
  final String timeLabel;
  final String actionLabel;
  final bool enabled;
  final VoidCallback? onTap;

  const _ClockActionButton({
    required this.timeLabel,
    required this.actionLabel,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.primaryMaroon : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: enabled ? AppColors.statRedBg : AppColors.chipGrayBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              timeLabel,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              actionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                decoration: enabled ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorrectionRequestButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CorrectionRequestButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.statBlueBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.edit_document,
              color: AppColors.statBlueIcon,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              'Correction Request Form',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.statBlueIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
