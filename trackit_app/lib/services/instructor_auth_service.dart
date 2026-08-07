import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class InstructorAuthResult {
  final String token;
  final Map<String, dynamic> instructor;

  const InstructorAuthResult({required this.token, required this.instructor});
}

class InstructorAuthService {
  final ApiClient client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'trackit_instructor_auth_token';

  InstructorAuthService(this.client);

  /// Loads a previously stored token (if any) and primes [client] with it.
  Future<String?> loadStoredToken() async {
    final token = await _storage.read(key: _tokenKey);
    client.setToken(token);
    return token;
  }

  Future<InstructorAuthResult> register({
    required String name,
    required String email,
    required String password,
    String? position,
  }) async {
    final response = await client.post(
      '/api/instructor-auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        if (position != null) 'position': position,
      },
    );
    return _persistAuthResponse(response);
  }

  Future<InstructorAuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await client.post(
      '/api/instructor-auth/login',
      body: {'email': email, 'password': password},
    );
    return _persistAuthResponse(response);
  }

  Future<InstructorAuthResult> _persistAuthResponse(Map<String, dynamic> response) async {
    final token = response['token'] as String;
    final instructor = response['instructor'] as Map<String, dynamic>;
    await _storage.write(key: _tokenKey, value: token);
    client.setToken(token);
    return InstructorAuthResult(token: token, instructor: instructor);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    client.setToken(null);
  }
}
