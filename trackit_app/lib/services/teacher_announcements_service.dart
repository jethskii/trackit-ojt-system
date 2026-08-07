import 'dart:convert';
import '../models/announcement.dart';
import 'api_client.dart';

abstract class TeacherAnnouncementsService {
  Future<List<Announcement>> getAnnouncements();

  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    required List<int> classIds,
    List<int>? imageBytes,
    String? imageFileName,
    String? imageContentType,
  });

  Future<Announcement> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    required List<int> classIds,
    List<int>? imageBytes,
    String? imageFileName,
    String? imageContentType,
    bool removeImage = false,
  });

  Future<void> deleteAnnouncement(String id);
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
    List<int>? imageBytes,
    String? imageFileName,
    String? imageContentType,
  }) async {
    final response = await client.postMultipart(
      '/api/teacher/announcements',
      fieldName: 'image',
      fileBytes: imageBytes,
      fileName: imageFileName,
      contentType: imageContentType ?? 'image/jpeg',
      fields: {'title': title, 'content': content, 'classIds': jsonEncode(classIds)},
    );
    return Announcement.fromJson(response['announcement'] as Map<String, dynamic>);
  }

  @override
  Future<Announcement> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    required List<int> classIds,
    List<int>? imageBytes,
    String? imageFileName,
    String? imageContentType,
    bool removeImage = false,
  }) async {
    final response = await client.postMultipart(
      '/api/teacher/announcements/$id',
      fieldName: 'image',
      fileBytes: imageBytes,
      fileName: imageFileName,
      contentType: imageContentType ?? 'image/jpeg',
      fields: {
        'title': title,
        'content': content,
        'classIds': jsonEncode(classIds),
        if (removeImage) 'removeImage': 'true',
      },
      method: 'PATCH',
    );
    return Announcement.fromJson(response['announcement'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    await client.delete('/api/teacher/announcements/$id');
  }
}
