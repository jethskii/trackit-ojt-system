import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'admin_shell.dart';

/// Unlike TeacherBootstrap/StudentBootstrap, there's no dashboard fetch to
/// await here -- Overview is a placeholder this round, and Class Management
/// loads its own data. So this just hands off to AdminShell directly.
class AdminBootstrap extends StatelessWidget {
  final ApiClient client;
  final VoidCallback onLoggedOut;

  const AdminBootstrap({super.key, required this.client, required this.onLoggedOut});

  @override
  Widget build(BuildContext context) {
    return AdminShell(client: client, onLoggedOut: onLoggedOut);
  }
}
