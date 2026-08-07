import '../models/teacher_attendance_record.dart';
import '../models/teacher_correction_request.dart';
import 'api_client.dart';

abstract class TeacherAttendanceService {
  Future<List<TeacherAttendanceRecord>> getRecords({String? search, DateTime? workDate});

  Future<List<TeacherCorrectionRequest>> getCorrections({String? status});

  Future<void> reviewCorrection({
    required int correctionId,
    required bool approve,
    String? reviewerNote,
  });
}

class HttpTeacherAttendanceService implements TeacherAttendanceService {
  final ApiClient client;

  HttpTeacherAttendanceService(this.client);

  @override
  Future<List<TeacherAttendanceRecord>> getRecords({String? search, DateTime? workDate}) async {
    final query = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (workDate != null) 'workDate': workDate.toIso8601String().substring(0, 10),
    };
    final uri = Uri(path: '/api/teacher/attendance/records', queryParameters: query);
    final response = await client.get(uri.toString());
    final rows = response['records'] as List<dynamic>;
    return rows
        .map((row) => TeacherAttendanceRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TeacherCorrectionRequest>> getCorrections({String? status}) async {
    final query = <String, String>{if (status != null) 'status': status};
    final uri = Uri(path: '/api/teacher/attendance/corrections', queryParameters: query);
    final response = await client.get(uri.toString());
    final rows = response['requests'] as List<dynamic>;
    return rows
        .map((row) => TeacherCorrectionRequest.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> reviewCorrection({
    required int correctionId,
    required bool approve,
    String? reviewerNote,
  }) async {
    await client.patch(
      '/api/teacher/attendance/corrections/$correctionId',
      body: {'decision': approve ? 'approved' : 'rejected', 'reviewerNote': reviewerNote},
    );
  }
}
