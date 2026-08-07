class TodayAttendance {
  /// Mirrors the server's MAX_DAILY_ATTEMPTS (attendance.js) -- kept here
  /// only as a UI fallback/default; the actual limit is always enforced
  /// server-side, this is never what's checked before allowing an action.
  static const int maxAttempts = 2;

  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final int attemptsUsed;

  const TodayAttendance({
    required this.date,
    this.clockIn,
    this.clockOut,
    this.attemptsUsed = 0,
  });

  bool get hasClockedIn => clockIn != null;

  bool get hasClockedOut => clockOut != null;

  /// A session is currently open (clocked in, not yet clocked out).
  bool get isClockedInSession => clockIn != null && clockOut == null;

  int get attemptsRemaining => (maxAttempts - attemptsUsed).clamp(0, maxAttempts);

  /// Clock In is only blocked while a session is already open, or once
  /// attempts are exhausted -- otherwise (including right after a
  /// completed cycle) it starts a fresh cycle.
  bool get canClockIn => !isClockedInSession && attemptsRemaining > 0;

  /// Clock Out never spends an attempt -- it's available any time a
  /// session is open, regardless of attempts remaining.
  bool get canClockOut => isClockedInSession;

  double get totalHours {
    if (clockIn == null) return 0;
    final end = clockOut ?? DateTime.now();
    final minutes = end.difference(clockIn!).inMinutes;
    return minutes <= 0 ? 0 : minutes / 60;
  }

  TodayAttendance copyWith({
    DateTime? clockIn,
    DateTime? clockOut,
    int? attemptsUsed,
  }) {
    return TodayAttendance(
      date: date,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
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
