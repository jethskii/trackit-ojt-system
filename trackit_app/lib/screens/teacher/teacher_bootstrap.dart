import 'package:flutter/material.dart';
import '../../models/teacher_dashboard.dart';
import '../../services/api_client.dart';
import '../../services/teacher_dashboard_service.dart';
import '../../utils/app_colors.dart';
import 'teacher_shell.dart';

/// Mirrors StudentBootstrap: fetches what TeacherShell needs right after
/// login so the shell itself can stay simple.
class TeacherBootstrap extends StatefulWidget {
  final ApiClient client;
  final VoidCallback onLoggedOut;

  const TeacherBootstrap({
    super.key,
    required this.client,
    required this.onLoggedOut,
  });

  @override
  State<TeacherBootstrap> createState() => _TeacherBootstrapState();
}

class _TeacherBootstrapState extends State<TeacherBootstrap> {
  late final TeacherDashboardService _dashboardService =
      HttpTeacherDashboardService(widget.client);
  late Future<TeacherDashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = _dashboardService.getDashboard();
  }

  void _retry() {
    setState(() => _future = _dashboardService.getDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TeacherDashboard>(
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
                      'Could not load your dashboard.\n${snapshot.error}',
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

        return TeacherShell(
          dashboardService: _dashboardService,
          initialDashboard: snapshot.data!,
          onLoggedOut: widget.onLoggedOut,
        );
      },
    );
  }
}
