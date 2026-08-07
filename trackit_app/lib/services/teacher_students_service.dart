import '../models/teacher_student_detail.dart';
import '../models/teacher_student_summary.dart';
import 'api_client.dart';

abstract class TeacherStudentsService {
  Future<List<TeacherStudentSummary>> getStudents();
  Future<TeacherStudentDetail> getStudentDetail(int studentId);
}

class HttpTeacherStudentsService implements TeacherStudentsService {
  final ApiClient client;

  HttpTeacherStudentsService(this.client);

  @override
  Future<List<TeacherStudentSummary>> getStudents() async {
    final response = await client.get('/api/teacher/students');
    final rows = response['students'] as List<dynamic>;
    return rows
        .map(
          (row) => TeacherStudentSummary.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<TeacherStudentDetail> getStudentDetail(int studentId) async {
    final response = await client.get('/api/teacher/students/$studentId');
    return TeacherStudentDetail.fromJson(response['student'] as Map<String, dynamic>);
  }
}
