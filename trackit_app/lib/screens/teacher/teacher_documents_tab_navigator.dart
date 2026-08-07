import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/teacher_attendance_service.dart';
import '../../services/teacher_classes_service.dart';
import '../../services/teacher_requirements_service.dart';
import '../../services/teacher_weekly_reports_service.dart';
import 'create_custom_requirement_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_custom_requirements_screen.dart';
import 'teacher_documents_hub_screen.dart';
import 'teacher_official_requirements_screen.dart';
import 'teacher_requirement_review_screen.dart';
import 'teacher_weekly_report_detail_screen.dart';
import 'teacher_weekly_reports_screen.dart';

/// Owns a nested Navigator for the Document (OJT Management) tab, the
/// same pattern as the Students and Notification tabs, so pushing into
/// any of these screens keeps TeacherShell's bottom nav visible.
class TeacherDocumentsTabNavigator extends StatefulWidget {
  final ApiClient client;
  final TeacherClassesService classesService;

  /// Owned by TeacherShell so Home Dashboard's "Needs your Attention" taps
  /// can deep-link straight into a screen here (e.g. Official Requirements
  /// filtered to Needs Review, or Attendance Requests) instead of just
  /// switching tabs to this navigator's root.
  final GlobalKey<NavigatorState>? navigatorKey;

  const TeacherDocumentsTabNavigator({
    super.key,
    required this.client,
    required this.classesService,
    this.navigatorKey,
  });

  @override
  State<TeacherDocumentsTabNavigator> createState() =>
      _TeacherDocumentsTabNavigatorState();
}

class _TeacherDocumentsTabNavigatorState
    extends State<TeacherDocumentsTabNavigator> {
  late final GlobalKey<NavigatorState> _navigatorKey =
      widget.navigatorKey ?? GlobalKey<NavigatorState>();
  late final TeacherRequirementsService _requirementsService =
      HttpTeacherRequirementsService(widget.client);
  late final TeacherAttendanceService _attendanceService =
      HttpTeacherAttendanceService(widget.client);
  late final TeacherWeeklyReportsService _weeklyReportsService =
      HttpTeacherWeeklyReportsService(widget.client);

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
            case '/attendance-records':
              page = TeacherAttendanceScreen(service: _attendanceService);
              break;
            case '/attendance-requests':
              page = TeacherAttendanceScreen(
                service: _attendanceService,
                startOnRequests: true,
              );
              break;
            case '/official-requirements':
              page = TeacherOfficialRequirementsScreen(
                service: _requirementsService,
                initialStatusFilter: settings.arguments as String?,
                onOpenStudent: (studentId) => _navigatorKey.currentState
                    ?.pushNamed('/official-requirements/$studentId'),
              );
              break;
            case '/weekly-reports':
              page = TeacherWeeklyReportsScreen(
                service: _weeklyReportsService,
                onOpenStudent: (studentId) => _navigatorKey.currentState
                    ?.pushNamed('/weekly-reports/$studentId'),
              );
              break;
            case '/additional-requirements':
              page = TeacherCustomRequirementsScreen(
                service: _requirementsService,
                onAddNew: () => _navigatorKey.currentState!
                    .pushNamed<String>('/add-requirement'),
              );
              break;
            case '/add-requirement':
              page = CreateCustomRequirementScreen(
                requirementsService: _requirementsService,
                classesService: widget.classesService,
              );
              break;
            case '/':
            default:
              final path = settings.name ?? '/';
              if (path.startsWith('/official-requirements/')) {
                final studentId = int.parse(path.split('/').last);
                page = TeacherRequirementReviewScreen(
                  studentId: studentId,
                  service: _requirementsService,
                );
              } else if (path.startsWith('/weekly-reports/')) {
                final studentId = int.parse(path.split('/').last);
                page = TeacherWeeklyReportDetailScreen(
                  studentId: studentId,
                  service: _weeklyReportsService,
                );
              } else {
                page = TeacherDocumentsHubScreen(
                  onOpenAttendanceRecords: () =>
                      _navigatorKey.currentState?.pushNamed('/attendance-records'),
                  onOpenAttendanceRequests: () =>
                      _navigatorKey.currentState?.pushNamed('/attendance-requests'),
                  onOpenOfficialRequirements: () =>
                      _navigatorKey.currentState?.pushNamed('/official-requirements'),
                  onOpenWeeklyReports: () =>
                      _navigatorKey.currentState?.pushNamed('/weekly-reports'),
                  onOpenAdditionalRequirements: () =>
                      _navigatorKey.currentState?.pushNamed('/additional-requirements'),
                  onAddNewRequirement: () =>
                      _navigatorKey.currentState?.pushNamed('/add-requirement'),
                );
              }
          }
          return MaterialPageRoute(builder: (_) => page, settings: settings);
        },
      ),
    );
  }
}
