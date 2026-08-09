import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/admin_profile.dart';
import 'api_client.dart';

class AdminAuthResult {
  final String token;
  final AdminProfile admin;

  const AdminAuthResult({required this.token, required this.admin});
}

/// No registration -- admin accounts are seeded directly in the database
/// (see migration_admin.sql), not self-signed-up like students/instructors.
class AdminAuthService {
  final ApiClient client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'trackit_admin_auth_token';

  AdminAuthService(this.client);

  Future<String?> loadStoredToken() async {
    final token = await _storage.read(key: _tokenKey);
    client.setToken(token);
    return token;
  }

  Future<AdminAuthResult> login({required String email, required String password}) async {
    final response = await client.post(
      '/api/admin-auth/login',
      body: {'email': email, 'password': password},
    );
    final token = response['token'] as String;
    final admin = AdminProfile.fromJson(response['admin'] as Map<String, dynamic>);
    await _storage.write(key: _tokenKey, value: token);
    client.setToken(token);
    return AdminAuthResult(token: token, admin: admin);
  }

  /// Called on app restart (token restored from storage, no login response
  /// in memory) so the sidebar can still show the real admin's identity.
  Future<AdminProfile> getMe() async {
    final response = await client.get('/api/admin-auth/me');
    return AdminProfile.fromJson(response['admin'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await client.post('/api/admin-auth/logout');
    } catch (_) {
      // Best effort -- still clear the local token below even if the
      // network call fails, so the user isn't stuck "logged in" locally.
    }
    await _storage.delete(key: _tokenKey);
    client.setToken(null);
  }
}
