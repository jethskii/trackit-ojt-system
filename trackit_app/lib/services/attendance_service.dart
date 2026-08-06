import '../models/attendance.dart';
import '../models/ojt_progress.dart';
import 'api_client.dart';

abstract class AttendanceService {
  Future<TodayAttendance> getToday();
  Future<TodayAttendance> clockIn();
  Future<TodayAttendance> clockOut();
  Future<List<AttendanceHistoryEntry>> getHistory();
  Future<OjtProgress> getProgress();
}

class HttpAttendanceService implements AttendanceService {
  final ApiClient client;

  HttpAttendanceService(this.client);

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  TodayAttendance _parseAttendance(Map<String, dynamic>? json) {
    if (json == null) {
      return TodayAttendance(date: _today());
    }
    return TodayAttendance(
      date: DateTime.parse(json['work_date'] as String),
      clockIn: json['clock_in'] != null ? DateTime.parse(json['clock_in'] as String) : null,
      clockOut: json['clock_out'] != null ? DateTime.parse(json['clock_out'] as String) : null,
    );
  }

  @override
  Future<TodayAttendance> getToday() async {
    final response = await client.get('/api/attendance/today');
    return _parseAttendance(response['attendance'] as Map<String, dynamic>?);
  }

  @override
  Future<TodayAttendance> clockIn() async {
    final response = await client.post('/api/attendance/clock-in');
    return _parseAttendance(response['attendance'] as Map<String, dynamic>?);
  }

  @override
  Future<TodayAttendance> clockOut() async {
    final response = await client.post('/api/attendance/clock-out');
    return _parseAttendance(response['attendance'] as Map<String, dynamic>?);
  }

  @override
  Future<List<AttendanceHistoryEntry>> getHistory() async {
    final response = await client.get('/api/attendance/history');
    final rows = response['history'] as List<dynamic>;
    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      final clockIn = DateTime.parse(map['clock_in'] as String);
      final clockOut = DateTime.parse(map['clock_out'] as String);
      return AttendanceHistoryEntry(
        date: DateTime.parse(map['work_date'] as String),
        clockIn: clockIn,
        clockOut: clockOut,
        totalHours: clockOut.difference(clockIn).inMinutes / 60,
      );
    }).toList();
  }

  @override
  Future<OjtProgress> getProgress() async {
    final response = await client.get('/api/attendance/progress');
    final json = response['progress'] as Map<String, dynamic>;
    return OjtProgress(
      completedHours: (json['completedHours'] as num).round(),
      totalHours: (json['totalHours'] as num).round(),
      daysAttended: (json['daysAttended'] as num).round(),
      estimatedCompletion: _estimateCompletion(json),
      averageHoursPerDay: (json['averageHoursPerDay'] as num).toDouble(),
      weeklyAverageHours: (json['weeklyAverageHours'] as num).toDouble(),
      aheadOfSchedule: json['aheadOfSchedule'] as bool,
    );
  }

  /// The server doesn't compute a projected completion date yet (needs an
  /// OJT start-date field) -- estimate from the current pace so the UI has
  /// something meaningful instead of nothing.
  DateTime _estimateCompletion(Map<String, dynamic> json) {
    final completed = (json['completedHours'] as num).toDouble();
    final total = (json['totalHours'] as num).toDouble();
    final weeklyAverage = (json['weeklyAverageHours'] as num).toDouble();
    final remainingHours = total - completed;
    if (weeklyAverage <= 0 || remainingHours <= 0) {
      return DateTime.now();
    }
    final remainingWeeks = remainingHours / weeklyAverage;
    return DateTime.now().add(Duration(days: (remainingWeeks * 7).round()));
  }
}
