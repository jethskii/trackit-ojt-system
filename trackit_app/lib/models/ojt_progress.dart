/// How the student's actual attendance pace compares to the expected pace
/// for their OJT start date, computed server-side. [completed] takes
/// priority over the others once completedHours reaches totalHours.
enum OjtProgressStatus { onTrack, behind, needsAttention, aheadOfSchedule, completed }

OjtProgressStatus ojtProgressStatusFromDb(String? value) {
  switch (value) {
    case 'behind':
      return OjtProgressStatus.behind;
    case 'needsAttention':
      return OjtProgressStatus.needsAttention;
    case 'aheadOfSchedule':
      return OjtProgressStatus.aheadOfSchedule;
    case 'completed':
      return OjtProgressStatus.completed;
    default:
      return OjtProgressStatus.onTrack;
  }
}

class OjtProgress {
  final int completedHours;
  final int totalHours;
  final int daysAttended;
  final DateTime estimatedCompletion;
  final double averageHoursPerDay;
  final double weeklyAverageHours;
  final OjtProgressStatus status;

  const OjtProgress({
    required this.completedHours,
    required this.totalHours,
    required this.daysAttended,
    required this.estimatedCompletion,
    required this.averageHoursPerDay,
    required this.weeklyAverageHours,
    required this.status,
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
