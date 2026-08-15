import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class DonutSegment {
  final String label;
  final int value;
  final Color color;

  const DonutSegment({required this.label, required this.value, required this.color});
}

/// A small, dependency-free donut chart (no charting package in this
/// project yet, and two static donuts don't justify adding one) --
/// proportional arcs drawn with CustomPainter, a center total, and a
/// legend with per-segment counts/percentages.
class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final String centerLabel;
  final String centerSubLabel;

  const DonutChart({
    super.key,
    required this.segments,
    required this.centerLabel,
    required this.centerSubLabel,
  });

  int get _total => segments.fold(0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    final total = _total;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _DonutPainter(segments: segments, total: total),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    centerSubLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final segment in segments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: segment.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          segment.label,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${segment.value} (${total > 0 ? (segment.value / total * 100).toStringAsFixed(1) : '0.0'}%)',
                        style: const TextStyle(
                          fontSize: 11.5,
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
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final int total;

  const _DonutPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    if (total == 0) {
      final paint = Paint()
        ..color = AppColors.chipGrayBg
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, 6.28319, false, paint);
      return;
    }

    var startAngle = -1.5707963; // -90deg, start at 12 o'clock
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (segment.value / total) * 6.28319;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.total != total;
}
