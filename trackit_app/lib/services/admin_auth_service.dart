import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AdminAuthResult {
  final String token;
  final Map<String, dynamic> admin;

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
    final admin = response['admin'] as Map<String, dynamic>;
    await _storage.write(key: _tokenKey, value: token);
    client.setToken(token);
    return AdminAuthResult(token: token, admin: admin);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    client.setToken(null);
  }
}
