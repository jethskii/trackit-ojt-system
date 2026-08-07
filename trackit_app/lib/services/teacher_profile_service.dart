import '../models/teacher_profile.dart';
import 'api_client.dart';

abstract class TeacherProfileService {
  Future<TeacherProfile> getProfile();

  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<String> changeEmail({
    required String currentPassword,
    required String newEmail,
  });
}

class HttpTeacherProfileService implements TeacherProfileService {
  final ApiClient client;

  HttpTeacherProfileService(this.client);

  @override
  Future<TeacherProfile> getProfile() async {
    final response = await client.get('/api/teacher/profile');
    return TeacherProfile.fromJson(response['profile'] as Map<String, dynamic>);
  }

  @override
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    final response = await client.postMultipart(
      '/api/teacher/profile/avatar',
      fieldName: 'avatar',
      fileBytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
    return response['avatarUrl'] as String;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await client.patch(
      '/api/teacher/profile/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  @override
  Future<String> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final response = await client.patch(
      '/api/teacher/profile/email',
      body: {'currentPassword': currentPassword, 'newEmail': newEmail},
    );
    return response['email'] as String;
  }
}
