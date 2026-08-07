import '../models/announcement.dart';
import 'api_client.dart';

abstract class TeacherAnnouncementsService {
  Future<List<Announcement>> getAnnouncements();

  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    required List<int> classIds,
  });
}

class HttpTeacherAnnouncementsService implements TeacherAnnouncementsService {
  final ApiClient client;

  HttpTeacherAnnouncementsService(this.client);

  @override
  Future<List<Announcement>> getAnnouncements() async {
    final response = await client.get('/api/teacher/announcements');
    final rows = response['announcements'] as List<dynamic>;
    return rows
        .map((row) => Announcement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    required List<int> classIds,
  }) async {
    final response = await client.post(
      '/api/teacher/announcements',
      body: {'title': title, 'content': content, 'classIds': classIds},
    );
    return Announcement.fromJson(response['announcement'] as Map<String, dynamic>);
  }
}
