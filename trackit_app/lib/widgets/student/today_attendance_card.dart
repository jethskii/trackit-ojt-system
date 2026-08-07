import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance.dart';
import '../../utils/app_colors.dart';

class TodayAttendanceCard extends StatelessWidget {
  final TodayAttendance attendance;

  const TodayAttendanceCard({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMMM d, yyyy').format(attendance.date);
    final clockInLabel = attendance.hasClockedIn
        ? DateFormat('hh:mm a').format(attendance.clockIn!)
        : '--:--';
    final clockOutLabel = attendance.hasClockedOut
        ? DateFormat('hh:mm a').format(attendance.clockOut!)
        : '--:--';
    final totalHoursLabel = '${_formatHours(attendance.totalHours)} Hrs';
    final overallStatus = !attendance.hasClockedIn
        ? _OverallStatus.unavailable
        : (attendance.hasClockedOut
              ? _OverallStatus.completed
              : _OverallStatus.ongoing);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_note,
                size: 18,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  "Today's Attendance",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AttemptsRemainingLabel(remaining: attendance.attemptsRemaining),
              _OverallStatusPill(status: overallStatus),
            ],
          ),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _AttendanceColumn(
                    dotColor: AppColors.successGreenText,
                    label: 'CLOCK IN',
                    value: clockInLabel,
                    valueColor: attendance.hasClockedIn
                        ? AppColors.successGreenText
                        : AppColors.textSecondary,
                    pillLabel: attendance.hasClockedIn
                        ? 'Completed'
                        : 'Pending',
                    pillBg: attendance.hasClockedIn
                        ? AppColors.successGreenBg
                        : AppColors.chipGrayBg,
                    pillText: attendance.hasClockedIn
                        ? AppColors.successGreenText
                        : AppColors.textSecondary,
                  ),
                ),
                const VerticalDivider(width: 16),
                Expanded(
                  child: _AttendanceColumn(
                    dotColor: AppColors.primaryMaroon,
                    label: 'CLOCK OUT',
                    value: clockOutLabel,
                    valueColor: attendance.hasClockedOut
                        ? AppColors.primaryMaroon
                        : AppColors.textPrimary,
                    pillLabel: attendance.hasClockedOut
                        ? 'Completed'
                        : 'Unavailable',
                    pillBg: attendance.hasClockedOut
                        ? AppColors.successGreenBg
                        : AppColors.chipGrayBg,
                    pillText: attendance.hasClockedOut
                        ? AppColors.successGreenText
                        : AppColors.textSecondary,
                  ),
                ),
                const VerticalDivider(width: 16),
                Expanded(
                  child: _AttendanceColumn(
                    dotColor: AppColors.statBlueIcon,
                    label: 'TOTAL HOURS',
                    value: totalHoursLabel,
                    valueColor: AppColors.statBlueIcon,
                    pillLabel: attendance.hasClockedOut
                        ? 'Completed'
                        : 'On Going',
                    pillBg: attendance.hasClockedOut
                        ? AppColors.successGreenBg
                        : AppColors.statBlueBg,
                    pillText: attendance.hasClockedOut
                        ? AppColors.successGreenText
                        : AppColors.statBlueIcon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    return hours == hours.roundToDouble()
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
  }
}

class _AttendanceColumn extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;
  final Color valueColor;
  final String pillLabel;
  final Color pillBg;
  final Color pillText;

  const _AttendanceColumn({
    required this.dotColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.pillLabel,
    required this.pillBg,
    required this.pillText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            pillLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: pillText,
            ),
          ),
        ),
      ],
    );
  }
}

class _AttemptsRemainingLabel extends StatelessWidget {
  final int remaining;

  const _AttemptsRemainingLabel({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final color = remaining == 0
        ? AppColors.statRedIcon
        : (remaining == 1 ? AppColors.statOrangeIcon : AppColors.textSecondary);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (remaining == 0)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.lock_outline, size: 12, color: AppColors.statRedIcon),
          ),
        Text(
          'Attempts Remaining: $remaining/${TodayAttendance.maxAttempts}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

enum _OverallStatus { completed, ongoing, unavailable }

class _OverallStatusPill extends StatelessWidget {
  final _OverallStatus status;

  const _OverallStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, text) = switch (status) {
      _OverallStatus.completed => (
        'Completed',
        AppColors.successGreenBg,
        AppColors.successGreenText,
      ),
      _OverallStatus.ongoing => (
        'Ongoing',
        AppColors.statBlueBg,
        AppColors.statBlueIcon,
      ),
      _OverallStatus.unavailable => (
        'Unavailable',
        AppColors.chipGrayBg,
        AppColors.textSecondary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }
}
