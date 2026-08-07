import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/teacher_profile_service.dart';
import '../student/profile/settings_screen.dart';
import 'teacher_help_center_screen.dart';
import 'teacher_profile_screen.dart';

/// Mirrors the Student module's ProfileTabNavigator: owns a nested
/// Navigator so pushing into Help Center or Settings keeps the bottom
/// nav visible. Settings is the same generic (role-agnostic) screen the
/// Student module uses; Help Center is teacher-specific content.
class TeacherProfileTabNavigator extends StatefulWidget {
  final ApiClient client;
  final VoidCallback onLoggedOut;

  const TeacherProfileTabNavigator({
    super.key,
    required this.client,
    required this.onLoggedOut,
  });

  @override
  State<TeacherProfileTabNavigator> createState() =>
      _TeacherProfileTabNavigatorState();
}

class _TeacherProfileTabNavigatorState
    extends State<TeacherProfileTabNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final TeacherProfileService _profileService = HttpTeacherProfileService(
    widget.client,
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigatorKey.currentState?.maybePop();
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/help-center':
              page = const TeacherHelpCenterScreen();
              break;
            case '/settings':
              page = const SettingsScreen();
              break;
            case '/':
            default:
              page = TeacherProfileScreen(
                service: _profileService,
                onOpenHelpCenter: () =>
                    _navigatorKey.currentState?.pushNamed('/help-center'),
                onOpenSettings: () =>
                    _navigatorKey.currentState?.pushNamed('/settings'),
                onLoggedOut: widget.onLoggedOut,
              );
          }
          return MaterialPageRoute(builder: (_) => page, settings: settings);
        },
      ),
    );
  }
}
