import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ojt_progress.dart';
import '../../utils/app_colors.dart';
import 'ojt_stat_tile.dart';

class OjtProgressCard extends StatelessWidget {
  final OjtProgress progress;

  const OjtProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final estCompletion = DateFormat('MMM d, yyyy').format(
      progress.estimatedCompletion,
    );

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
          const Text(
            'OJT Hours Progress',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${progress.completedHours}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryMaroon,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' / ${progress.totalHours} Hours',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (progress.aheadOfSchedule) _AheadOfSchedulePill(),
            ],
          ),
          const SizedBox(height: 14),
          _ProgressBar(ratio: progress.progressRatio),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OjtStatTile(
                  icon: Icons.hourglass_bottom,
                  iconColor: AppColors.statOrangeIcon,
                  backgroundColor: AppColors.statOrangeBg,
                  value: '${progress.daysAttended} Days',
                  label: 'Days Attended',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OjtStatTile(
                  icon: Icons.calendar_today,
                  iconColor: AppColors.statPurpleIcon,
                  backgroundColor: AppColors.statPurpleBg,
                  value: estCompletion,
                  label: 'Est. Completion',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OjtStatTile(
                  icon: Icons.access_time,
                  iconColor: AppColors.statRedIcon,
                  backgroundColor: AppColors.statRedBg,
                  value: '${_formatHours(progress.averageHoursPerDay)} Hours',
                  label: 'Average Hours / Day',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OjtStatTile(
                  icon: Icons.bar_chart,
                  iconColor: AppColors.statBlueIcon,
                  backgroundColor: AppColors.statBlueBg,
                  value: '${_formatHours(progress.weeklyAverageHours)} Hours',
                  label: 'Weekly Average',
                ),
              ),
            ],
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

class _AheadOfSchedulePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successGreenBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            size: 14,
            color: AppColors.successGreenText,
          ),
          SizedBox(width: 4),
          Text(
            'Ahead of Schedule',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.successGreenText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double ratio;

  const _ProgressBar({required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 20,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryMaroon),
          ),
        ),
        Text(
          '${(ratio * 100).round()}%',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
