class OjtProgress {
  final int completedHours;
  final int totalHours;
  final int daysAttended;
  final DateTime estimatedCompletion;
  final double averageHoursPerDay;
  final double weeklyAverageHours;
  final bool aheadOfSchedule;

  const OjtProgress({
    required this.completedHours,
    required this.totalHours,
    required this.daysAttended,
    required this.estimatedCompletion,
    required this.averageHoursPerDay,
    required this.weeklyAverageHours,
    required this.aheadOfSchedule,
  });

  double get progressRatio {
    if (totalHours == 0) return 0;
    final ratio = completedHours / totalHours;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  int get progressPercent => (progressRatio * 100).round();
}
