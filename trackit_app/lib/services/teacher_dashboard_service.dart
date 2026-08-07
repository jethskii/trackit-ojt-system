import '../models/teacher_dashboard.dart';
import 'api_client.dart';

abstract class TeacherDashboardService {
  Future<TeacherDashboard> getDashboard();
}

class HttpTeacherDashboardService implements TeacherDashboardService {
  final ApiClient client;

  HttpTeacherDashboardService(this.client);

  @override
  Future<TeacherDashboard> getDashboard() async {
    final response = await client.get('/api/teacher/dashboard');
    return TeacherDashboard.fromJson(response['dashboard'] as Map<String, dynamic>);
  }
}
