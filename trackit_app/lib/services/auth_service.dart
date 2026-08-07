import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/class_lookup_result.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final Map<String, dynamic> student;

  const AuthResult({required this.token, required this.student});
}

class AuthService {
  final ApiClient client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'trackit_auth_token';

  AuthService(this.client);

  /// Loads a previously stored token (if any) and primes [client] with it.
  /// Returns the token, or null if the user has never logged in / logged out.
  Future<String?> loadStoredToken() async {
    final token = await _storage.read(key: _tokenKey);
    client.setToken(token);
    return token;
  }

  /// Resolves an activation code to the class it joins, so the
  /// registration form can show "You're joining: BSIT - 3F under Ma'am
  /// Althea" before the student submits. Throws [ApiException] for an
  /// invalid code.
  Future<ClassLookupResult> lookupClass(String code) async {
    final response = await client.get(
      '/api/classes/lookup?code=${Uri.encodeQueryComponent(code)}',
    );
    return ClassLookupResult.fromJson(response['class'] as Map<String, dynamic>);
  }

  /// [activationCode] joins a class (see [lookupClass]) -- it's what sets
  /// course, section, and adviser together, rather than the student
  /// free-typing course/section or picking an adviser separately.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String activationCode,
    String? studentNumber,
    String? yearLevel,
  }) async {
    final response = await client.post(
      '/api/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'activationCode': activationCode,
        if (studentNumber != null) 'studentNumber': studentNumber,
        if (yearLevel != null) 'yearLevel': yearLevel,
      },
    );
    return _persistAuthResponse(response);
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final response = await client.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    return _persistAuthResponse(response);
  }

  Future<AuthResult> _persistAuthResponse(Map<String, dynamic> response) async {
    final token = response['token'] as String;
    final student = response['student'] as Map<String, dynamic>;
    await _storage.write(key: _tokenKey, value: token);
    client.setToken(token);
    return AuthResult(token: token, student: student);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    client.setToken(null);
  }
}
