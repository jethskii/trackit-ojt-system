import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../student/student_bootstrap.dart';
import 'login_screen.dart';

/// Root of the app below MaterialApp: decides between the login flow and
/// the authenticated Student Module based on whether a stored token
/// exists, and owns the single ApiClient/AuthService instance shared by
/// everything underneath.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ApiClient _client = ApiClient();
  late final AuthService _authService = AuthService(_client);
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await _authService.loadStoredToken();
    if (!mounted) return;
    setState(() {
      _loggedIn = token != null;
      _checking = false;
    });
  }

  void _handleLoggedIn() {
    setState(() => _loggedIn = true);
  }

  Future<void> _handleLoggedOut() async {
    await _authService.logout();
    if (mounted) setState(() => _loggedIn = false);
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

    if (!_loggedIn) {
      return LoginScreen(authService: _authService, onLoggedIn: _handleLoggedIn);
    }

    return StudentBootstrap(client: _client, onLoggedOut: _handleLoggedOut);
  }
}
