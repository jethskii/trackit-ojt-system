import '../models/teacher_weekly_report_row.dart';
import 'api_client.dart';

class TeacherStudentWeeklyReports {
  final int studentId;
  final String studentName;
  final String? avatarUrl;
  final List<TeacherWeeklyReportRow> reports;

  const TeacherStudentWeeklyReports({
    required this.studentId,
    required this.studentName,
    this.avatarUrl,
    required this.reports,
  });
}

abstract class TeacherWeeklyReportsService {
  Future<List<TeacherWeeklyReportStudentSummary>> getStudents();

  Future<TeacherStudentWeeklyReports> getStudentReports(int studentId);
}

class HttpTeacherWeeklyReportsService implements TeacherWeeklyReportsService {
  final ApiClient client;

  HttpTeacherWeeklyReportsService(this.client);

  @override
  Future<List<TeacherWeeklyReportStudentSummary>> getStudents() async {
    final response = await client.get('/api/teacher/weekly-reports/students');
    final rows = response['students'] as List<dynamic>;
    return rows
        .map((row) => TeacherWeeklyReportStudentSummary.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TeacherStudentWeeklyReports> getStudentReports(int studentId) async {
    final response = await client.get('/api/teacher/weekly-reports/students/$studentId');
    final student = response['student'] as Map<String, dynamic>;
    final rows = response['reports'] as List<dynamic>;
    return TeacherStudentWeeklyReports(
      studentId: student['id'] as int,
      studentName: student['name'] as String,
      avatarUrl: student['avatarUrl'] as String?,
      reports: rows
          .map((row) => TeacherWeeklyReportRow.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }
}
