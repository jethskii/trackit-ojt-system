import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance.dart';
import '../../utils/app_colors.dart';

class AttendanceHistorySection extends StatelessWidget {
  final List<AttendanceHistoryEntry> history;
  final VoidCallback onViewAll;

  const AttendanceHistorySection({
    super.key,
    this.history = const [],
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.receipt_long,
              size: 18,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            InkWell(
              onTap: onViewAll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.primaryMaroon,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No attendance records yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          for (final entry in history) _HistoryRow(entry: entry),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final AttendanceHistoryEntry entry;

  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d, yyyy').format(entry.date);
    final hoursLabel = entry.totalHours == entry.totalHours.roundToDouble()
        ? entry.totalHours.toInt().toString()
        : entry.totalHours.toStringAsFixed(1);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dateLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '$hoursLabel Hrs',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryMaroon,
            ),
          ),
        ],
      ),
    );
  }
}
