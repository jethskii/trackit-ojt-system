import 'package:flutter/material.dart';
import '../../models/attendance.dart';
import '../../models/notification.dart';
import '../../models/ojt_progress.dart';
import '../../models/student.dart';
import '../../services/notifications_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_bottom_nav.dart';
import 'documents/documents_tab_navigator.dart';
import 'notifications_screen.dart';
import 'profile/profile_tab_navigator.dart';
import 'student_attendance_view.dart';
import 'student_home_view.dart';

class StudentShell extends StatefulWidget {
  final Student student;
  final OjtProgress progress;
  final List<String> announcements;
  final TodayAttendance todayAttendance;
  final List<AttendanceHistoryEntry> attendanceHistory;

  const StudentShell({
    super.key,
    required this.student,
    required this.progress,
    required this.todayAttendance,
    this.announcements = const [],
    this.attendanceHistory = const [],
  });

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _navIndex = 0;
  final NotificationsService _notificationsService = MockNotificationsService();

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
        progress: widget.progress,
        announcements: widget.announcements,
      ),
      StudentAttendanceView(
        progress: widget.progress,
        initialAttendance: widget.todayAttendance,
        history: widget.attendanceHistory,
      ),
      DocumentsTabNavigator(student: widget.student),
      NotificationsScreen(
        service: _notificationsService,
        onNavigateTo: _goToTab,
      ),
      const ProfileTabNavigator(),
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
