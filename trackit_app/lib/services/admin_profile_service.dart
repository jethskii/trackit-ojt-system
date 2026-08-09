import '../models/admin_profile.dart';
import '../models/admin_session.dart';
import 'api_client.dart';

class AdminProfileService {
  final ApiClient client;

  AdminProfileService(this.client);

  /// Combined single-save edit -- name and/or email as plain fields, plus
  /// an optional new avatar file, all in one request (matches the spec's
  /// single Edit Profile form rather than separate save actions).
  Future<AdminProfile> updateProfile({
    String? name,
    String? email,
    List<int>? avatarBytes,
    String? avatarFileName,
    String avatarContentType = 'image/jpeg',
  }) async {
    final response = await client.postMultipart(
      '/api/admin/profile',
      fieldName: 'avatar',
      fileBytes: avatarBytes,
      fileName: avatarFileName,
      contentType: avatarContentType,
      method: 'PATCH',
      fields: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      },
    );
    return AdminProfile.fromJson(response['admin'] as Map<String, dynamic>);
  }

  Future<List<AdminSession>> getSessions() async {
    final response = await client.get('/api/admin/profile/sessions');
    final sessions = response['sessions'] as List<dynamic>;
    return sessions
        .map((s) => AdminSession.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<void> terminateSession(int sessionId) async {
    await client.delete('/api/admin/profile/sessions/$sessionId');
  }

  /// Step 1 of change-password: sends a one-time code to the admin's own
  /// registered email. Returns the masked email so the UI can show
  /// "Code sent to j***@gmail.com" without ever displaying the code
  /// itself or the full address.
  Future<String> requestPasswordOtp() async {
    final response = await client.post('/api/admin/profile/change-password/request-otp');
    return response['maskedEmail'] as String;
  }

  /// Step 2: verify the code. Returns a short-lived reset token that
  /// [confirmPasswordChange] must present -- so the final step can't be
  /// reached without having actually verified the OTP.
  Future<String> verifyPasswordOtp(String code) async {
    final response = await client.post(
      '/api/admin/profile/change-password/verify-otp',
      body: {'code': code},
    );
    return response['resetToken'] as String;
  }

  Future<void> confirmPasswordChange({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await client.post(
      '/api/admin/profile/change-password/confirm',
      body: {
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }
}
