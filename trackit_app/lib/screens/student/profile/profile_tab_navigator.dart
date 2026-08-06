import 'package:flutter/material.dart';
import '../../../services/api_client.dart';
import '../../../services/student_profile_service.dart';
import 'help_center_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Mirrors DocumentsTabNavigator: owns a nested Navigator so pushing into
/// Help Center or Settings keeps StudentShell's bottom nav visible.
class ProfileTabNavigator extends StatefulWidget {
  final ApiClient client;
  final VoidCallback onLoggedOut;

  const ProfileTabNavigator({
    super.key,
    required this.client,
    required this.onLoggedOut,
  });

  @override
  State<ProfileTabNavigator> createState() => _ProfileTabNavigatorState();
}

class _ProfileTabNavigatorState extends State<ProfileTabNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final StudentProfileService _profileService = HttpStudentProfileService(
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
              page = const HelpCenterScreen();
              break;
            case '/settings':
              page = const SettingsScreen();
              break;
            case '/':
            default:
              page = ProfileScreen(
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
