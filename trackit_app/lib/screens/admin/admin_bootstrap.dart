import 'package:flutter/material.dart';
import '../../services/admin_auth_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import 'admin_shell.dart';

/// Mirrors TeacherBootstrap: fetches the real logged-in admin's identity
/// (name/email) so the sidebar profile card isn't stuck showing a generic
/// placeholder on a fresh app launch where the login response isn't in
/// memory anymore.
class AdminBootstrap extends StatefulWidget {
  final ApiClient client;
  final AdminAuthService adminAuthService;
  final VoidCallback onLoggedOut;

  const AdminBootstrap({
    super.key,
    required this.client,
    required this.adminAuthService,
    required this.onLoggedOut,
  });

  @override
  State<AdminBootstrap> createState() => _AdminBootstrapState();
}

class _AdminBootstrapState extends State<AdminBootstrap> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.adminAuthService.getMe();
  }

  void _retry() {
    setState(() => _future = widget.adminAuthService.getMe());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryMaroon),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: AppColors.statRedIcon,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load your admin session.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: widget.onLoggedOut,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryMaroon,
                            side: const BorderSide(
                              color: AppColors.primaryMaroon,
                            ),
                          ),
                          child: const Text('Back to Login'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _retry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryMaroon,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return AdminShell(
          client: widget.client,
          adminName: snapshot.data!['name'] as String,
          adminEmail: snapshot.data!['email'] as String,
          onLoggedOut: widget.onLoggedOut,
        );
      },
    );
  }
}
