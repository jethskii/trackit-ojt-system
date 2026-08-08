import '../models/admin_announcement.dart';
import 'api_client.dart';

abstract class AdminAnnouncementsService {
  Future<List<AdminAnnouncement>> getAnnouncements({String? search});

  Future<AdminAnnouncement> createAnnouncement({
    required String title,
    required String content,
    required AdminAnnouncementAudience targetAudience,
    List<int>? imageBytes,
    String? imageFileName,
    String? imageContentType,
  });

  Future<void> deleteAnnouncement(int id);
}

class HttpAdminAnnouncementsService implements AdminAnnouncementsService {
  final ApiClient client;

  HttpAdminAnnouncementsService(this.client);

  @override
  Future<List<AdminAnnouncement>> getAnnouncements({String? search}) async {
    final query = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri(path: '/api/admin/announcements', queryParameters: query);
    final response = await client.get(uri.toString());
    final rows = response['announcements'] as List<dynamic>;
    return rows
        .map((row) => AdminAnnouncement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminAnnouncement> createAnnouncement({
    required String title,
    required String content,
    required AdminAnnouncementAudience targetAudience,
    List<int>? imageBytes,
    String? imageFileName,
    String? imageContentType,
  }) async {
    final response = await client.postMultipart(
      '/api/admin/announcements',
      fieldName: 'image',
      fileBytes: imageBytes,
      fileName: imageFileName,
      contentType: imageContentType ?? 'image/jpeg',
      fields: {
        'title': title,
        'content': content,
        'targetAudience': adminAudienceToDb(targetAudience),
      },
    );
    return AdminAnnouncement.fromJson(response['announcement'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAnnouncement(int id) async {
    await client.delete('/api/admin/announcements/$id');
  }
}
