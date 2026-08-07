import '../models/student_announcement.dart';
import 'api_client.dart';

abstract class StudentAnnouncementsService {
  Future<List<StudentAnnouncement>> getAnnouncements();
}

class HttpStudentAnnouncementsService implements StudentAnnouncementsService {
  final ApiClient client;

  HttpStudentAnnouncementsService(this.client);

  @override
  Future<List<StudentAnnouncement>> getAnnouncements() async {
    final response = await client.get('/api/announcements');
    final rows = response['announcements'] as List<dynamic>;
    return rows
        .map((row) => StudentAnnouncement.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
