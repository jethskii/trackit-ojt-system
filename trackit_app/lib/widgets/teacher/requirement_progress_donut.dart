import 'package:flutter/material.dart';
import '../../models/teacher_requirement_student_summary.dart';
import '../../utils/app_colors.dart';

/// The Progress Summary donut chart -- Completed / Needs Review / Pending,
/// drawn with CustomPainter (no charting package dependency for a single
/// 3-segment ring).
class RequirementProgressDonut extends StatelessWidget {
  final RequirementProgressSummary summary;

  const RequirementProgressDonut({super.key, required this.summary});

  static const _completedColor = AppColors.successGreenText;
  static const _needsReviewColor = AppColors.statBlueIcon;
  static const _pendingColor = AppColors.statOrangeIcon;

  @override
  Widget build(BuildContext context) {
    final total = summary.total;
    final percent = total > 0 ? (summary.completed / total * 100).round() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Summary',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(96, 96),
                      painter: _DonutPainter(
                        completed: summary.completed,
                        needsReview: summary.needsReview,
                        pending: summary.pending,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow(
                      color: _completedColor,
                      label: 'Completed',
                      count: summary.completed,
                    ),
                    const SizedBox(height: 8),
                    _LegendRow(
                      color: _needsReviewColor,
                      label: 'Needs Review',
                      count: summary.needsReview,
                    ),
                    const SizedBox(height: 8),
                    _LegendRow(
                      color: _pendingColor,
                      label: 'Pending',
                      count: summary.pending,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendRow({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int completed;
  final int needsReview;
  final int pending;

  const _DonutPainter({
    required this.completed,
    required this.needsReview,
    required this.pending,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = completed + needsReview + pending;
    final rect = Offset.zero & size;
    const strokeWidth = 14.0;
    final paintBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (total == 0) {
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        0,
        6.28319,
        false,
        paintBase..color = AppColors.chipGrayBg,
      );
      return;
    }

    final segments = [
      (completed, RequirementProgressDonut._completedColor),
      (needsReview, RequirementProgressDonut._needsReviewColor),
      (pending, RequirementProgressDonut._pendingColor),
    ];

    double startAngle = -1.5708; // -90deg, start at the top
    for (final (value, color) in segments) {
      if (value == 0) continue;
      final sweep = (value / total) * 6.28319;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paintBase..color = color,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.completed != completed ||
        oldDelegate.needsReview != needsReview ||
        oldDelegate.pending != pending;
  }
}
