import 'package:flutter/material.dart';
import '../../../models/student.dart';
import '../../../services/activity_reports_service.dart';
import '../../../services/api_client.dart';
import '../../../services/custom_requirements_service.dart';
import '../../../services/hte_directory_service.dart';
import '../../../services/ojt_requirements_service.dart';
import '../../../services/student_profile_service.dart';
import 'activity_reports_screen.dart';
import 'additional_requirements_screen.dart';
import 'documents_hub_screen.dart';
import 'hte_directory_screen.dart';
import 'startup_requirements_screen.dart';

/// Owns a nested [Navigator] for the Document tab so pushing into HTE
/// Directory, OJT Requirements, or Activity Reports keeps StudentShell's
/// Scaffold (and its bottom nav) visible, instead of covering the whole
/// screen the way a root-level push would.
class DocumentsTabNavigator extends StatefulWidget {
  final Student student;
  final ApiClient client;

  const DocumentsTabNavigator({
    super.key,
    required this.student,
    required this.client,
  });

  @override
  State<DocumentsTabNavigator> createState() => _DocumentsTabNavigatorState();
}

class _DocumentsTabNavigatorState extends State<DocumentsTabNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final HteDirectoryService _hteService = HttpHteDirectoryService(
    widget.client,
  );
  late final OjtRequirementsService _ojtService = HttpOjtRequirementsService(
    widget.client,
  );
  late final ActivityReportsService _reportsService =
      HttpActivityReportsService(widget.client);
  late final StudentProfileService _profileService = HttpStudentProfileService(
    widget.client,
  );
  late final CustomRequirementsService _customRequirementsService =
      HttpCustomRequirementsService(widget.client);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // The system/hardware back gesture targets the app's root Navigator,
        // not this nested one, so forward it manually when there's a pushed
        // Documents screen to pop back from.
        _navigatorKey.currentState?.maybePop();
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/hte':
              page = HteDirectoryScreen(service: _hteService);
              break;
            case '/ojt-requirements':
              page = StartupRequirementsScreen(
                service: _ojtService,
                profileService: _profileService,
              );
              break;
            case '/activity-reports':
              page = ActivityReportsScreen(
                service: _reportsService,
                student: widget.student,
              );
              break;
            case '/additional-requirements':
              page = AdditionalRequirementsScreen(service: _customRequirementsService);
              break;
            case '/':
            default:
              page = DocumentsHubScreen(
                onOpenHteDirectory: () =>
                    _navigatorKey.currentState?.pushNamed('/hte'),
                onOpenOjtRequirements: () =>
                    _navigatorKey.currentState?.pushNamed('/ojt-requirements'),
                onOpenActivityReports: () =>
                    _navigatorKey.currentState?.pushNamed('/activity-reports'),
                onOpenAdditionalRequirements: () =>
                    _navigatorKey.currentState?.pushNamed('/additional-requirements'),
              );
          }
          return MaterialPageRoute(builder: (_) => page, settings: settings);
        },
      ),
    );
  }
}
