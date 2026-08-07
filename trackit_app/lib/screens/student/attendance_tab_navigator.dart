import 'package:flutter/material.dart';
import '../../models/attendance.dart';
import '../../models/ojt_progress.dart';
import '../../services/attendance_service.dart';
import 'attendance_correction_form_screen.dart';
import 'attendance_history_screen.dart';
import 'student_attendance_view.dart';

/// Mirrors DocumentsTabNavigator/ProfileTabNavigator: owns a nested
/// Navigator so pushing into the Correction Request Form or the full
/// Attendance History screen keeps StudentShell's bottom nav visible.
class AttendanceTabNavigator extends StatefulWidget {
  final AttendanceService service;
  final OjtProgress initialProgress;
  final TodayAttendance initialAttendance;
  final List<AttendanceHistoryEntry> initialHistory;

  const AttendanceTabNavigator({
    super.key,
    required this.service,
    required this.initialProgress,
    required this.initialAttendance,
    this.initialHistory = const [],
  });

  @override
  State<AttendanceTabNavigator> createState() =>
      _AttendanceTabNavigatorState();
}

class _AttendanceTabNavigatorState extends State<AttendanceTabNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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
            case '/correction-request':
              page = AttendanceCorrectionFormScreen(service: widget.service);
              break;
            case '/history':
              page = AttendanceHistoryScreen(service: widget.service);
              break;
            case '/':
            default:
              page = StudentAttendanceView(
                service: widget.service,
                initialProgress: widget.initialProgress,
                initialAttendance: widget.initialAttendance,
                initialHistory: widget.initialHistory,
                onOpenCorrectionRequest: () async {
                  final result = await _navigatorKey.currentState
                      ?.pushNamed<String>('/correction-request');
                  return result;
                },
                onOpenHistory: () =>
                    _navigatorKey.currentState?.pushNamed('/history'),
              );
          }
          // Typed <String> -- '/correction-request' is pushed via
          // pushNamed<String>() above, which requires the produced route
          // to actually be a Route<String> (an untyped MaterialPageRoute
          // infers <dynamic> and fails that check at runtime on web).
          return MaterialPageRoute<String>(builder: (_) => page, settings: settings);
        },
      ),
    );
  }
}
