import '../models/attendance.dart';
import '../models/attendance_correction_request.dart';
import '../models/ojt_progress.dart';
import 'api_client.dart';

abstract class AttendanceService {
  Future<TodayAttendance> getToday();

  /// [latitude]/[longitude] are the student's current device position,
  /// checked server-side against the company location saved via Confirm
  /// Company Details (100m radius). Throws [ApiException] if they're too
  /// far, or if the company location hasn't been set yet.
  Future<TodayAttendance> clockIn({
    required double latitude,
    required double longitude,
  });
  Future<TodayAttendance> clockOut({
    required double latitude,
    required double longitude,
  });
  Future<List<AttendanceHistoryEntry>> getHistory();
  Future<OjtProgress> getProgress();

  Future<List<AttendanceCorrectionRequest>> getCorrectionRequests();
  Future<AttendanceCorrectionRequest> submitCorrectionRequest({
    required DateTime workDate,
    required String reason,
    String? attachmentFileName,
  });
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
  Future<TodayAttendance> clockIn({
    required double latitude,
    required double longitude,
  }) async {
    final response = await client.post(
      '/api/attendance/clock-in',
      body: {'latitude': latitude, 'longitude': longitude},
    );
    return _parseAttendance(response['attendance'] as Map<String, dynamic>?);
  }

  @override
  Future<TodayAttendance> clockOut({
    required double latitude,
    required double longitude,
  }) async {
    final response = await client.post(
      '/api/attendance/clock-out',
      body: {'latitude': latitude, 'longitude': longitude},
    );
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
      status: ojtProgressStatusFromDb(json['status'] as String?),
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

  @override
  Future<List<AttendanceCorrectionRequest>> getCorrectionRequests() async {
    final response = await client.get('/api/attendance/corrections');
    final rows = response['requests'] as List<dynamic>;
    return rows
        .map(
          (row) => AttendanceCorrectionRequest.fromJson(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<AttendanceCorrectionRequest> submitCorrectionRequest({
    required DateTime workDate,
    required String reason,
    String? attachmentFileName,
  }) async {
    final response = await client.post(
      '/api/attendance/corrections',
      body: {
        'workDate': _formatDate(workDate),
        'reason': reason,
        if (attachmentFileName != null) 'attachmentFileName': attachmentFileName,
      },
    );
    return AttendanceCorrectionRequest.fromJson(
      response['request'] as Map<String, dynamic>,
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
