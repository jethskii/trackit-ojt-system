import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Which kind of account is currently logged in. Needed because
/// AuthService (student) and InstructorAuthService keep separate tokens
/// under separate storage keys -- this says which one AuthGate should
/// trust on app restart.
enum SessionRole { student, instructor }

class SessionRoleStore {
  static const _key = 'trackit_active_role';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> save(SessionRole role) => _storage.write(key: _key, value: role.name);

  Future<SessionRole?> load() async {
    final value = await _storage.read(key: _key);
    for (final role in SessionRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }

  Future<void> clear() => _storage.delete(key: _key);
}
