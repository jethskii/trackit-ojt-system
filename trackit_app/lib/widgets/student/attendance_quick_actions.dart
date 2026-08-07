import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance.dart';
import '../../utils/app_colors.dart';

class AttendanceQuickActions extends StatelessWidget {
  final TodayAttendance attendance;
  final DateTime currentTime;
  final VoidCallback? onClockAction;
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
    // Clocked out and out of attempts to start a new cycle -- truly
    // nothing left to do until tomorrow, distinct from "clocked out but
    // could clock in again" or "mid-session, clock out any time."
    final isLocked = attendance.attemptsRemaining == 0 && !attendance.isClockedInSession;
    final actionLabel = attendance.canClockOut
        ? 'CLOCK OUT'
        : (attendance.canClockIn ? 'CLOCK IN' : 'LOCKED');
    final enabled = (attendance.canClockIn || attendance.canClockOut) && onClockAction != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, size: 18, color: AppColors.primaryMaroon),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _AttemptsPill(remaining: attendance.attemptsRemaining),
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
        if (isLocked) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipGrayBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No attempts remaining',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You have used all of your clocking attempts for today. '
                        'Your attendance actions are now locked until the next day.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AttemptsPill extends StatelessWidget {
  final int remaining;

  const _AttemptsPill({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final isLow = remaining <= 1;
    final bg = isLow ? AppColors.statOrangeBg : AppColors.chipGrayBg;
    final text = isLow ? AppColors.statOrangeIcon : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        'Attempts: $remaining/${TodayAttendance.maxAttempts}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
      ),
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
            Icon(enabled ? Icons.access_time : Icons.lock_outline, color: color, size: 22),
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
