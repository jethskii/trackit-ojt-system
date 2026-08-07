import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/instructor_auth_service.dart';
import '../../services/session_role.dart';
import '../../utils/app_colors.dart';
import '../student/student_bootstrap.dart';
import '../teacher/teacher_bootstrap.dart';
import 'login_screen.dart';

/// Root of the app below MaterialApp: decides between the login flow and
/// the authenticated Student or Teacher module based on the stored
/// session role, and owns the single ApiClient/auth service instances
/// shared by everything underneath.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ApiClient _client = ApiClient();
  late final AuthService _authService = AuthService(_client);
  late final InstructorAuthService _instructorAuthService =
      InstructorAuthService(_client);
  final SessionRoleStore _roleStore = SessionRoleStore();
  bool _checking = true;
  SessionRole? _activeRole;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final role = await _roleStore.load();
    SessionRole? resolvedRole;
    if (role == SessionRole.student) {
      final token = await _authService.loadStoredToken();
      if (token != null) resolvedRole = SessionRole.student;
    } else if (role == SessionRole.instructor) {
      final token = await _instructorAuthService.loadStoredToken();
      if (token != null) resolvedRole = SessionRole.instructor;
    }
    if (!mounted) return;
    setState(() {
      _activeRole = resolvedRole;
      _checking = false;
    });
  }

  Future<void> _handleLoggedIn(SessionRole role) async {
    await _roleStore.save(role);
    if (!mounted) return;
    setState(() => _activeRole = role);
  }

  Future<void> _handleLoggedOut() async {
    await _authService.logout();
    await _instructorAuthService.logout();
    await _roleStore.clear();
    if (mounted) setState(() => _activeRole = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryMaroon),
        ),
      );
    }

    switch (_activeRole) {
      case SessionRole.student:
        return StudentBootstrap(client: _client, onLoggedOut: _handleLoggedOut);
      case SessionRole.instructor:
        return TeacherBootstrap(client: _client, onLoggedOut: _handleLoggedOut);
      case null:
        return LoginScreen(
          authService: _authService,
          instructorAuthService: _instructorAuthService,
          onLoggedIn: _handleLoggedIn,
        );
    }
  }
}
