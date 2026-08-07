import 'package:flutter/material.dart';
import '../../models/attendance.dart';
import '../../models/notification.dart';
import '../../models/ojt_progress.dart';
import '../../models/student.dart';
import '../../services/api_client.dart';
import '../../services/attendance_service.dart';
import '../../services/notifications_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_bottom_nav.dart';
import 'attendance_tab_navigator.dart';
import 'documents/documents_tab_navigator.dart';
import 'notifications_screen.dart';
import 'profile/profile_tab_navigator.dart';
import 'student_home_view.dart';

class StudentShell extends StatefulWidget {
  final ApiClient client;
  final Student student;
  final OjtProgress initialProgress;
  final TodayAttendance initialAttendance;
  final List<AttendanceHistoryEntry> initialHistory;
  final VoidCallback onLoggedOut;

  const StudentShell({
    super.key,
    required this.client,
    required this.student,
    required this.initialProgress,
    required this.initialAttendance,
    this.initialHistory = const [],
    required this.onLoggedOut,
  });

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _navIndex = 0;
  late final AttendanceService _attendanceService = HttpAttendanceService(
    widget.client,
  );
  late final NotificationsService _notificationsService =
      HttpNotificationsService(widget.client);

  @override
  void initState() {
    super.initState();
    // Loaded once here (rather than only inside NotificationsScreen) so
    // the Home tab's announcement preview has data even if the student
    // never opens the Notifications tab.
    _notificationsService.load();
  }

  void _goToTab(NotificationTarget target) {
    final index = switch (target) {
      NotificationTarget.home => 0,
      NotificationTarget.attendance => 1,
      NotificationTarget.documents => 2,
      NotificationTarget.profile => 4,
    };
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentHomeView(
        student: widget.student,
        progress: widget.initialProgress,
        notificationsService: _notificationsService,
        onNavigateTo: _goToTab,
        onOpenNotifications: () => setState(() => _navIndex = 3),
      ),
      AttendanceTabNavigator(
        service: _attendanceService,
        initialProgress: widget.initialProgress,
        initialAttendance: widget.initialAttendance,
        initialHistory: widget.initialHistory,
      ),
      DocumentsTabNavigator(student: widget.student, client: widget.client),
      NotificationsScreen(
        service: _notificationsService,
        onNavigateTo: _goToTab,
      ),
      ProfileTabNavigator(
        client: widget.client,
        onLoggedOut: widget.onLoggedOut,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _navIndex, children: pages),
      bottomNavigationBar: ListenableBuilder(
        listenable: _notificationsService,
        builder: (context, _) {
          final navItems = [
            const AppBottomNavItem(icon: Icons.home, label: 'Home'),
            const AppBottomNavItem(
              icon: Icons.event_available,
              label: 'Attendance',
            ),
            const AppBottomNavItem(
              icon: Icons.description,
              label: 'Document',
            ),
            AppBottomNavItem(
              icon: Icons.notifications,
              label: 'Notification',
              badgeCount: _notificationsService.unreadCount,
            ),
            const AppBottomNavItem(icon: Icons.person, label: 'Profile'),
          ];
          return AppBottomNav(
            items: navItems,
            currentIndex: _navIndex,
            onTap: (index) => setState(() => _navIndex = index),
          );
        },
      ),
    );
  }
}
