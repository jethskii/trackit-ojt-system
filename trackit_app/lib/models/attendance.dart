class TodayAttendance {
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;

  const TodayAttendance({required this.date, this.clockIn, this.clockOut});

  bool get hasClockedIn => clockIn != null;

  bool get hasClockedOut => clockOut != null;

  double get totalHours {
    if (clockIn == null) return 0;
    final end = clockOut ?? DateTime.now();
    final minutes = end.difference(clockIn!).inMinutes;
    return minutes <= 0 ? 0 : minutes / 60;
  }

  TodayAttendance copyWith({DateTime? clockIn, DateTime? clockOut}) {
    return TodayAttendance(
      date: date,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
    );
  }
}

class AttendanceHistoryEntry {
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final double totalHours;

  const AttendanceHistoryEntry({
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.totalHours,
  });
}
